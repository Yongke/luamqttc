local socket = require("socket")
local os, setmetatable= os, setmetatable

local difftime = function (t1, t2)
    return t1 - t2
end

local _M = {}

_M.new = function(timeout)
    local m = {}
    m.start = socket.gettime()
    m.timeout = timeout
    return setmetatable(m, { __index = _M })
end

_M.escaped = function(self)
    return difftime(socket.gettime(), self.start)
end

_M.remain = function(self)
    return self.timeout - self:escaped()
end

return _M
