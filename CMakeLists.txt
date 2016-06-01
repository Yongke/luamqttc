CMAKE_MINIMUM_REQUIRED(VERSION 3.0.2)

## library paho-embed-mqtt3p
SET(SOURCES_MQTTPactet
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
        deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/StackTrace.h)
ADD_LIBRARY(paho-embed-mqtt3c SHARED ${SOURCES_MQTTPactet})

SET(SOURCES_luamqttpacket
        src/luamqttpacket.c
        src/luamqttpacket.h)
ADD_LIBRARY(luamqttpacket SHARED ${SOURCES_luamqttpacket})
INCLUDE_DIRECTORIES(deps/org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/)
TARGET_LINK_LIBRARIES(luamqttpacket paho-embed-mqtt3c lua)

INSTALL(TARGETS luamqttpacket
        LIBRARY DESTINATION lib/lua/5.2/
        RENAME mqttpacket)
