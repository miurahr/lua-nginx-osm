Name
====

lua-nginx-osm - Lua Tirex client driver for the ngx_lua based on the cosocket API

Status
======

This library is considered experimental status.

Description
===========

This Lua library is a Tirex client driver for the ngx_lua nginx module:

http://wiki.nginx.org/HttpLuaModule

This Lua library takes advantage of ngx_lua's cosocket API, which ensures 
100% nonblocking behavior.

Note that at least [ngx_lua 0.8.1](https://github.com/chaoslawful/lua-nginx-module/tags) is required.

Synopsis
========

    lua_package_path "/path/to/lua-nginx-osm/?.lua;;";
    lua_shared_dict osm_tirex 10m; ## mandatory to use osm.tirex module
    lua_socket_log_errors off;

    server {
        location /example {
            content_by_lua '
                local tirex = require "osm.tirex"
                local tile = require "osm.tile"
		local data = require "osm.data"
                
                -- --------------------------------------------------
                -- check uri
                -- --------------------------------------------------
                local uri = ngx.var.uri
		local map = 'example'
                local x, y, z = tile.get_cordination(uri, map, ".png")
                if not x then
                    return ngx.exit(ngx.HTTP_FORBIDDEN)
                end
                
                -- check x, y, z range
                local max_zoom = 18
                local min_zoom = 5
                if not tile.check_integrity_xyzm(x, y, z, minz, maxz) then
                    return ngx.exit(ngx.HTTP_FORBIDDEN)
                end
                
                -- check x, y, z supported to generate
		local region = data.get_region('japan')
                if not osm_tile.region_include(region, x, y, z)
                    return ngx.exit(ngx.HTTP_FORBIDDEN)
                end
                
                -- try renderd file.
                local png, err = tile.get_tile(map, x, y, z)
                if png then
                    ngx.header.content_type = 'image/png'
                    ngx.print(png)
                    return ngx.OK
                end
		
                -- ask tirex to render it
                local ok = tirex.send_request(map, x, y, z)
                if not ok then
                    return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
                end

		-- get tile image from metatile
                local tilefile = tile.xyz_to_metatile_filename(x, y, z)
                local tilepath = tirex_tilepath..'/'..map..'/'..tilefile
                local png, err = osm_tile.get_tile(tilepath, x, y, z)
                if png then
                    ngx.header.content_type = 'image/png'
                    ngx.print(png)
                    return ngx.OK
                end
                ngx.log(ngx.ERR, err)
                return ngx.exit(ngx.HTTP_NOT_FOUND)
            ';
        }
    }

Methods
=======

only send_request() is supported.

TODO
====

Community
=========

English Mailing List
--------------------

The [osm-dev](https://lists.openstreetmap.org/lists/osm-dev) mailing list is for English speakers.
It is for all topic about development  openstreetmap.

Japanese Mailing List
--------------------

The [OSM-ja](https://lists.openstreetmap.org/lists/talk-ja) mailing list is for Japanese speakers.
It is for all topic about openstreetmap in Japanese or in Japan.

Bugs and Patches
================

Please report bugs or submit patches by

1. creating a ticket on the [GitHub Issue Tracker](http://github.com/miurahr/lua-nginx-osm/issues),

Author
======

Hiroshi Miura <miurahr@osmf.jp>, OpenStreetMap Foundation Japan

Copyright and License
=====================

Hiroshi Miura, 2013 

Distributed under GPLv3

See Also
========
* the ngx_lua module: http://wiki.nginx.org/HttpLuaModule


