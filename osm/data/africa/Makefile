POLY2LUA = ../../../utils/poly2lua/poly2lua
KML2POLY = ../../../utils/kml2poly.py

REGION = africa
REGIONS_DATA = egypt.lua ethiopia.lua guinea.lua \
               congo-democratic-republic.lua \
	       canary-islands.lua burkina-faso.lua \
	       guinea-bissau.lua ivory-coast.lua \
	       liberia.lua libya.lua \
	       madagascar.lua morocco.lua \
	       nigeria.lua sierra-leone.lua \
	       somalia.lua south-africa-and-lesotho.lua \
	       tanzania.lua

.PHONY: all

all: $(REGIONS_DATA)

%.poly:
%.kml:
	wget http://download.geofabrik.de/$(REGION)/$@

%.lua: %.kml
	cat $< | $(KML2POLY) | $(POLY2LUA) > $@

clean:
	rm '*.lua'
