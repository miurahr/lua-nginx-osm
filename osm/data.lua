--
-- OpenStreetMap region data library
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
local setmetatable = setmetatable
local error = error
local require = require
local myname = ...

module(...)

_VERSION = '0.30'

local target = {
    ['africa']                    = myname .. '.africa',
    ['burkina-faso']              = myname .. '.africa.burkina-faso',
    ['canary-islands']            = myname .. '.africa.canary-islands',
    ['congo-democratic-republic'] = myname .. '.africa.congo-democratic-republic',
    ['egypt']                     = myname .. '.africa.egypt',
    ['ethiopia']                  = myname .. '.africa.ethiopia',
    ['guinea-bissau']             = myname .. '.africa.guinea-bissau',
    ['guinea']                    = myname .. '.africa.guinea',
    ['ivory-coast']               = myname .. '.africa.ivory-coast',
    ['liberia']                   = myname .. '.africa.liberia',
    ['libya']                     = myname .. '.africa.libya',
    ['madagascar']                = myname .. '.africa.madagascar',
    ['morocco']                   = myname .. '.africa.morocco',
    ['nigeria']                   = myname .. '.africa.nigeria',
    ['sierra-leone']              = myname .. '.africa.sierra-leone',
    ['somalia']                   = myname .. '.africa.somalia',
    ['south-africa-and-lesotho']  = myname .. '.africa.south-africa-and-lesotho',
    ['south-africa']              = myname .. '.africa.south-africa-and-lesotho',
    ['lesotho']                   = myname .. '.africa.south-africa-and-lesotho',
    -- FIXME: split south-africa, lesotho
    ['tanzania']                  = myname .. '.africa.tanzania',

    ['asia']      = myname .. '.asia',
    ['china']     = myname .. '.asia.china',
    ['india']     = myname .. '.asia.india',
    ['indonesia'] = myname .. '.asia.indonesia',
    ['iran']      = myname .. '.asia.iran',
    ['iraq']      = myname .. '.asia.iraq',
    ['israel-and-palestine'] = '.asia.israel-and-palestine',
    ['israel']    = '.asia.israel-and-palestine',
    ['palestine'] = '.asia.israel-and-palestine',
    ['japan']     = myname .. '.asia.japan',
    ['jordan']    = myname .. '.asia.jordan',
    ['kazakhstan'] = myname .. '.asia.kazakhstan',
    ['kyrgyzstan'] = myname .. '.asia.kyrgyzstan',
    ['lebanon']   = myname .. '.asia.lebanon',
    ['malaysia-singapore-brunei'] = myname .. '.asia.malaysia-singapore-brunei',
    -- FIXME: split malaysia singapore and brunei
    ['mongolia']   = myname .. '.asia.mongolia',
    ['pakistan']   = myname .. '.asia.pakistan',
    ['philippines']= myname .. '.asia.philippines',
    ['taiwan']     = myname .. '.asia.taiwan',
    ['tajikistan'] = myname .. '.asia.tajikistan',
    ['thailand']   = myname .. '.asia.thailand',
    ['turkmenistan'] = myname .. '.asia.turkmenistan',
    ['uzbekistan'] = myname .. '.asia.uzbekistan',
    ['vietnam']    = myname .. '.vietnam',

    ['australia-oceania'] = myname .. '.australia-oceania',
    ['australia']         = myname .. '.australia-oceania.australia',
    ['fiji']              = myname .. '.australia-oceania.fiji',
    ['new-caledonia']     = myname .. '.australia-oceania.new-caledonia',
    ['new-zealand']       = myname .. '.australia-oceania.new-zealand',

    ['central-america']   = myname .. '.central-america',
    ['belize']            = myname .. '.central-america.belize',
    ['cuba']              = myname .. '.central-america.cuba',
    ['guatemala']         = myname .. '.central-america.quatemala',
    ['haiti-and-domrep']  = myname .. '.central-america.haiti-and-domrep',
    -- FIXME: split and rename
    ['mexico']            = myname .. '.central-america.mexico',

    ['europe']            = myname .. '.europe',
    ['albania']           = myname .. '.europe.albania',
    ['alps']              = myname .. '.europe.alps',
    ['andorra']           = myname .. '.europe.andorra',
    ['france']            = myname .. '.europe.france',
    ['germany']           = myname .. '.europe.germany',
    ['austria']           = myname .. '.europe.austria',
    ['azores']            = myname .. '.europe.azores',
    ['belgium']           = myname .. '.europe.belgium',
    ['bosnia-herzegovina']= myname .. '.europe.bosnia-herzegovina',
    ['british-isles'],    = myname .. '.europe.british-isles',
    ['bulgaria']          = myname .. '.europe.bulgalia',
    ['croatia']           = myname .. '.europe.croatia',
    ['cyprus']            = myname .. '.europe.cyprus','
    ['czech-republic']    = myname .. '.europe.czech-republic',
    ['denmark']           = myname .. '.europe.denmark',
    ['estonia']           = myname .. '.europe.estonia',
    ['faroe-islands']     = myname .. '.europe.faroe-islands',
    ['finland']           = myname .. '.europe.finland',
    ['great-britain']     = myname .. '.europe.great-britain',
    ['greece']            = myname .. '.europe.greece',
    ['hungary']           = myname .. '.europe.hungary',
    ['iceland']           = myname .. '.europe.iceland',
    ['ireland-and-northern-ireland']= myname .. '.europe.ireland-and-northern-ireland',
    ['isle-of-man']       = myname .. '.europe.isle-of-man',
    ['italy']             = myname .. '.europe.italy',
    ['kosovo']            = myname .. '.europe.kosovo',
    ['latvia']            = myname .. '.europe.latvia',
    ['liechtenstein']     = myname .. '.europe.liechtenstein',
    ['luxembourg']        = myname .. '.europe.luxembourg',
    ['macedonia']         = myname .. '.europe.macedonia',
    ['malta']             = myname .. '.europe.malta',
    ['moldova']           = myname .. '.europe.moldova',
    ['monaco']            = myname .. '.europe.monaco',
    ['montenegro']        = myname .. '.europe.montenegro',
    ['netherlands']       = myname .. '.europe.netherlands',
    ['norway']            = myname .. '.europe.norway',
    ['poland']            = myname .. '.europe.poland',
    ['portugal']          = myname .. '.europe.portugal',
    ['romania']           = myname .. '.europe.romania',
    ['russia-european-part']= myname .. '.europe.russia-european-part',
    ['serbia']            = myname .. '.europe.serbia',
    ['slovakia']          = myname .. '.europe.slovakia',
    ['slovenia']          = myname .. '.europe.slovenia',
    ['spain']             = myname .. '.europe.spain',
    ['sweden']            = myname .. '.europe.sweden',
    ['switzerland']       = myname .. '.europe.switzerland',
    ['turkey']            = myname .. '.europe.turkey',
    ['ukraine']           = myname .. '.europe.ukraine',

    ['north-america']     = myname .. '.north-america',
    ['canada']            = myname .. '.north-america.canada',
    ['greenland']         = myname .. '.north-america.greenland',
    ['us-midwest']        = myname .. '.north-america.us-midwest',
    ['us-northeast']      = myname .. '.north-america.us-northeast',
    ['us-pacific']        = myname .. '.north-america.us-pacific',
    ['us-south']          = myname .. '.north-america.us-south',
    ['us-west']           = myname .. '.north-america.us-west',

    ['south-america']     = myname .. '.south-america',
    ['argentina']         = myname .. '.south-america.argentina',
    ['bolivia']           = myname .. '.south-america.bolvia',
    ['brazil']            = myname .. '.south-america.brazil',
    ['chile']             = myname .. '.south-america.chile',
    ['colombia']          = myname .. '.south-america.colombia',
    ['ecuador']           = myname .. '.south-america.ecuador',
    ['peru']              = myname .. '.south-america.peru',
    ['uruguay']           = myname .. '.south-america.uruguay',

    ['antarctica']        = myname .. '.antarctica',
    ['world']             = myname .. '.world'
  }

local world = {
   {
    {lon=-180, lat=-89.9},
    {lon=-180, lat=89.9},
    {lon=180, lat=89.9},
    {lon=180, lat=-89.9},
    {lon=-180, lat=-89.9}
   }
}

function get_region(name)
    if name == 'world' then
        return world
    end
    if not target[name] then
        return nil
    end
    local region = require(target[name])
    return region
end

local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
}

setmetatable(_M, class_mt)
