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

local shmem = ngx.shared.osm_tirex

local udp = ngx.socket.udp
local time = ngx.time
local sleep = ngx.sleep

local insert = table.insert
local concat = table.concat

local sub = string.sub
local len = string.len
local find = string.find
local gmatch = string.gmatch
local format = string.format

local pairs = pairs
local unpack = unpack
local tonumber = tonumber
local tostring = tostring
local error = error
local setmetatable = setmetatable

local tirexsock = 'unix:/var/run/tirex/master.sock'
local tirex_cmd_max_size = 512

module(...)

_VERSION = '0.20'

-- ------------------------------------
-- Syncronize thread functions
--
--   thread(1)
--       get_handle(key)
--       do work
--       store work result somewhere
--       send_signal(key)
--       return result
--
--   thread(2)
--       get_handle(key) fails then
--       wait_singal(key, timeout)
--       return result what thread(1) done
--
--   to syncronize amoung nginx threads
--   we use ngx.shared.DICT interface.
--   
--   Here we use ngx.shared.osm_tirex
--   you need to set /etc/conf.d/lua.conf
--      ngx_shared_dict osm_tirex 10m; 
--
--   if these functions returns 'nil'
--   status is undefined
--   something wrong
--
--   status definitions
--    key is not exist:    neutral
--    key is exist: someone got work token
--       flag = 0:     now working
--       flag = 3:     work is finished
--
--    key will be expired in timeout sec
--    we can use same key after timeout passed
--
-- ------------------------------------

--
--  if key exist, it returns false
--  else it returns true
--
function get_handle(key, timeout, flag)
    local success,err,forcible = shmem:add(key, 0, timeout, flag)
    if success ~= false then
        return key, ''
    end
    return nil, ''
end

function remove_handle(key)
    return shmem:delete(key)
end

-- return nil if timeout in wait
--
function wait_signal(key, timeout)
    local timeout = tonumber(timeout)
    for i=0, timeout do
        local val, flag = shmem:get(key)
        if val then
            if flag == 3 then
                return true
            end
            sleep(1)
        else
            return nil
        end
    end
    return nil
end

-- function: serialize_msg
-- argument: table msg
--     hash table {key1=val1, key2=val2,....}
-- return: string
--     should be 'key1=val1\nkey2=val2\n....\n'
--
function serialize_msg (msg)
    local str = ''
    for k,v in pairs(msg) do
        str = str .. k .. '=' .. tostring(v) .. '\n'
    end
    return str
end

-- function: deserialize_msg
-- arguments: string str: recieved message from tirex
--     should be 'key1=val1\nkey2=val2\n....\n'
-- return: table
--     hash table {key1=val1, key2=val2,....}
function deserialize_msg (str) 
    local msg = {}
    for line in gmatch(str, "[^\n]+") do
        local m,_,k,v = find(line,"([^=]+)=(.+)")
        if  k ~= '' then
            msg[k]=v
        end
    end
    return msg
end

-- ========================================================

function get_key(map, mx, my, mz)
    return format("%s:%d:%d:%d",map, mx, my, mz)
end

-- function: send_tirex_request
function send_tirex_request(req)
    local udpsock = udp()
    udpsock:setpeername(tirexsock)

    local ok,err=udpsock:send(req)
    if not ok then
        udpsock:close()
        return nil
    end
    -- then receive response
    local data, err = udpsock:receive(tirex_cmd_max_size)
    udpsock:close()
    if not data then
        return nil
    end

    return deserialize_msg(data)
end

-- function: request_render
--  enqueue request to tirex server
--
function request_render(map, mx, my, mz, id, priority)
    -- Create request command
    local req = serialize_msg({
        ["id"]   = tostring(id);
        ["type"] = 'metatile_enqueue_request';
        ["prio"] = priority;
        ["map"]  = map;
        ["x"]    = mx;
        ["y"]    = my;
        ["z"]    = mz})
    local index = get_key(map, mx, my, mz)
    shmem:set(index, data, 120, 1) 
    local msg = send_tirex_request(req)

    if not msg then
        -- propagate error to waiting context
        remove_handle(index)
        return nil
    end
    local index = get_key(msg["map"], msg["x"], msg["y"], msg["z"])
    local ok, err = shmem:set(index, data, 300, 3) -- send signal
    if not ok then
        return nil
    end
    return true
end


-- funtion: send_request
-- argument: map, x, y, z
-- return:   true or nil
--
function send_request (map, x, y, z)
    return enqueue_request(map, x, y, z, 1)
end

-- funtion: enqueue_request
-- argument: map, x, y, z
-- return:   true or nil
--
function enqueue_request (map, x, y, z, priority)
    local mx = x - x % 8
    local my = y - y % 8
    local mz = z
    local id = time()
    local priority = tonumber(priority)
    local index = get_key(map, mx, my, mz)

    local ok, err = get_handle(index, 300, 0)
    if not ok then
        -- someone have already start Tirex session
        -- wait other side(*), sync..
        return wait_signal(index, 30)
    end

    -- Ask Tirex session
    local ok = request_render(map, mx, my, mz, id, priority)
    if not ok then
        return nil
    end
end

-- funtion: dequeue_request
-- argument: map, x, y, z
-- return:   true or nil
--
function dequeue_request (map, x, y, z, priority)
    local mx = x - x % 8
    local my = y - y % 8
    local mz = z
    local id = time()
    local priority = tonumber(priority)
        
    -- Create request command
    local req = serialize_msg({
        ["id"]   = tostring(id);
        ["type"] = 'metatile_remove_request';
        ["prio"] = priority;
        ["map"]  = map;
        ["x"]    = mx;
        ["y"]    = my;
        ["z"]    = mz})
    local ok = send_tirex_request(req)
    if not ok then
        return nil
    end
end

-- function: ping_request()
-- return: true or nil
function ping_request()
    -- Create request command
    local req = serialize_msg({
        ["type"] = 'ping'})
    local msg = send_tirex_request(req)
    if not msg then
        return nil
    end
    if msg["result"] ~= 'ok' then
        return nil
    end
    return true
end

local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
}

setmetatable(_M, class_mt)
