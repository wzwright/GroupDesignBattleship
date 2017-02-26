#!/usr/bin/make -rf
all: lws install-plugin python_c_test

make-datadir:
	mkdir -p build/datadir
	cp -rv example-config/ build/datadir/config

lws: make-datadir
	cd build && cmake ../libwebsockets -DLWS_WITH_LWSWS=1 -DCMAKE_INSTALL_PREFIX:PATH=${PWD}/build/datadir -DCMAKE_BUILD_TYPE=DEBUG
	cd build && make

install-plugin: make-datadir libprotocol_battleships.so
	install -d build/datadir/share/libwebsockets-test-server/plugins
	install libprotocol_battleships.so build/datadir/share/libwebsockets-test-server/plugins/

CFLAGS += -fPIC
CFLAGS += -ggdb3
CFLAGS += -Ibuild/
LDLIBS += -ljansson
CFLAGS += $(shell python3-config --cflags)
LDFLAGS += $(shell python3-config --ldflags)
LDLIBS += $(shell python3-config --libs)

libprotocol_battleships.so: protocol_battleships.o py_logic.o
	gcc -shared $(LDLIBS) $^ -o $@

python_c_test:
	gcc $(CFLAGS) python_c_test.c py_logic.c -o python_c_test $(LDFLAGS) $(LDLIBS)

clean:
	rm -rf build
	rm -f protocol_battleships.o py_logic.o libprotocol_battleships.so 
	rm -f python_c_test

run:
	build/bin/lwsws -c build/datadir/config

valgrind:
	LD_PRELOAD=build/datadir/share/libwebsockets-test-server/plugins/libprotocol_battleships.so valgrind --leak-check=full --read-var-info=yes --track-origins=yes build/bin/lwsws -c build/datadir/config

test:
	python3 -m unittest bship_logic.tests -v
