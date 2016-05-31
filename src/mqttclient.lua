local socket = require "socket"
local mqttpacket = require "mqttpacket"
local timer = require "timer"

local string, math = string, math
local assert = assert
local print = print
local table = table
local table_insert = table.insert


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

local _M = {}

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
        print(err)
        return nil, nil
    end
    table_insert(buff, data)

    -- byte >> 4, workaround
    local type = math.floor(string.byte(data, 1) / 2 ^ 4)

    local multiplier = 1
    local len = 0
    repeat
        local data, err = self:receive(1)
        if not data then
            print(err)
            return nil, nil
        end
        table_insert(buff, data)
        local c = string.byte(data, 1)
        len = len + multiplier * (c >= 128 and (c - 128) or c)
        multiplier = multiplier * 128
    until c < 128

    local data, err = self:receive(len)
    if not data then
        print(err)
        return nil, nil
    end
    table_insert(buff, data)

    return type, table.concat(buff)
end

_M.settimeout = function(self, timeout)
    self.timer = timer:new(timeout or 5)
    self.transport:settimeout(timeout)
end

_M.connect = function(self, opts, timeout)
    local sock = assert(socket.connect("mangoiot.mqtt.iot.gz.baidubce.com", 1883))
    self.transport = sock
    self:settimeout(timeout)

    local req = mqttpacket.serialize_connect(opts)
    local ok, err = self:send(req)
    if not ok then
        print(err)
        return nil, err
    end

    local type, data = self:read_packet()

    local success, code = mqttpacket.deserialize_connack(data)
    if not success then
        print(code)
        return nil, err
    end

    return self
end

_M.publish = function(self, topic, message, timeout)
    assert(self.transport)
    self:settimeout(timeout)

    local req = mqttpacket.serialize_publish(topic, message)
    local ok, err = self:send(req)
    if not ok then
        print(err)
        return nil, err
    end

    return true
end

_M.subscribe = function(self, topic, qos, callback, timeout)
    assert(self.transport)
    self:settimeout(timeout)

    local req = mqttpacket.serialize_subscribe(topic, qos or 0)
    local ok, err = self:send(req)
    if not ok then
        print(err)
        return nil, err
    end

    local type, data = self:read_packet()
    if type == 9 then
        local ok, granted_qos = mqttpacket.deserialize_suback(data)
        print(ok, granted_qos)
        -- return true

        while true do
            local type, data = self:read_packet()
            assert(type)

            print(type, data)
        end
    end


    return nil, "suback is wrong"
end

_M.unsubscribe = function(self, timeout)
    assert(self.transport)
    self:settimeout(timeout)
end

_M.disconnect = function(self, timeout)
    assert(self.transport)
    self:settimeout(timeout)
end

return _M