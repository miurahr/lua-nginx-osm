--
-- OpenStreetMap syncronization library
--
--
-- Copyright (C) 2013, Hiroshi Miura
--
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
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

local sleep = ngx.sleep
local tonumber = tonumber
local tostring = tostring

module(...)

_VERSION = '0.10'

local mt = { __index = _M }

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
--       wait_singal(key)
--       return result what thread(1) done
--
--   to syncronize amoung nginx threads
--   we use ngx.shared.DICT interface.
--   
--   Here we use ngx.shared.stats
--   you need to set /etc/conf.d/lua.conf
--      ngx_shared_dict stats 10m; 
--
--   if these functions returns 'nil'
--   status is undefined
--   something wrong
--
--   status definitions
--    key is not exist:    neutral
--    key is exist: someone got work token
--       val = 0:     now working
--       val > 0:     work is finished
--
--    key will be expired in timeout sec
--    we can use same key after timeout passed
--
-- ------------------------------------

-- Constructor
--
-- argument shoulbe ngx.shared.DICT itself
--
function new(self, shmem, interval)
    if not shmem then
        return nil
    end
    if not interval then
         interval = 1
    end
    local key="openstreetmap:sync_"..tostring(math:rand())
    success, err, forcible=shmem:add(key, 0, 0, 0)
    if not success then
        return nil
    else
        ok,err = shmem:delete(key)
    end
    return setmetatable({ shmem = shmem , interval = interval }, mt)
end

--
--  if key exist, it returns false
--  else it returns true
--
function get_handle(self, key, timeout, flag)
    local shmem = self.shmem
    local success,err,forcible = shmem:add(key, 0, timeout, flag)
    if success ~= false then
        return key, ''
    end
    return nil, ''
end

-- returns new value (maybe 1)
function send_signal(self, key)
    local shmem = self.shmem
    return shmem:incr(key, 1)
end

-- return nil if timeout in wait
--
function wait_signal(self, key, timeout)
    local shmem = self.shmem
    local interval = self.interval
    local timeout = tonumber(timeout)
    for i=0, timeout do
        local val, id = shmem:get(key)
        if val then
            if val > 0 then
                return id
            end
            sleep(interval)
        else
            return nil
        end
    end
    return nil
end

-- ===================================================================
