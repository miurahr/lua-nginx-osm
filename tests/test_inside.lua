#!/usr/bin/env lua5.1

package.path = '../?.lua'

function table_print(t1)
    indent_string = string.rep(" ", 4)
    if t1 then
        for _, b in pairs(t1) do
            print('polygon:')
            for _, v in pairs(b) do
                print(indent_string,'lon=',v.lon,',lat=', v.lat)
            end
        end
    end
end

local osm_tile = require "osm.tile"
local osm_data = require "osm.data"
local x = 233816
local y = 100256
local z = 18

print('tile.data japan test:')
local region = assert(osm_data.get_region("japan"))
print('ok')
table_print(region,0)
print('tile inside test:')
assert(osm_tile.is_inside_region(region, x, y, z))
print('ok')


