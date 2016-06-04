# luamqttc - An lua mqtt client

luamqttc is base on the paho Embedded MQTT C Client Library - MQTTPacket.

Supported features:
* MQTT version v3.1.1
* Authentication
* QOS of 0, 1, 2
* Last will topic
* SSL


## How to build

```
git clone https://github.com/Yongke/luamqttc.git
luarocks make
```

## How to run tests

Run pato mqtt testing fake broker first
```
git clone https://github.com/eclipse/paho.mqtt.testing.git
cd paho.mqtt.testing/interoperability && python3 startbroker.py
```
and then run
```
lua tests/client_test.lua
```

After the tests, quit the fake broker(CTRL + C) and you will see the coverage report.

## How to use
Check samples in tests/client_test.lua

## License
It is dual licensed under the EPL and EDL (see about.html and notice.html for more details).  You can choose which of these licenses you want to use the code under.

