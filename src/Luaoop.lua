-- https://github.com/ImagicTheCat/Luaoop
-- MIT license (see LICENSE)

--[[
MIT License

Copyright (c) 2017 Imagic

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local xtype = require("xtype")

local lua5_1 = (string.find(_VERSION, "5.1") ~= nil)
local getmetatable, setmetatable, pairs = getmetatable, setmetatable, pairs
local table_pack = table.pack or function(...)
  local t = {...}
  t.n = select("#", ...)
  return t
end
local xtype_get = xtype.get

local Luaoop = {}
local class_mt = {}
local class = setmetatable(xtype.create("class", "xtype"), {
  xtype = "xtype"
})

-- proxy lua operators
local function op_tostring(lhs)
  local f = class_getop(lhs, "__tostring", nil, true)
  if f then
    return f(lhs)
  else -- default: print "instance<type>: 0x..."
    local mtable = getmetatable(lhs)
    mtable.__tostring = nil
    local str = string.gsub(tostring(lhs), "table:", "instance<"..class_name(lhs)..">:", 1)
    mtable.__tostring = op_tostring
    return str
  end
end

local function op_unm(lhs)
  local f = class_getop(lhs, "__unm", nil)
  if f then return f(lhs) end
end

local function op_call(lhs, ...)
  local f = class_getop(lhs, "__call", nil)
  if f then return f(lhs, ...) end
end

-- Build/re-build the class.
-- If a class is not already built, when used for inheritance or instantiation this function is called.
--
-- classdef: class
local function class_build(classdef)
  if not xtype.is(classdef, class) then error("invalid argument #1 (class expected)") end
  local luaoop = classdef.luaoop
  -- build
  --- prepare build, table with access to the class inherited properties
  if not luaoop.build then luaoop.build = {} end
  for k in pairs(luaoop.build) do luaoop.build[k] = nil end
  --- prepare instance build
  if not luaoop.instance_build then luaoop.instance_build = {} end
  for k in pairs(luaoop.instance_build) do luaoop.instance_build[k] = nil end
  --- inheritance
  ---- class build
  for i=#luaoop.bases,1,-1 do -- least specific, descending order
    local base = luaoop.bases[i]
    -- inherit class build properties
    for k,v in pairs(base.luaoop.build) do luaoop.build[k] = v end
    -- inherit class properties
    for k,v in pairs(base) do
      if k ~= "luaoop" and not string.sub(k, 1, 6) == "xtype_" then luaoop.build[k] = v end
    end
  end
  ---- instance build
  for k,v in pairs(luaoop.build) do -- inherit class build, everything but special properties
    if string.sub(k, 1, 2) ~= "__" then luaoop.instance_build[k] = v end
  end
  for k,v in pairs(classdef) do -- inherit class, everything but special properties
    if k ~= "luaoop" and not string.sub(k, 1, 6) == "xtype_" --
      and string.sub(k, 1, 2) ~= "__" then
      luaoop.instance_build[k] = v
    end
  end
  --- generic instance metatable
  if not luaoop.meta then
    luaoop.meta = {
      __index = luaoop.instance_build,
      -- operators
      __call = op_call,
      __unm = op_unm,
      __tostring = op_tostring,
    }
  end
  -- setup class inheritance
  getmetatable(classdef).__index = luaoop.build -- regular properties inheritance
end

local function proxy_gc(t)
  local mt = getmetatable(t)
  mt.destructor(mt.instance)
end

-- Create instance.
-- classdef: class
-- ...: constructor arguments
local function class_instantiate(classdef, ...)
  local mtable = getmetatable(classdef)
  local luaoop
  if mtable then luaoop = mtable.luaoop end

  if luaoop and not luaoop.type then -- valid class
    if not luaoop.build then
      class_build(classdef)
    end

    local __instantiate = luaoop.__instantiate
    if __instantiate then -- instantiate hook
      return __instantiate(classdef, ...)
    else -- regular
      -- create instance
      local t = setmetatable({}, luaoop.meta)

      local constructor = classdef.__construct
      local destructor = classdef.__destruct

      if destructor then
        local mtable, luaoop = force_custom_mtable(luaoop.meta, t) -- gc requires custom properties

        if lua5_1 then -- Lua 5.1
          local proxy = newproxy(true)
          local mt = getmetatable(proxy)
          mt.__gc = proxy_gc
          mt.destructor = destructor
          mt.instance = t
          luaoop.proxy = proxy
        else
          luaoop.proxy = setmetatable({}, { __gc = proxy_gc, instance = t, destructor = destructor })
        end
      end

      -- construct
      if constructor then constructor(t, ...) end
      return t
    end
  end
end

-- Create a new class.
-- name: human-readable string (doesn't have to be unique)
-- ...: base classes (single/multiple inheritance)
-- return created class
local function class_new(name, ...)
  local bases = table_pack(...)
  -- check inheritance validity and build
  for i=1, bases.n do
    local base = bases[i]
    if not xtype.is(base, class) then error("invalid base class #"..i) end
    -- build
    if not base.luaoop.build then class_build(base) end
  end
  -- create
  local c = xtype.create(name, ...)
  c.luaoop = {bases = bases}
  -- default print "class<type>: 0x..."
  local tostring_const = string.gsub(tostring(c), "table:", "class<"..name..">:", 1)
  return setmetatable(c, {
    xtype = class,
    __call = class_instantiate,
    __tostring = function(c) return tostring_const end
  })
end

-- Get the class metatable applied to the instances.
-- Useful to apply class behaviour to a custom table; will build the class if
-- not already built.
--
-- classdef: class
-- return metatable
local function class_meta(classdef)
  if not xtype.is(classdef, class) then error("invalid argument #1 (class expected)") end
  local luaoop = classdef.luaoop
  if not luaoop.build then class_build(classdef) end
  return luaoop.meta
end

class.new = class_new
class.meta = class_meta
class.instantiate = class_instantiate
class.build = class_build
class.mt.__call = function(t, ...) return class_new(...) end

-- Namespaces.
Luaoop.class = class

return Luaoop
