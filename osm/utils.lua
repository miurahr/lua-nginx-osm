--
-- OpenStreetMap utility library
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

local sub = string.sub
local find = string.find
local tonumber = tonumber
local tostring = tostring
local setmetatable = setmetatable

module(...)

_VERSION = '0.10'

local mt = { __index = _M }

function get_cordination(uri, base, ext)
    local uri = tostring(uri)
    local captures = ''
    if ext == '' then
        captures = "^"..base.."/(%d+)/(%d+)/(%d+)"
    elseif sub(ext, 1) ~= '.' then
        captures = "^"..base.."/(%d+)/(%d+)/(%d+)"..'.'..ext
    else
        captures = "^"..base.."/(%d+)/(%d+)/(%d+)"..ext
    end
    local s,_,oz,ox,oy = find(uri, captures)
    if s == nil then
        return nil
    end
    return tonumber(ox), tonumber(oy), tonumber(oz)
end

function check_integrity_xyzm(x, y, z, minz, maxz)
    local x = tonumber(x)
    local y = tonumber(y)
    local z = tonumber(z)
    local minz = tonumber(minz)
    local maxz = tonumber(maxz)
    if z < minz or z > maxz then
        return nil
    end
    local lim = 2 ^ z
    if x < 0 or x >= lim or y < 0 or y >= lim then
        return nil
    end
    return true
end

function check_integrity_xyz(x, y, z)
    local lim = 2 ^ z
    if x < 0 or x >= lim or y < 0 or y >= lim then
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
