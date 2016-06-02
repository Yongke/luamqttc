local require = require
local assert, print = assert, print
local table = table
local ipairs = ipairs
local mqttclient = require("luamqttc/client")

local host = "localhost"
local port = 1883
local timeout = 1 -- 1 seconds

local topics = { "TopicA", "TopicA/B", "Topic/C", "TopicA/C", "/TopicA" }
local wildtopics = { "TopicA/+", "+/C", "#", "/#", "/+", "+/+", "TopicA/#" }
local nosubscribe_topics = { "nosubscribe" }

local cb_buf = {}

local callback = function(topic, data)
    print("cb: ", topic)
    table.insert(cb_buf, { topic, data })
end

local unittest = function()
    print("Unit testing")
    local t = {
        { "+/+", "a/b", true },
        { "+/+", "a/b/c", false },
        { "+/+", "a", false },
        { "a/b/+/c", "a/b/1/c", true },
        { "abc", "abc", true },
        { "abc", "abcd", false },
        { "a/#", "a/b", true },
        { "a/#", "a/b/c", true },
        { "a/#", "a", true },
        { "a/#", "b", false },
    }

    for _, v in ipairs(t) do
        assert(v[3] == mqttclient:topic_match(v[1], v[2]))
    end
end

local basic = function()
    print("Basic testing")
    cb_buf = {}
    local aclient = mqttclient.new("myclientid")

    assert(aclient:connect(host, port, timeout))
    aclient:disconnect()

    assert(aclient:connect(host, port, timeout))
    assert(aclient:subscribe(topics[1], 2, callback))
    assert(aclient:publish(topics[1], "qos 0"))
    assert(aclient:publish(topics[1], "qos 1", { qos = 1 }))
    assert(aclient:publish(topics[1], "qos 2", { qos = 2 }))
    aclient:message_loop(timeout)
    aclient:disconnect()
    assert(#cb_buf == 3)

    assert(aclient:connect(host, port, timeout))
    local _, local_port = aclient.transport:getsockname()
    aclient:connect(host, port, timeout)
    local _, local_port1 = aclient.transport:getsockname()
    -- previous transport connection(tcp) was closed by server & start new
    assert(local_port ~= local_port1)
    aclient:disconnect()
    print("Basic testing finished")
end

local retained_message = function()
    print("Retained message testing")
    cb_buf = {}

    local aclient = mqttclient.new("myclientid", { clean_session = true })
    assert(aclient:connect(host, port, timeout))
    assert(aclient:publish(topics[2], "qos 0", { qos = 0, retained = true }))
    assert(aclient:publish(topics[3], "qos 1", { qos = 1, retained = true }))
    assert(aclient:publish(topics[4], "qos 2", { qos = 2, retained = true }))

    assert(aclient:subscribe(wildtopics[6], 2, callback))
    aclient:message_loop(timeout)
    aclient:disconnect()
    assert(#cb_buf == 3)

    cb_buf = {}
    assert(aclient:connect(host, port, timeout))
    assert(aclient:publish(topics[2], "", { qos = 0, retained = true }))
    assert(aclient:publish(topics[3], "", { qos = 1, retained = true }))
    assert(aclient:publish(topics[4], "", { qos = 2, retained = true }))

    assert(aclient:subscribe(wildtopics[6], 2, callback))
    aclient:message_loop(timeout)
    aclient:disconnect()
    assert(#cb_buf == 0)

    print("Retained message testing finished")
end

local offline_message_queueing = function()
    print("Offline message queueing test")

    cb_buf = {}
    local aclient = mqttclient.new("myclientid", { clean_session = false })
    assert(aclient:connect(host, port, timeout))
    assert(aclient:subscribe(wildtopics[6], 2, callback))
    aclient:disconnect()

    local bclient = mqttclient.new("myclientid2") -- clean session by default
    assert(bclient:connect(host, port, timeout))
    assert(bclient:publish(topics[2], "qos 0"))
    assert(bclient:publish(topics[3], "qos 1", { qos = 1 }))
    assert(bclient:publish(topics[4], "qos 2", { qos = 2 }))
    bclient:message_loop(timeout)
    bclient:disconnect()

    assert(aclient:connect(host, port, timeout))
    aclient:message_loop(timeout)
    aclient:disconnect()

    if #cb_buf == 2 then
        print("This server is not queueing QoS 0 messages for offline clients")
    elseif #cb_buf == 3 then
        print("This server is queueing QoS 0 messages for offline clients")
    else
        assert(false)
    end
    print("Offline message queueing test finished")
end

local will_message = function()
    print("Will message test")
    cb_buf = {}
    local aclient = mqttclient.new("myclientid", {
        clean_session = true,
        will_flag = true,
        will_options =
        { topic_name = topics[3], message = "client not disconnected" }
    })
    assert(aclient:connect(host, port, timeout))

    local bclient = mqttclient.new("myclientid2", { clean_session = false })
    assert(bclient:connect(host, port, timeout))
    assert(bclient:subscribe(topics[3], 2, callback))

    -- terminate the connection
    aclient.transport:close()

    bclient:message_loop(timeout)
    bclient:disconnect()

    assert(#cb_buf == 1)
    print("Will message test finished")
end

unittest()
basic()
retained_message()
offline_message_queueing()
will_message()