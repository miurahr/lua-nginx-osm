PREFIX ?=          /usr/local
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR ?=     $(PREFIX)/lib/lua/$(LUA_VERSION)
LUA_LIB_DATA_DIR = $(LUA_LIB_DIR)/osm/data/
INSTALL ?= install

POLY2LUA = ../../utils/poly2lua/poly2lua
KML2POLY = ../../utils/kml2poly.py

REGIONS = asia africa antarctica \
	  europe north-america \
	  australia-oceania \
	  central-america \
	  south-america
REGIONS_DATA = asia.lua africa.lua \
	  europe.lua north-america.lua \
	  australia-oceania.lua \
	  central-america.lua \
	  south-america.lua

.PHONY: all install

all: $(REGIONS_DATA)
	for r in $(REGIONS) ; do \
	  $(MAKE) -C $$r all ;\
	done

%.poly:
%.kml:
	wget http://download.geofabrik.de/$@

%.lua: %.kml
	cat $< | $(KML2POLY) | $(POLY2LUA) > $@

clean:
	rm '*.lua'
	for r in $(REGIONS) ; do \
	  $(MAKE) -C $$r clean ;\
	done

install: all
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DATA_DIR)
	$(INSTALL) *.lua $(DESTDIR)/$(LUA_LIB_DATA_DIR)
	for d in $(REGIONS) ; do \
	    $(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DATA_DIR)/$$(d)/ ;\
	    $(INSTALL) $(d)/*.lua $(DESTDIR)/$(LUA_LIB_DATA_DIR)/$$(d)/ ;\
	done
