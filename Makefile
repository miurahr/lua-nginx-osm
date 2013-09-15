PREFIX ?=          /usr/local
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR ?=     $(PREFIX)/lib/lua/$(LUA_VERSION)
INSTALL ?= install

POLY2LUA = utils/poly2lua
KML2POLY = utils/kml2poly.py

DATA = osm/data
REGIONS = $(DATA)/japan.lua $(DATA)/asia.lua $(DATA)/africa.lua \
		  $(DATA)/europe.lua $(DATA)/canada.lua
REGDATA = $(DATA)/japan.kml $(DATA)/asia.kml $(DATA)/africa.kml \
		  $(DATA)/europe.kml $(DATA)/canada.kml

.PHONY: all install

all: $(POLY2LUA) $(REGIONS)

$(POLY2LUA): utils/poly2lua.cpp utils/CMakeLists.txt
	(cd utils; cmake .)
	$(MAKE) -C utils

$(DATA)/%.lua: $(DATA)/%.kml
	cat $< | $(KML2POLY) | $(POLY2LUA) > $@


install: all
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DIR)/osm
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DIR)/osm/data
	$(INSTALL) osm/*.lua $(DESTDIR)/$(LUA_LIB_DIR)/osm
	$(INSTALL) osm/data/*.lua $(DESTDIR)/$(LUA_LIB_DIR)/osm/data

