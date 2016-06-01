local socket = require "socket"
local mqttpacket = require "mqttpacket"
local timer = require "luamqttc/timer"

local string, math = string, math
local assert, type = assert, type
local print = print
local table = table
local table_insert = table.insert
local MAX_PACKET_ID = 65535

local assert = function(x, err)
    return assert(x, string.format("error message: %s", err or "unknown"))
end

local function range(a, b, step)
    if not b then
        b = a
        a = 1
    end
    step = step or 1
    local f =
    step > 0 and
            function(_, lastvalue)
                local nextvalue = lastvalue + step
                if nextvalue <= b then return nextvalue end
            end or
            step < 0 and
            function(_, lastvalue)
                local nextvalue = lastvalue + step
                if nextvalue >= b then return nextvalue end
            end or
            function(_, lastvalue) return lastvalue end
    return f, nil, a - step
end

local function print_bytes(data)
    for i in range(1, #data) do
        print(string.byte(data, i))
    end
end

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
    DISCONNECT = 14,

    -- subscribe handlers
    subscribe_callbacks = {}
}


------------------------------------
-- API functions below
------------------------------------

-- Options table:
--  username: string or nil,
--  password: string or nil
--  keep_alive: integer
--  clean_session: true or false
--  will_flag: true or false
--  will_options: table
_M.new = function(self, client_id, opts)
    assert(client_id and type(client_id) == "string")
    self.opts = opts or {}
    self.opts.client_id = client_id
    self.packet_id = 0
    return self
end

_M.connect = function(self, host, port, timeout)
    local sock = assert(socket.connect(host, port))
    self.transport = sock
    self:settimeout(timeout)

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
-- qos: 0, 1 or 2 (0 by default)
-- retained: true or false
-- dup: true or false
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

    local type, data = self:wait_packet(self.SUBACK)
    assert(type, data)
    local ok, granted_qos = mqttpacket.deserialize_suback(data)
    assert(ok, granted_qos)

    self.subscribe_callbacks[topic] = callback
    return true
end

_M.unsubscribe = function(self, timeout)
    self:settimeout(timeout)
end

_M.disconnect = function(self, timeout)
    self:settimeout(timeout)

    local req = mqttpacket.serialize_disconnect()
    local ok, err = self:send(req)
    assert(ok, err)

    return true
end

------------------------------------
-- Supporting functions below
------------------------------------

_M.settimeout = function(self, timeout)
    assert(self.transport)
    self.timer = timer:new(timeout or 5)
    self.transport:settimeout(timeout)
end

_M.send = function(self, data)
    self.transport:settimeout(self.timer:remain())
    return self.transport:send(data)
end

_M.receive = function(self, pattern)
    self.transport:settimeout(self.timer:remain())
    return self.transport:receive(pattern)
end

_M.read_packet = function(self)
    local buff = {}

    local data, err = self:receive(1)
    if not data then
        return nil, err
    end
    table_insert(buff, data)

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

    local data, err = self:receive(len)
    if not data then
        return nil, err
    end
    table_insert(buff, data)

    return type, table.concat(buff)
end

_M.cycle_packet = function(self)
    local type, data = self:read_packet()
    if type == self.PUBLISH then

    elseif type == self.PUBREC then
        local ok, dup, packet_id = mqttpacket.deserialize_ack(data)
        assert(ok, packet_id)
        local data1 = mqttpacket.serialize_ack(self.PUBREL, false, packet_id)
        self:send(data1)
    end
    return type, data
end

_M.wait_packet = function(self, type)
    local exptype, data
    repeat
        exptype, data = self:cycle_packet()
    until (type == exptype or exptype == nil)

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

return _M