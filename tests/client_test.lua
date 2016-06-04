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
local callback = function(topic, data, packet_id, dup, qos, retained)
    print("cb 1: ", topic)
    table.insert(cb_buf, { topic, data, qos })
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
    print("Basic test")
    cb_buf = {}
    local aclient = mqttclient.new("myclientid")

    assert(aclient:connect(host, port, {timeout = timeout}))
    aclient:disconnect()

    assert(aclient:connect(host, port, {timeout = timeout}))
    assert(aclient:subscribe(topics[1], 2, callback))
    assert(aclient:publish(topics[1], "qos 0"))
    assert(aclient:publish(topics[1], "qos 1", { qos = 1 }))
    assert(aclient:publish(topics[1], "qos 2", { qos = 2 }))
    aclient:message_loop(timeout)
    aclient:disconnect()
    assert(#cb_buf == 3)

    assert(aclient:connect(host, port, {timeout = timeout}))
    local _, local_port = aclient.transport:getsockname()
    aclient:connect(host, port, {timeout = timeout})
    local _, local_port1 = aclient.transport:getsockname()
    -- previous transport connection(tcp) was closed by server & start new
    assert(local_port ~= local_port1)

    assert(aclient:unsubscribe(topics[1]))

    aclient:disconnect()
    print("Basic test finished")
end

local retained_message = function()
    print("Retained message test")
    cb_buf = {}

    local aclient = mqttclient.new("myclientid", { clean_session = true })
    assert(aclient:connect(host, port, {timeout = timeout}))
    assert(aclient:publish(topics[2], "qos 0", { qos = 0, retained = true }))
    assert(aclient:publish(topics[3], "qos 1", { qos = 1, retained = true }))
    assert(aclient:publish(topics[4], "qos 2", { qos = 2, retained = true }))

    assert(aclient:subscribe(wildtopics[6], 2, callback))
    aclient:message_loop(timeout)
    aclient:disconnect()
    assert(#cb_buf == 3)

    cb_buf = {}
    assert(aclient:connect(host, port, {timeout = timeout}))
    assert(aclient:publish(topics[2], "", { qos = 0, retained = true }))
    assert(aclient:publish(topics[3], "", { qos = 1, retained = true }))
    assert(aclient:publish(topics[4], "", { qos = 2, retained = true }))

    assert(aclient:subscribe(wildtopics[6], 2, callback))
    aclient:message_loop(timeout)
    aclient:disconnect()
    assert(#cb_buf == 0)

    print("Retained message test finished")
end

local offline_message_queueing = function()
    print("Offline message queueing test")

    cb_buf = {}
    local aclient = mqttclient.new("myclientid", { clean_session = false })
    assert(aclient:connect(host, port, {timeout = timeout}))
    assert(aclient:subscribe(wildtopics[6], 2, callback))
    aclient:disconnect()

    local bclient = mqttclient.new("myclientid2") -- clean session by default
    assert(bclient:connect(host, port, {timeout = timeout}))
    assert(bclient:publish(topics[2], "qos 0"))
    assert(bclient:publish(topics[3], "qos 1", { qos = 1 }))
    assert(bclient:publish(topics[4], "qos 2", { qos = 2 }))
    bclient:message_loop(timeout)
    bclient:disconnect()

    assert(aclient:connect(host, port, {timeout = timeout}))
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
        {
            topic_name = topics[3],
            message = "client not disconnected",
            retained = true
        }
    })
    assert(aclient:connect(host, port, {timeout = timeout}))

    local bclient = mqttclient.new("myclientid2", { clean_session = false })
    assert(bclient:connect(host, port, {timeout = timeout}))
    assert(bclient:subscribe(topics[3], 2, callback))

    -- terminate the connection
    aclient.transport:close()

    bclient:message_loop(timeout)
    bclient:disconnect()

    assert(#cb_buf == 1)
    print("Will message test finished")
end

local overlapping_subscriptions = function()
    print("Overlapping subscriptions test")
    cb_buf = {}

    local aclient = mqttclient.new("myclientid")
    assert(aclient:connect(host, port, {timeout = timeout}))
    assert(aclient:subscribe(wildtopics[7], 2, callback))
    assert(aclient:subscribe(wildtopics[1], 1, callback))

    assert(aclient:publish(topics[4], "overlapping topic filters", { qos = 2 }))
    aclient:message_loop(timeout)
    aclient:disconnect()

    assert((#cb_buf == 1 and cb_buf[1][3] == 2) or #cb_buf == 2)
    print("Overlapping subscriptions test finished")
end

local keepalive_test = function()
    print("Keepalive test")

    cb_buf = {}
    local aclient = mqttclient.new("myclientid", {
        clean_session = true,
        keep_alive = 5, -- 5 seconds
        will_flag = true,
        will_options =
        { topic_name = topics[5], message = "keepalive expiry" }
    })
    assert(aclient:connect(host, port, {timeout = timeout}))

    local bclient = mqttclient.new("myclientid2", {
        clean_session = false,
        keep_alive = 3
    })
    assert(bclient:connect(host, port, {timeout = timeout}))
    assert(bclient:subscribe(topics[5], 2, callback))

    bclient:message_loop(15)
    bclient:disconnect()

    assert(#cb_buf == 1)
    print("Keepalive test finished")
end

local redelivery_on_reconnect = function()
    cb_buf = {}

    local aclient = mqttclient.new("myclientid", { clean_session = false })
    assert(aclient:connect(host, port, {timeout = timeout}))
    assert(aclient:subscribe(wildtopics[7], 2, callback))
    aclient.transport:close()

    local bclient = mqttclient.new("myclientid2")
    assert(bclient:connect(host, port, {timeout = timeout}))

    assert(bclient:publish(topics[2], "qos 1", { qos = 1 }))
    assert(bclient:publish(topics[4], "qos 2", { qos = 2 }))
    bclient:disconnect()

    assert(#cb_buf == 0)
    -- reconnect
    assert(aclient:connect(host, port, {timeout = timeout}))
    aclient:message_loop(timeout)
    aclient:disconnect()
    assert(#cb_buf == 2)
end

local connect_ssl = function()
    cb_buf = {}
    print("SSL test")

    local host = "iot.eclipse.org"
    local port = 8883
    local aclient = mqttclient.new("myclientid")

    assert(aclient:connect(host, port, {timeout = timeout, usessl = true}))
    assert(aclient:subscribe(topics[1], 2, callback))

    assert(aclient:publish(topics[1], "qos 0"))
    assert(aclient:publish(topics[1], "qos 1", { qos = 1 }))
    assert(aclient:publish(topics[1], "qos 2", { qos = 2 }))

    aclient:message_loop(timeout)
    aclient:disconnect()
    assert(#cb_buf == 3) -- may fail, this is a public server ;-)

    print("SSL test finished")
end

unittest()
basic()
retained_message()
offline_message_queueing()
will_message()
overlapping_subscriptions()
keepalive_test()
redelivery_on_reconnect()
connect_ssl()