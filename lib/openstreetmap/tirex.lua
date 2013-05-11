--
-- Lua script for interface Tirex engine
--
--
-- Copyright (C) 2013, Hiroshi Miura
--
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU Affero General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    any later version.
--
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU Affero General Public License for more details.
--
--    You should have received a copy of the GNU Affero General Public License
--    along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

local udp = ngx.socket.udp
local timerat = ngx.timer.at
local time = ngx.time
local insert = table.insert
local concat = table.concat
local sub = string.sub
local len = string.len
local find = string.find
local gmatch = string.gmatch
local null = ngx.null
local pairs = pairs
local unpack = unpack
local setmetatable = setmetatable
local tonumber = tonumber
local tostring = tostring
local error = error
local sync = require "openstreetmap.sync"

module(...)

_VERSION = '0.10'

local mt = { __index = _M }

-- Constructor
--
function new(self, shmem)
    if not shmem then
        return nil
    end
    local sync = sync:new(shmem)
    if not sync then
        return nil
    end
    local sock, err = udp()
    if not sock then
        return nil, err
    end
    return setmetatable({ sock = sock, shmem = shmem, sync = sync }, mt)
end


-- function: serialize_tirex_msg
-- argument: table msg
--     hash table {key1=val1, key2=val2,....}
-- return: string
--     should be 'key1=val1\nkey2=val2\n....\n'
--
local function serialize_tirex_msg (msg)
    local str = ''
    for k,v in pairs(msg) do
        str = str .. k .. '=' .. tostring(v) .. '\n'
    end
    return str
end

-- function: deserialize_tirex_msg
-- arguments: string str: recieved message from tirex
--     should be 'key1=val1\nkey2=val2\n....\n'
-- return: table
--     hash table {key1=val1, key2=val2,....}
local function deserialize_tirex_msg (str) 
    local msg = {}
    for line in gmatch(str, "[^\n]+") do
        m,_,k,v = find(line,"([^=]+)=(.+)")
        if  k ~= '' then
            msg[k]=v
        end
    end
    return msg
end

-- function: connect
--
function connect(self, tirexpath)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end
    return sock:setpeername(tirexpath)
end

-- function: enqueue
-- arguments: string map
--            number x, y, z, priority
-- return id
--
function enqueue (self, map, x, y, z, priority)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end
    local id = time()
    local mx = x - x % 8
    local my = y - y % 8
    local req = serialize_tirex_msg({
        ["id"]   = tostring(id);
        ["type"] = 'metatile_enqueue_request';
        ["prio"] = priority;
        ["map"]  = map;
        ["x"]    = mx;
        ["y"]    = my;
        ["z"]    = z})
    local ok, err = sock:send(req)
    if not ok then
        return nil, err
    end
    return id, nil
end

-- function: read_reply
-- arguments: number id
-- return     msg, err
--
function _read_reply (sock)
    local data, err = sock:receive()
    if not data then
        return nil, err
    end
    local msg = deserialize_tirex_msg(tostring(data))
    local gotid = msg["id"]
    if tonumber(gotid) ~= tonumber(id) then
        -- push it for other client
        -- check whehter other client got it
        return msg, nil
    else
        return msg, nil
    end
end

function set_timeout(self, timeout)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:settimeout(timeout)
end

function close(self)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:close()
end


-- ========================================================
--  It does not share context and global vals/funcs
--
tirex_handler = function (premature)
    local tirexsock = 'unix:/var/run/tirex/master.sock'
    local tirex_cmd_max_size = 512
    local cmds = ngx.shared.cmds
    local stats = ngx.shared.stats

    if premature then
        -- clean up
        stats:delete('_tirex_handler')
        return
    end

    local udpsock = ngx.socket.udp()
    udpsock:setpeername(tirexsock)

    for i = 0, 10000 do
        -- send all requests first...
        local indexes = cmds:get_keys()
        for key,index in pairs(indexes) do
            local req = cmds:get(index)
            local ok,err=udpsock:send(req)
            if not ok then
                ngx.log(ngx.DEBUG, err)
            else
                cmds:delete(index)
            end
        end
        -- then receive response
        local data, err = udpsock:receive(tirex_cmd_max_size)
        if data then
            -- deserialize
            local msg = {}
            for line in string.gmatch(data, "[^\n]+") do
                m,_,k,v = string.find(line,"([^=]+)=(.+)")
                if  k ~= '' then
                    msg[k]=v
                end
            end
            local resp = string.format("%s:%d:%d:%d", msg["map"], msg["x"], msg["y"], msg["z"])
            -- send_signal to client context
            local ok, err = stats:incr(resp, 1)
            if not ok then
                ngx.log(ngx.DEBUG, "error in incr")
            end
        else
            ngx.log(ngx.DEBUG, err)
        end
    end
    udpsock:close()
    -- call myself
    ngx.timer.at(0.1, tirex_handler)
end
-- ========================================================

function push_request_tirex_render(index,req)
    local cmds = ngx.shared.cmds
    return cmds:safe_add(index, req, 0, 0)
end

function start_handler_if_needed()
    local handle = get_handle('_tirex_handler', 0, 0)
    if handle then
        -- only single light thread can handle Tirex
        ngx.log(ngx.INFO, "start tirex_handler")
        ngx.timer.at(0, tirex_handler)
    end
end

-- function: request_tirex_render
--  enqueue request to tirex server
--
function request_tirex_render(map, mx, my, mz, id)
    -- Create request command
    local index = string.format("%s:%d:%d:%d",map, mx, my, mz)
    local priority = 8
    local req = serialize_msg({
        ["id"]   = tostring(id);
        ["type"] = 'metatile_enqueue_request';
        ["prio"] = priority;
        ["map"]  = map;
        ["x"]    = mx;
        ["y"]    = my;
        ["z"]    = mz})
    push_request_tirex_render(index, req)
    start_handler_if_needed()
    return ngx.OK
end

-- funtion: send_tirex_request
-- argument: map, x, y, z
-- return:   true or nil
--
function send_tirex_request (map, x, y, z)
    local mx = x - x % 8
    local my = y - y % 8
    local mz = z
    local id = ngx.time()
    local index = string.format("%s:%d:%d:%d",map, mx, my, mz)

    local ok, err = get_handle(index, tirex_sync_duration, id)
    if not ok then
        -- someone have already start Tirex session
        -- wait other side(*), sync..
        return wait_signal(index, 30)
    end

    -- Ask Tirex session
    local ok = request_tirex_render(map, mx, my, mz, id)
    if not ok then
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    return wait_signal(index, 30)
end


