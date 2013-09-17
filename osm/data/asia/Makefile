POLY2LUA = ../../../utils/poly2lua/poly2lua
KML2POLY = ../../../utils/kml2poly.py

REGION = asia
REGIONS_DATA = japan.lua india.lua  \
               china.lua indonesia.lua \
	       iran.lua iraq.lua \
	       israel-and-palestine.lua \
	       jordan.lua kazakhstan.lua \
	       kyrgyzstan.lua lebanon.lua \
	       malaysia-singapore-brunei.lua \
	       mongolia.lua pakistan.lua \
	       philippines.lua taiwan.lua \
               tajikistan.lua thailand.lua \
	       turkmenistan.lua uzbekistan.lua \
	       vietnam.lua

.PHONY: all

all: $(REGIONS_DATA)

%.poly:
%.kml:
	wget http://download.geofabrik.de/$(REGION)/$@

%.lua: %.kml
	cat $< | $(KML2POLY) | $(POLY2LUA) > $@

clean:
	rm '*.lua'
