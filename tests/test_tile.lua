#!/usr/bin/env lua5.1

package.path = '../?.lua'

local osm_tile=require "osm.tile"
local map = "data"
local uri = "/18/233816/100256.png"

print('test with map data and uri:', uri)

local x, y, z = osm_tile.get_cordination(uri, "", "png")

print('get_cordination test:')
print('x', assert(tonumber(x), 233816))
print('y', assert(tonumber(y), 100256))
print('z', assert(tonumber(z), 18))
print('ok')
local minz=15
local maxz=18
print('check_integrity_xyzm test:')
assert(osm_tile.check_integrity_xyzm(x, y, z, minz, maxz))
maxz=17
assert(not(osm_tile.check_integrity_xyzm(x, y, z, minz, maxz)))
print('ok')

print('xyz_to_metatile_filename test:')
local tilefile = osm_tile.xyz_to_metatile_filename(x, y, z)
print(assert(tilefile, "18/49/152/23/90/128.meta"))
print('ok')
print('get_tile test:')
local tilepath = "./"..map.."/"..tilefile
local png, err = assert(osm_tile.get_tile(tilepath, x, y, z))
print('ok')

