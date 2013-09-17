POLY2LUA = ../../../utils/poly2lua/poly2lua
KML2POLY = ../../../utils/kml2poly.py

REGION = south-america
REGIONS_DATA =  \
         argentina.lua bolivia.lua brazil.lua chile.lua colombia.lua \
         ecuador.lua peru.lua uruguay.lua

.PHONY: all

all: $(REGIONS_DATA)

%.poly:
%.kml:
	wget http://download.geofabrik.de/$(REGION)/$@

%.lua: %.kml
	cat $< | $(KML2POLY) | $(POLY2LUA) > $@

clean:
	rm '*.lua'
