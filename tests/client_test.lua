local require = require
local assert, print = assert, print
local mqttclient = require("luamqttc/client")

local host = "localhost"
local port = 1883
local timeout = 1 -- 1 seconds

local topics = { "TopicA", "TopicA/B", "Topic/C", "TopicA/C", "/TopicA" }
local wildtopics = { "TopicA/+", "+/C", "#", "/#", "/+", "+/+", "TopicA/#" }
local nosubscribe_topics = { "nosubscribe" }

local callback = function()

end

local basic = function()
    print("Basic testing")
    local aclient = mqttclient:new("myclientid")

    assert(mqttclient:connect(host, port, timeout))
    aclient:disconnect()

    assert(mqttclient:connect(host, port, timeout))
    assert(aclient:subscribe(topics[1], 2, callback))
    assert(aclient:publish(topics[1], "qos 0"))
    assert(aclient:publish(topics[1], "qos 1", {qos=1}))
    assert(aclient:publish(topics[1], "qos 2", {qos=2}))
end

basic()
