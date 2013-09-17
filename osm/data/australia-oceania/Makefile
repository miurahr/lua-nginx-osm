POLY2LUA = ../../../utils/poly2lua/poly2lua
KML2POLY = ../../../utils/kml2poly.py

REGION = australia-oceania
REGIONS_DATA = australia.lua  fiji.lua \
               new-caledonia.lua new-zealand.lua

.PHONY: all

all: $(REGIONS_DATA)

%.poly:
%.kml:
	wget http://download.geofabrik.de/$(REGION)/$@

%.lua: %.kml
	cat $< | $(KML2POLY) | $(POLY2LUA) > $@

clean:
	rm '*.lua'
