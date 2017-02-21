luarocks make

git clone https://github.com/eclipse/paho.mqtt.testing.git
oldpwd=`pwd`
cd paho.mqtt.testing/interoperability && python3 startbroker.py &
sleep 3
cd $oldpwd && lua tests/client_test.lua
