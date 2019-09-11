FROM ubuntu:18.04

LABEL maintainer="Tangram Flex"

# This is for ZMQ Proxy
RUN apt-get update

# zeromq build dependencies - http://zeromq.org/area:faq
RUN apt-get install -y --no-install-recommends \
    ca-certificates \
	autoconf \
	automake \
	build-essential \
	cmake \
	git \
	libtool \
	pkg-config

# libzmq - 0mq library
RUN git clone -b 'v4.3.0' --single-branch --depth 1 https://github.com/zeromq/libzmq.git && \
	cd libzmq && \
	./autogen.sh && \
	./configure && \
	make && \
	make install && \
	ldconfig

# cppzmq - official 0mq c++ bindings
# https://github.com/zeromq/cppzmq#build-instructions
RUN git clone -b 'v4.3.0' --single-branch --depth 1 https://github.com/zeromq/cppzmq.git && \
	cd cppzmq && \
	mkdir build && \
	cd build && \
	cmake .. && \
	make -j4 install

# cleanup
RUN rm -rf /libzmq
RUN rm -rf /cppzmq

# Copy in ZMQ source
COPY ZeroMQProxy/ /ZeroMQProxy/

# move to ZMQProxy dir
WORKDIR /ZeroMQProxy

# Make ZMQ executable
RUN make main

# Move back to root dir
WORKDIR /

# cp executable out of source directory
RUN cp ZeroMQProxy/zmq_proxy /usr/lib/zmq_proxy

# remove source directory so image is as lightweight as possible.
RUN rm -rf /ZeroMQProxy

# uninstall packages
RUN apt-get remove -y \
    ca-certificates \
	autoconf \
	automake \
	build-essential \
	cmake \
	git \
	libtool \
	pkg-config

RUN apt-get autoremove -y

# Expose subscribe port (no ryhme or reason to the selection of port numbers)
EXPOSE 6668

# Expose publish port
EXPOSE 6667

# Executable, subscribeAddress, publishAddress
ENTRYPOINT ["./usr/lib/zmq_proxy", "tcp://localhost:6668", "tcp://localhost:6667"]
