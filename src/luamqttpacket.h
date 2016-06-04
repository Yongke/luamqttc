#ifndef PROJECT_MQTTCLIENT_H
#define PROJECT_MQTTCLIENT_H

#include <memory.h>

#include "lua.h"
#include "lauxlib.h"

#include "MQTTPacket.h"
#include "MQTTConnect.h"

typedef struct PublishOptions PublishOptions;

struct PublishOptions {
    int qos;
    unsigned char retained;
    unsigned char dup;
    unsigned short packet_id;
};

#endif
