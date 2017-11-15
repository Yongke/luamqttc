local socket = require "socket"
local ssl = require "ssl"
local mqttpacket = require "mqttpacket"
local timer = require "luamqttc/timer"

local string, math = string, math
local type = type
local table = table
local table_insert = table.insert
local pairs = pairs
local MAX_PACKET_ID = 65535
local gassert = assert
local setmetatable = setmetatable

------------------------------------
-- Utility functions below
------------------------------------
local assert = function(x, err)
    return gassert(x, string.format("error message: %s", err or "unknown"))
end

local split = function(str, delimiter)
    if str == nil or str == '' or delimiter == nil then
        return nil
    end
    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table_insert(result, match)
    end
    return result
end

------------------------------------
-- API functions below
------------------------------------

local _M = {
    CONNECT = 1,
    CONNACK = 2,
    PUBLISH = 3,
    PUBACK = 4,
    PUBREC = 5,
    PUBREL = 6,
    PUBCOMP = 7,
    SUBSCRIBE = 8,
    SUBACK = 9,
    UNSUBSCRIBE = 10,
    UNSUBACK = 11,
    PINGREQ = 12,
    PINGRESP = 13,
    DISCONNECT = 14
}

-- Options table:
--  username: string or nil,
--  password: string or nil
--  keep_alive: integer
--  clean_session: true or false
--  will_flag: true or false
--  will_options: table
--   topic_name: string
--   message: string
--   ratained: true or false
--   qos: 0, 1, 2

_M.new = function(client_id, opts)
    assert(client_id and type(client_id) == "string")
    local m = {}
    m.opts = opts or {}
    m.opts.client_id = client_id
    m.packet_id = 0
    -- subscribe handlers
    m.subscribe_callbacks = {}
    return setmetatable(m, { __index = _M })
end

_M.connect = function(self, host, port, connopts)
    local connopts = connopts or {}
    local sock = assert(socket.connect(host, port))

    if connopts.usessl then
        local params = { mode = "client", protocol = "tlsv1_2", verify = "none" }

        if connopts.protocol then
            params.protocol = connopts.protocol
        end

        if connopts.verify then
            params.verify = connopts.verify
        end

        if connopts.cafile then
            params.cafile = connopts.cafile
        end

        if connopts.certificate then
            params.certificate = connopts.certificate
        end

        if connopts.key then
            params.key = connopts.key
        end

        sock = assert(ssl.wrap(sock, params))
        assert(sock:dohandshake())
        if params.verify == "peer" then
            assert(sock:getpeerverification())
        end
    end

    self.transport = sock
    self:settimeout(connopts.timeout)
    self:setkatimeout()

    local req = mqttpacket.serialize_connect(self.opts)
    local ok, err = self:send(req)
    assert(ok, err)

    local type, data = self:wait_packet(self.CONNACK)
    assert(type, data)
    local success, code = mqttpacket.deserialize_connack(data)
    assert(type, code)

    return true
end

-- Options table:
--  qos: 0, 1 or 2 (0 by default)
--  retained: true or false
--  dup: true or false
_M.publish = function(self, topic, message, opts, timeout)
    local opts = opts or {}
    self:settimeout(timeout)

    local qos = opts.qos or 0
    if qos >= 1 then
        opts.packet_id = self:next_packet_id()
    end
    local req = mqttpacket.serialize_publish(topic, message, opts)
    local ok, err = self:send(req)
    assert(ok, err)

    if qos == 1 then
        self:wait_ack(self.PUBACK)
    elseif qos == 2 then
        self:wait_ack(self.PUBCOMP)
    end

    return true
end

_M.subscribe = function(self, topic, qos, callback, timeout)
    self:settimeout(timeout)

    local req = mqttpacket.serialize_subscribe(topic, qos or 0, self:next_packet_id())
    local ok, err = self:send(req)
    assert(ok, err)
    self.subscribe_callbacks[topic] = callback

    local type, data = self:wait_packet(self.SUBACK)
    assert(type, data)
    local ok, granted_qos = mqttpacket.deserialize_suback(data)
    assert(ok, granted_qos)

    return true
end

_M.message_loop = function(self, timeout)
    if timeout then
        self:settimeout(timeout)
        repeat
            local type, data = self:cycle_packet()
        until self.timer:remain() < 0 or (type == nil and data ~= "timeout")
    else
        repeat
            self:settimeout()
            local type, data = self:cycle_packet()
        until type == nil and data ~= "timeout"
    end
end

_M.unsubscribe = function(self, topic, timeout)
    self:settimeout(timeout)

    local req = mqttpacket.serialize_unsubscribe(topic, self:next_packet_id())
    local ok, err = self:send(req)
    assert(ok, err)
    self:wait_ack(self.UNSUBACK)
    return true
end

_M.disconnect = function(self, timeout)
    self:settimeout(timeout)

    local req = mqttpacket.serialize_disconnect()
    local ok, err = self:send(req)
    assert(ok, err)

    self.transport:close()
    return true
end

------------------------------------
-- Supporting functions below
------------------------------------
_M.setkatimeout = function(self)
    self.keepalive_timer = timer.new(self.opts.keep_alive or 60)
end

_M.settimeout = function(self, timeout)
    assert(self.transport)
    self.timer = timer.new(timeout or 5)
    self.transport:settimeout(timeout)
end

_M.send = function(self, data)
    local remain = self.timer:remain()
    if remain < 0 then
        return nil, "timeout"
    end
    self.transport:settimeout(remain)

    -- reset the keepalive timeout
    self:setkatimeout()

    return self.transport:send(data)
end

_M.receive = function(self, pattern)
    local data, err = self.transport:receive(pattern)
    if err == "wantread" or err == "wantwrite" then
        err = "timeout"
    end
    return data, err
end

local readtimeout = 0.1

_M.read_packet = function(self)
    local buff = {}

    -- reset the tansport timeout to a small one,
    -- logic here is getting the whole packet or return immediately
    self.transport:settimeout(readtimeout)
    local data, err = self:receive(1)
    if not data then
        return nil, err
    end
    table_insert(buff, data)

    -- make sure following data in save packet are received in one packet
    self.transport:settimeout(-1)

    -- byte >> 4, workaround
    local type = math.floor(string.byte(data, 1) / 2 ^ 4)

    local multiplier = 1
    local len = 0
    repeat
        local data, err = self:receive(1)
        if not data then
            return nil, err
        end
        table_insert(buff, data)
        local c = string.byte(data, 1)
        len = len + multiplier * (c >= 128 and (c - 128) or c)
        multiplier = multiplier * 128
    until c < 128

    if len > 0 then
        local data, err = self:receive(len)
        if not data then
            return nil, err
        end
        table_insert(buff, data)
    end

    return type, table.concat(buff)
end

_M.cycle_packet = function(self)
    local type, data = self:read_packet()
    if type == self.PUBLISH then
        local ok, topic, message, packet_id, dup, qos, retained = mqttpacket.deserialize_publish(data)
        assert(ok)
        if qos > 0 then
            local ackdata = mqttpacket.serialize_ack(self.PUBACK, false, packet_id)
            local ok, err = self:send(ackdata)
            assert(ok, err)
        end
        self:handle_callbacks(topic, message, packet_id, dup, qos, retained)
    elseif type == self.PUBREC then
        local ok, dup, packet_id = mqttpacket.deserialize_ack(data)
        assert(ok)
        local ackdata = mqttpacket.serialize_ack(self.PUBREL, false, packet_id)
        local ok, err = self:send(ackdata)
        assert(ok, err)
    elseif type == self.PINGRESP then
        self.pingresp_timer = nil
    end

    if self.pingresp_timer then
        assert(self.pingresp_timer:remain() > 0, "can not receive ping response")
    end
    self:keepalive()

    return type, data
end

_M.keepalive = function(self)
    if self.keepalive_timer:remain() < 0 then
        local data = mqttpacket.serialize_pingreq()
        local ok, err = self:send(data)
        assert(ok, err)
        self.pingresp_timer = timer.new(5)
    end
end

_M.wait_packet = function(self, type)
    local exptype, data
    repeat
        exptype, data = self:cycle_packet()
    until self.timer:remain() < 0 or type == exptype
            or (exptype == nil and data ~= "timeout")
    return exptype, data
end

_M.next_packet_id = function(self)
    if self.packet_id == MAX_PACKET_ID then
        self.packet_id = 1
    else
        self.packet_id = self.packet_id + 1
    end
    return self.packet_id
end

_M.wait_ack = function(self, type)
    local type, data = self:wait_packet(type)
    assert(type, data)
    local ok, dup, packet_id = mqttpacket.deserialize_ack(data)
    assert(ok, packet_id)
    return dup, packet_id
end

_M.handle_callbacks = function(self, topic, data, ...)
    for filter, cb in pairs(self.subscribe_callbacks) do
        if self:topic_match(filter, topic) then
            cb(topic, data, ...)
            return
        end
    end
end

_M.topic_match = function(self, filter, name)
    if filter == name then
        return true
    end

    local t1 = split(filter, "/")
    local t2 = split(name, "/")
    local len1, len2 = #t1, #t2

    local i = 1
    repeat
        local item_match = (t1[i] == t2[i])
                or (t1[i] == "+" and t2[i] ~= nil and len1 == len2)
                or (t1[i] == "#" and (t2[i] ~= nil or (t2[i] == nil and t2[i - 1] ~= nil)))
        if not item_match then
            return false
        end
        i = i + 1
    until (i > len1)
    return true
end

return _M
