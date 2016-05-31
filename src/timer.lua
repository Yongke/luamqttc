local socket = require("socket")
local os = os
local difftime = os.difftime

local _M = {}

_M.new = function(self, timeout)
    self.start = socket.gettime()
    self.timeout = timeout
    return self
end

_M.escaped = function(self)
    return difftime(socket.gettime(), self.start)
end

_M.remain = function(self)
    return self.timeout - self:escaped()
end

return _M


