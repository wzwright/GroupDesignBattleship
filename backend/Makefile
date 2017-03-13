#!/usr/bin/make -rf
all: lws install-plugin

make-datadir:
	mkdir -p build/datadir
	cp -rv example-config/ build/datadir/config

lws: make-datadir
	cd build && cmake ../libwebsockets -DLWS_WITH_LWSWS=1 -DCMAKE_INSTALL_PREFIX:PATH=${PWD}/build/datadir -DCMAKE_BUILD_TYPE=DEBUG
	cd build && make

install-plugin: make-datadir libprotocol_battleship.so
	install -d build/datadir/share/libwebsockets-test-server/plugins
	install libprotocol_battleship.so build/datadir/share/libwebsockets-test-server/plugins/

CC=gcc
CFLAGS += -fPIC
CFLAGS += -ggdb3
CFLAGS += -Ibuild/
LDLIBS += -ljansson
CFLAGS += $(shell python3-config --cflags)
LDFLAGS += $(shell python3-config --ldflags)
LDLIBS += $(shell python3-config --libs)

bship_logic.c bship_logic.h: bship_logic.pyx
	cython bship_logic.pyx -o bship_logic.c

bship_logic.o: bship_logic.c
	$(CC) -c bship_logic.c $(CFLAGS) $(LDFLAGS) $(LDLIBS) -o $@

libprotocol_battleship.so: protocol_battleship.o bship_logic.o
	$(CC) -shared $^ $(LDLIBS) -o $@

clean:
	rm -rf build
	rm -f protocol_battleship.o libprotocol_battleship.so bship_logic.o bship_logic.c bship_logic.h

run:
	build/bin/lwsws -c build/datadir/config

valgrind:
	LD_PRELOAD=build/datadir/share/libwebsockets-test-server/plugins/libprotocol_battleship.so valgrind --leak-check=full --read-var-info=yes --track-origins=yes build/bin/lwsws -c build/datadir/config

test:
	python3 -m unittest bship_logic.tests -v
