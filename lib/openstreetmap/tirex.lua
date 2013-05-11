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
local null = ngx.null

local insert = table.insert
local concat = table.concat

local sub = string.sub
local len = string.len
local find = string.find
local gmatch = string.gmatch
local format = string.format

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

-- ========================================================
--  It does not share context and global vals/funcs
--
local tirex_handler
tirex_handler = function (premature, shmem)
    local status = shmem
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
        local indexes = status:get_keys()
        for key,index in pairs(indexes) do
            local req = status:get(index)
            local ok,err=udpsock:send(req)
            if not ok then
                ngx.log(ngx.DEBUG, err)
            else
                status:delete(index)
            end
        end
        -- then receive response
        local data, err = udpsock:receive(tirex_cmd_max_size)
        if data then
            -- deserialize
            local msg = {}
            for line in gmatch(data, "[^\n]+") do
                m,_,k,v = find(line,"([^=]+)=(.+)")
                if  k ~= '' then
                    msg[k]=v
                end
            end
            local resp = format("%s:%d:%d:%d", msg["map"], msg["x"], msg["y"], msg["z"])
            -- send_signal to client context
            local ok, err = status:incr(resp, 1)
            if not ok then
                ngx.log(ngx.DEBUG, "error in incr")
            end
        else
            ngx.log(ngx.DEBUG, err)
        end
    end
    udpsock:close()
    -- call myself
    timerat(0.1, tirex_handler, status)
end
-- ========================================================

function push_request_tirex_render(self, index, req)
    local status = self.shmem
    return status:safe_add(index, req, 0, 0)
end


-- function: request_tirex_render
--  enqueue request to tirex server
--
function request_tirex_render(map, mx, my, mz, id)
    local status = self.shmem
    -- Create request command
    local index = format("%s:%d:%d:%d",map, mx, my, mz)
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

    local handle = sync.get_handle('_tirex_handler', 0, 0)
    if handle then
        -- only single light thread can handle Tirex
        timerat(0, tirex_handler, status)
    end

    return true
end

-- funtion: send_tirex_request
-- argument: map, x, y, z
-- return:   true or nil
--
function send_tirex_request (self, map, x, y, z)
    local mx = x - x % 8
    local my = y - y % 8
    local mz = z
    local id = ngx_time()
    local index = format("%s:%d:%d:%d",map, mx, my, mz)

    local ok, err = sync.get_handle(index, tirex_sync_duration, id)
    if not ok then
        -- someone have already start Tirex session
        -- wait other side(*), sync..
        return sync.wait_signal(index, 30)
    end

    -- Ask Tirex session
    local ok = request_tirex_render(map, mx, my, mz, id)
    if not ok then
        return nil
    end
    return sync.wait_signal(index, 30)
end

local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
}

setmetatable(_M, class_mt)
