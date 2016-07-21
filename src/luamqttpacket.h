#ifndef PROJECT_MQTTCLIENT_H
#define PROJECT_MQTTCLIENT_H

#include <memory.h>
#include "compat-5.2.h"

#include "MQTTPacket.h"
#include "MQTTConnect.h"

typedef struct PublishOptions PublishOptions;

struct PublishOptions {
    int qos;
    unsigned char retained;
    unsigned char dup;
    unsigned short packet_id;
};

#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM == 501
#define luabuffptr(buf) (buf.ptr)
#else
#define luabuffptr(buf) (buf.b)
#endif

#endif
