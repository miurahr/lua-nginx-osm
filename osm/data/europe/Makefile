POLY2LUA = ../../../utils/poly2lua/poly2lua
KML2POLY = ../../../utils/kml2poly.py

REGION = europe
REGIONS_DATA = alps.lua france.lua germany.lua  \
         albania.lua andorra.lua austria.lua \
         azores.lua belgium.lua bosnia-herzegovina.lua \
         british-isles.lua bulgaria.lua \
         croatia.lua cyprus.lua czech-republic.lua \
         denmark.lua estonia.lua \
         faroe-islands.lua finland.lua \
         great-britain.lua greece.lua hungary.lua \
         iceland.lua ireland-and-northern-ireland.lua \
         isle-of-man.lua italy.lua \
         kosovo.lua latvia.lua liechtenstein.lua \
         lithuania.lua luxembourg.lua macedonia.lua malta.lua \
         moldova.lua monaco.lua montenegro.lua \
         netherlands.lua norway.lua poland.lua portugal.lua \
         romania.lua \
         serbia.lua slovakia.lua spain.lua sweden.lua \
         switzerland.lua turkey.lua ukraine.lua
#         russia-european-part.lua 

.PHONY: all

all: $(REGIONS_DATA)

%.poly:
%.kml:
	wget http://download.geofabrik.de/$(REGION)/$@

%.lua: %.kml
	cat $< | $(KML2POLY) | $(POLY2LUA) > $@

clean:
	rm '*.lua'
