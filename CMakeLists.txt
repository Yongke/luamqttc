CMAKE_MINIMUM_REQUIRED(VERSION 3.0.2)

## library paho-embed-mqtt3p
SET(SOURCES_MQTTPactet
        org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTConnect.h
        org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTConnectClient.c
        org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTConnectServer.c
        org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTDeserializePublish.c
        org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTFormat.c
        org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTFormat.h
        org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTPacket.c
        org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTPacket.h
        org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTPublish.h
        org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTSerializePublish.c
        org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTSubscribe.h
        org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTSubscribeClient.c
        org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTSubscribeServer.c
        org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTUnsubscribe.h
        org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTUnsubscribeClient.c
        org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/MQTTUnsubscribeServer.c
        org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/StackTrace.h)
ADD_LIBRARY(paho-embed-mqtt3c SHARED ${SOURCES_MQTTPactet})

SET(SOURCES_luamqttpacket
        src/luamqttpacket.c
        src/luamqttpacket.h)
ADD_LIBRARY(mqttpacket SHARED ${SOURCES_luamqttpacket})
INCLUDE_DIRECTORIES(org.eclipse.paho.mqtt.embedded-c/MQTTPacket/src/)
TARGET_LINK_LIBRARIES(mqttpacket paho-embed-mqtt3c lua)

