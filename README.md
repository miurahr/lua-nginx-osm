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

Note that at least [ngx_lua 0.8.1](https://github.com/chaoslawful/lua-nginx-module/tags) or [ngx_openresty 1.2.1.14](http://openresty.org/#Download) is required.

Synopsis
========

    lua_package_path "/path/to/lua-nginx-osm/lib/?.lua;;";

    server {
        location /example {
            content_by_lua '
                local osm_utils = require "openstreetmap.utils"
                local osm_tirex = require "openstreetmap.tirex"
                local osm_tile = require "openstreetmap.tile"
                
                -- --------------------------------------------------
                -- check uri
                -- --------------------------------------------------
                local uri = ngx.var.uri
                local x, y, z = osm_utils.get_cordination(uri, "example", ".png")
                if not x then
                    return ngx.exit(ngx.HTTP_FORBIDDEN)
                end
                
                -- check x, y, z range
                local max_zoom = 18
                local min_zoom = 5
                if not check_integrity_xyzm(x, y, z, minz, maxz) then
                    return ngx.exit(ngx.HTTP_FORBIDDEN)
                end
                
                -- check x, y, z supported to generate
                local region = "japan"
                if not region_include(region, x, y, z)
                    return ngx.exit(ngx.HTTP_FORBIDDEN)
                end
                
                -- --------------------------------------------------
                -- generate tile and send back it
                -- --------------------------------------------------
                local tirex = osm_tirex:new()
                tirex:set_timeout(1000) -- 1 sec
                local ok, err = tirex:connect("unix:/var/run/tirex/master.sock")
                if not ok then
                    ngx.say("failed to connect: ", err)
                    return
                end
                local map = "example"
                local priority = 8
                local id, err = tirex:enqueue (map, x, y, z, priority)
                if not id then
                    ngx.say("failed to request tile generation: ", err)
                    return
                end
    
                local res, err = tirex:result(id)
                if not res then
                    ngx.say("failed to get result: ", err)
                    return
                end
    
                if res == ngx.null then
                    ngx.say("rendering failed.")
                    return
                end
                
                ok, err = tirex:close()
                if not ok then
                    ngx.say("failed to close: ", err)
                    return
                end
                
                local meta = tile.xyz_to_metatile_filename(x, y, z)
                ok, err = tile.send_tile(meta, x, y)
                if not ok then
                    ngx.say("failed to send tile:", err)
                end
            ';
        }
    }

Methods
=======

All of the Tirex commands have their own methods with the same name except all in lower case.


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
* the [lua-resty-memcached](https://github.com/agentzh/lua-resty-memcached) library
* the [lua-resty-mysql](https://github.com/agentzh/lua-resty-mysql) library


