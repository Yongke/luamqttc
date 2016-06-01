package.cpath = package.cpath .. ';/Users/yongke/IdeaProjects/luamqttc/build/?.dylib'
local assert = assert
local mqttclient = require("mqttclient")

local opts = {
    client_id = "lua001",
    username = "mangoiot/lua001",
    password = "GmpzzdL3tqBHnBo7KYnuCByab8Of05LNw1zdA9/EYxM="
}

local conn = assert(mqttclient:connect(opts))
conn:publish("lua2ws", "xxxx from lua client")
conn:subscribe("ws2lua", 0, nil, 10)
