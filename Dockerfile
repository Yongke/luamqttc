FROM ubuntu:14.04

RUN mkdir /app
WORKDIR /app
Add . /app

RUN apt-get update && \
    apt-get install -y git openssh-server wget build-essential && \
    apt-get clean

#install lua
RUN apt-get install -y libncurses5-dev libreadline-dev && \
    cd /tmp && wget https://www.lua.org/ftp/lua-5.1.4.tar.gz  && \
    tar zxf lua-5.1.4.tar.gz && cd lua-5.1.4 && \
    make linux && make install

#install luarocks
RUN apt-get install -y unzip && \
    cd /tmp && wget http://luarocks.org/releases/luarocks-2.4.0.tar.gz  && \
    tar zxpf luarocks-2.4.0.tar.gz && \
    cd luarocks-2.4.0 && ./configure && make bootstrap

RUN apt-get -y install libssl-dev
