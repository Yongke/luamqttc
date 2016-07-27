package = "luamqttc"
version = "1.0-2"

source = {
    url = "https://github.com/Yongke/luamqttc"
}

description = {
    summary = "A lua mqtt client",
    detailed = [[
        A lua mqtt client which is based on the paho Embedded MQTT C Client Libraries.
    ]],
    homepage = "https://github.com/Yongke/luamqttc",
    license = "EPL/EDL"
}

dependencies = {
    "lua >= 5.1", "luasocket", "luasec"
}

build = {
    type = "builtin",
    modules = {
        mqttpacket = {
            sources = {
                "deps/lua-compat-5.2/compat-5.2.c",
                "deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTConnectClient.c",
                "deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTConnectServer.c",
                "deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTDeserializePublish.c",
                "deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTFormat.c",
                "deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTPacket.c",
                "deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTSerializePublish.c",
                "deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTSubscribeClient.c",
                "deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTSubscribeServer.c",
                "deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTUnsubscribeClient.c",
                "deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTUnsubscribeServer.c",
                "src/luamqttpacket.c"
            },
            incdirs = { "deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src", "deps/lua-compat-5.2" }
        }
    },
    install = {
        lua = {
            ["luamqttc.client"] = "src/client.lua",
            ["luamqttc.timer"] = "src/timer.lua"
        }
    }
}