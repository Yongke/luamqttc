CMAKE_MINIMUM_REQUIRED(VERSION 3.0.2)

SET(SOURCES_lua-compat-5.2
        deps/lua-compat-5.2/compat-5.2.h
        deps/lua-compat-5.2/compat-5.2.c)
SET(SOURCES_luamqttpacket
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTConnect.h
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTConnectClient.c
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTConnectServer.c
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTDeserializePublish.c
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTFormat.c
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTFormat.h
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTPacket.c
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTPacket.h
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTPublish.h
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTSerializePublish.c
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTSubscribe.h
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTSubscribeClient.c
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTSubscribeServer.c
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTUnsubscribe.h
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTUnsubscribeClient.c
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTUnsubscribeServer.c
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/StackTrace.h
        src/luamqttpacket.c
        src/luamqttpacket.h)

INCLUDE_DIRECTORIES(deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/)
INCLUDE_DIRECTORIES(deps/lua-compat-5.2)
ADD_LIBRARY(luamqttpacket SHARED ${SOURCES_luamqttpacket} ${SOURCES_lua-compat-5.2})

INCLUDE_DIRECTORIES(/usr/local/include/lua5.1/)
TARGET_LINK_LIBRARIES(luamqttpacket lua.5.1)

#INCLUDE_DIRECTORIES(/usr/local/include/lua5.2/)
#TARGET_LINK_LIBRARIES(luamqttpacket lua.5.2)

#INCLUDE_DIRECTORIES(/usr/local/include/lua5.3/)
#TARGET_LINK_LIBRARIES(luamqttpacket lua.5.3)
