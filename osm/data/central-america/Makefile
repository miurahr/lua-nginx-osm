POLY2LUA = ../../../utils/poly2lua/poly2lua
KML2POLY = ../../../utils/kml2poly.py

REGION = central-america
REGIONS_DATA =  mexico.lua belize.lua cuba.lua guatemala.lua \
                haiti-and-domrep.lua

.PHONY: all

all: $(REGIONS_DATA)

%.poly:
%.kml:
	wget http://download.geofabrik.de/$(REGION)/$@

%.lua: %.kml
	cat $< | $(KML2POLY) | $(POLY2LUA) > $@

clean:
	rm '*.lua'
