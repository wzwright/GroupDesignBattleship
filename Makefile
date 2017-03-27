#!/usr/bin/make -rf
all: frontend backend

.PHONY: all frontend backend install uninstall clean

PREFIX ?= /usr

frontend:
	cd frontend && npm install && npm run buildLocal

backend:
	make -C backend

install:
	make -C backend DESTDIR=$(abspath $(DESTDIR)) PREFIX=$(PREFIX) install
	install -m0644 -D frontend/index.html $(DESTDIR)$(PREFIX)/share/battleship/index.html
	cp -drv --no-preserve=ownership frontend/dist $(DESTDIR)$(PREFIX)/share/battleship/

uninstall:
	make -C backend DESTDIR=$(abspath $(DESTDIR)) PREFIX=$(PREFIX) uninstall
	rm -rf $(DESTDIR)$(PREFIX)/share/battleship

clean:
	make -C backend clean
	rm -rf frontend/dist
