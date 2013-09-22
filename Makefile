PREFIX ?=          /usr/local
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR ?=     $(PREFIX)/lib/lua/$(LUA_VERSION)
INSTALL ?= install

POLY2LUA = utils/poly2lua/poly2lua

DATA = osm/data

.PHONY: all install

all: $(POLY2LUA) data

$(POLY2LUA): utils/poly2lua.cpp utils/CMakeLists.txt
	mkdir -p utils/poly2lua
	(cd utils/poly2lua; cmake ../)
	$(MAKE) -C utils/poly2lua

test:
	cd tests \
	lua5.1 test_tile.lua;\
	lua5.1 test_inside.lua

data:
	$(MAKE) -C $(DATA) all

clean:
	rm -rf utils/poly2lua
	$(MAKE) -C $(DATA) clean

install: all
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DIR)/osm
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DIR)/osm/data
	$(INSTALL) osm/*.lua $(DESTDIR)/$(LUA_LIB_DIR)/osm
	$(MAKE) -C $(DATA) install
