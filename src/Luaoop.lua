local Luaoop = {}

local lua5_1 = (string.find(_VERSION, "5.1") ~= nil)

-- CLASS MODULE

local class = {}

-- force an instance to have a custom mtable (by default they share the same table for optimization)
-- mtable: current instance mtable
-- t: instance
-- return custom mtable, custom luaoop table
local function force_custom_mtable(mtable, t)
  if not mtable.luaoop.custom then
    -- copy mtable
    local new_mtable = {}
    for k,v in pairs(mtable) do
      new_mtable[k] = v
    end

    -- copy luaoop
    new_mtable.luaoop = {}
    for k,v in pairs(mtable.luaoop) do
      new_mtable.luaoop[k] = v
    end

    -- flag custom
    new_mtable.luaoop.custom = true
    setmetatable(t, new_mtable)

    mtable = new_mtable
  end

  return mtable, mtable.luaoop
end

-- create a new class
-- name: identifier for debugging purpose
-- ...: base classes (single/multiple inheritance)
-- return created class
function class.new(name, ...)
  if type(name) == "string" then
    local c = { -- init class
      -- binary operator tables
      __add = {},
      __sub = {},
      __mul = {},
      __div = {},
      __pow = {},
      __mod = {},
      __eq = {},
      __le = {},
      __lt = {},
      __concat = {}
    }
    local bases = {...}

    local types = { [name] = true } -- add self type

    -- check inheritance validity and build
    for i,base in pairs(bases) do
      local mtable = getmetatable(base)
      local luaoop
      if mtable then
        luaoop = mtable.luaoop
      end

      if not luaoop or luaoop.type then -- if not a class
        error("invalid base class #"..i)
      end

      if not luaoop.build then class.build(base) end
    end

    return setmetatable(c, { 
      luaoop = { bases = bases, name = name }, 
      __call = function(c, ...) return class.instantiate(c, ...) end, 
      __tostring = function(c) return "class<"..class.name(c)..">" end
    })
  else
    error("class name is not a string")
  end
end

-- t: class or instance
-- return class name or nil
function class.name(t)
  if t then
    local mtable = getmetatable(t)
    local luaoop
    if mtable then luaoop = mtable.luaoop end

    if luaoop then
      return luaoop.name
    end
  end
end

-- t: instance
-- return the type (class) or nil
function class.type(t)
  if t then
    local mtable = getmetatable(t)
    local luaoop
    if mtable then luaoop = mtable.luaoop end

    if luaoop then
      return luaoop.type
    end
  end
end

-- check if an instance/class is/inherits from a specific class
-- t: class or instance
-- classdef: can be nil to check if t is a valid (built) class
function class.is(t, classdef)
  if t then
    local mtable = getmetatable(t)
    local luaoop
    if mtable then luaoop = mtable.luaoop end

    if luaoop and luaoop.types then
      if not classdef then
        return not luaoop.type
      else
        return luaoop.types[classdef]
      end
    end
  end

  return false
end

-- t: class or instance
-- return types map (type => true) or nil
function class.types(t)
  if t then
    local mtable = getmetatable(t)
    local luaoop
    if mtable then luaoop = mtable.luaoop end

    if luaoop and luaoop.types then
      local types = {}
      for k,v in pairs(luaoop.types) do
        types[k] = v
      end

      return types
    end
  end
end

-- get operator
-- lhs: instance
-- name: full name of the operator (starting with "__")
-- rhs: any value, can be nil for unary operators
-- no_error: if passed/true, will not trigger an error if no operator was found
function class.getop(lhs, name, rhs, no_error)
  local mtable = getmetatable(lhs)
  local luaoop
  if mtable then luaoop = mtable.luaoop end

  if luaoop and luaoop.type then -- check if instance
    local rtype, f
    if rhs ~= nil then -- not nil, binary
      rtype = class.type(rhs) -- Luaoop type
      if not rtype then rtype = type(rhs) end -- fallback to Lua type

      f = luaoop.type[name][rtype]
    else
      f = luaoop.type[name]
    end

    if f then
      return f
    elseif not no_error then
      local drtype
      if rtype == nil then
        drtype = "nil"
      elseif type(rtype) == "string" then
        drtype = rtype
      else
        drtype = class.name(rtype)
      end
      error("operator <"..luaoop.name.."> ["..string.sub(name, 3).."] <"..drtype.."> undefined")
    end
  else
    if not no_error then
      error("left operand for operator ["..string.sub(name, 3).."] is not an instance")
    end
  end
end

local getop = class.getop

-- proxy lua operators
local function op_tostring(lhs)
  local f = getop(lhs, "__tostring", nil, true)
  if f then
    return f(lhs)
  else
    return "class<"..class.name(lhs)..">: "..class.id(lhs)
  end
end

local function op_concat(lhs,rhs)
  local f = getop(lhs, "__concat", rhs, true)
  if f then 
    return f(lhs,rhs) 
  end

  f = getop(rhs, "__concat", lhs)
  if f then 
    return f(rhs,lhs,true) 
  end
end

local function op_unm(lhs)
  local f = getop(lhs, "__unm", nil)
  if f then return f(lhs) end
end

local function op_call(lhs, ...)
  local f = getop(lhs, "__call", nil)
  if f then return f(lhs, ...) end
end

local function op_add(lhs,rhs)
  local f = getop(lhs, "__add", rhs, true)
  if f then 
    return f(lhs,rhs) 
  end

  f = getop(rhs, "__add", lhs)
  if f then 
    return f(rhs,lhs) 
  end
end

local function op_sub(lhs,rhs) -- also deduced as lhs+(-rhs)
  local f = getop(lhs, "__sub", rhs, true)
  if f then 
    return f(lhs,rhs)
  end

  f = getop(lhs, "__add", rhs)
  if f then
    return f(lhs, -rhs)
  end
end

local function op_mul(lhs,rhs)
  local f = getop(lhs, "__mul", rhs, true)
  if f then 
    return f(lhs,rhs) 
  end

  f = getop(rhs, "__mul", lhs)
  if f then 
    return f(rhs,lhs) 
  end
end

local function op_div(lhs,rhs)
  local f = getop(lhs, "__div", rhs)
  if f then 
    return f(lhs,rhs) 
  end
end

local function op_mod(lhs,rhs)
  local f = getop(lhs, "__mod", rhs)
  if f then 
    return f(lhs,rhs) 
  end
end

local function op_pow(lhs,rhs)
  local f = getop(lhs, "__pow", rhs)
  if f then 
    return f(lhs,rhs) 
  end
end

local function op_eq(lhs,rhs)
  local f = getop(lhs, "__eq", rhs, true)
  if f then 
    return f(lhs,rhs) 
  end
end

local function op_lt(lhs,rhs)
  local f = getop(lhs, "__lt", rhs)
  if f then 
    return f(lhs,rhs) 
  end
end

local function op_le(lhs,rhs)
  local f = getop(lhs, "__le", rhs)
  if f then 
    return f(lhs,rhs) 
  end
end

-- get the class metatable applied to the instances
-- useful to apply class behaviour to a custom table
-- will build the class if not already built
-- classdef: class
-- return meta or nil
function class.meta(classdef)
  if classdef then
    local mtable = getmetatable(classdef)
    local luaoop
    if mtable then luaoop = mtable.luaoop end

    if luaoop and not luaoop.type then -- if class
      if not luaoop.build then
        class.build(classdef)
      end

      return luaoop.meta
    end
  end
end

-- create instance
-- classdef: class
-- ...: constructor arguments
function class.instantiate(classdef, ...)
  local meta = class.meta(classdef)

  if meta then -- valid meta
    -- create instance
    local t = setmetatable({}, meta) 

    local constructor = t.__construct
    local destructor = t.__destruct

    if destructor then
      local mtable, luaoop = force_custom_mtable(meta, t) -- gc requires custom properties

      local gc = function()
        destructor(t)
      end

      if lua5_1 then -- Lua 5.1
        local proxy = newproxy(true)
        getmetatable(proxy).__gc = gc
        luaoop.proxy = proxy
      else
        luaoop.proxy = setmetatable({}, { __gc = gc })
      end
    end

    -- construct
    if constructor then constructor(t, ...) end
    return t
  end
end

-- build class
-- will build/re-build the class
-- (if a class is not already built, when used for inheritance or instantiation this function is called)
-- classdef: class
function class.build(classdef)
  if classdef then
    local mtable = getmetatable(classdef)
    local luaoop
    if mtable then luaoop = mtable.luaoop end

    if luaoop and not luaoop.type then
      -- build
      -- prepare build, table with access to the class inherited properties
      if not luaoop.build then luaoop.build = {} end
      for k in pairs(luaoop.build) do luaoop.build[k] = nil end

      -- prepare types
      if not luaoop.types then luaoop.types = {} end
      for k in pairs(luaoop.types) do luaoop.types[k] = nil end

      -- prepare instance build
      if not luaoop.instance_build then luaoop.instance_build = {} end
      for k in pairs(luaoop.instance_build) do luaoop.instance_build[k] = nil end

      --- inheritance
      for _,base in ipairs(luaoop.bases) do
        local base_luaoop = getmetatable(base).luaoop

        -- types
        for t in pairs(base_luaoop.types) do
          luaoop.types[t] = true
        end

        -- class properties
        for k,v in pairs(base) do
          if type(v) == "table" and string.sub(k, 1, 2) == "__" then -- inherit/merge special tables
            local table = luaoop.build[k]
            if not table then
              table = {}
              luaoop.build[k] = table
            end

            for tk, tv in pairs(v) do
              table[tk] = tv
            end
          else -- inherit regular property
            luaoop.build[k] = v
          end
        end

        -- class build properties
        for k,v in pairs(base_luaoop.build) do
          if type(v) == "table" and string.sub(k, 1, 2) == "__" then -- inherit/merge special tables
            local table = luaoop.build[k]
            if not table then
              table = {}
              luaoop.build[k] = table
            end

            for tk, tv in pairs(v) do
              table[tk] = tv
            end
          else -- inherit regular property
            luaoop.build[k] = v
          end
        end

      end

      -- add self type
      luaoop.types[classdef] = true

      --- build generic instance metatable
      ---- instance build
      for k,v in pairs(luaoop.build) do -- class build, everything but special tables
        if type(v) ~= "table" or string.sub(k, 1, 2) ~= "__" then 
          luaoop.instance_build[k] = v
        end
      end

      for k,v in pairs(classdef) do -- class, everything but special tables
        if type(v) ~= "table" or string.sub(k, 1, 2) ~= "__" then 
          luaoop.instance_build[k] = v
        end
      end

      ---- build generic instance metatable
      if not luaoop.meta then 
        luaoop.meta = {
          __index = luaoop.instance_build, 
          luaoop = {
            bases = luaoop.bases,
            name = luaoop.name,
            types = luaoop.types,
            type = classdef
          },

          -- add operators metamethods
          __call = op_call,
          __unm = op_unm,
          __add = op_add,
          __sub = op_sub,
          __mul = op_mul,
          __div = op_div,
          __pow = op_pow,
          __mod = op_mod,
          __eq = op_eq,
          __le = op_le,
          __lt = op_lt,
          __tostring = op_tostring,
          __concat = op_concat
        }
      end

      -- setup class 
      mtable.__index = luaoop.build -- regular properties inheritance

      --- special tables inheritance
      for k,v in pairs(classdef) do
        if type(v) == "table" and string.sub(k, 1, 2) == "__" then 
          setmetatable(v, { __index = luaoop.build[k] })
        end
      end
    end
  end
end

-- return address number from table (tostring hack, return nil on failure)
local function table_addr(t)
  local hex = string.match(tostring(t), ".*(0x%x+).*")
  if hex then return tonumber(hex) end
end

local addr_counter = 0 -- addr counter in replacement of table_addr

-- works by using tostring(table) address hack or using a counter instead on failure
-- t: instance
-- return unique instance id or nil
function class.id(t)
  if t then
    local mtable = getmetatable(t)
    local luaoop
    if mtable then luaoop = mtable.luaoop end
    if luaoop then
      mtable, luaoop = force_custom_mtable(mtable, t) -- id requires custom properties

      if luaoop.id then -- return existing id
        return luaoop.id
      elseif luaoop.type then -- generate id
        -- remove tostring proxy
        mtable.__tostring = nil
        -- generate addr
        luaoop.id = table_addr(t)
        -- reset tostring proxy
        mtable.__tostring = op_tostring

        if not luaoop.id then
          luaoop.id = addr_counter
          addr_counter = addr_counter+1
        end

        return luaoop.id
      end
    end
  end
end

-- t: instance
-- return unique instance data table or nil
function class.data(t)
  if t then
    local mtable = getmetatable(t)
    local luaoop
    if mtable then luaoop = mtable.luaoop end
    if luaoop and luaoop.type then
      mtable, luaoop = force_custom_mtable(mtable, t) -- data requires custom properties

      if not luaoop.data then -- create data table
        luaoop.data = {}
      end

      return luaoop.data
    end
  end
end

-- SHORTCUTS
setmetatable(class, { __call = function(t, name, ...) 
  return class.new(name, ...)
end})

-- NAMESPACES
Luaoop.class = class


-- LuaJIT CCLASS MODULE

if jit then

local ffi = require("ffi")
local C = ffi.C
local cclass = {}

-- change the symbols dict for the next following cclass (ffi.C by default)
function cclass.symbols(symbols)
  C = symbols
end

local cintptr_t = ffi.typeof("intptr_t")
local function f_id(self)
  return tonumber(ffi.cast(cintptr_t, self))
end

-- NOTE: operator redundant code until better way

-- optimize special method name resolution
local op_dict = {}

-- get operator from instance lhs, rhs can be nil for unary operators
local function getop(lhs, name, rhs, no_error)
  local f = nil

  local rtype = nil
  if type(rhs) == "cdata" then
    rtype = rhs:__type()
  else
    rtype = type(rhs)
  end

  local ltype = nil
  if type(lhs) == "cdata" then
    ltype = lhs:__type()
  else
    ltype = type(lhs)
  end

  -- optimization using op_dict
  local dict = op_dict[name]
  if not dict then
    dict = {}
    op_dict[name] = dict
  end

  -- method name
  local fname = dict[rtype]
  if not fname then -- generate fname
    if rhs then
      fname = "__"..name.."_"..rtype
    else
      fname = "__"..name
    end

    dict[rtype] = fname
  end

  if type(lhs) == "cdata" then
    f = lhs:__get(fname)
  end

  if f then
    return f
  elseif not no_error then
    error("operator <"..ltype.."> ["..name.."] <"..rtype.."> undefined")
  end
end

-- proxy lua operators
local function op_tostring(lhs)
  local f = getop(lhs, "tostring", nil, true)
  if f then
    return f(lhs)
  else
    return "cclass<"..lhs:__type()..">: "..lhs:__id()
  end
end

local function op_concat(lhs,rhs)
  local f = getop(lhs, "concat", rhs, true)
  if f then 
    return f(lhs,rhs) 
  end

  f = getop(rhs, "concat", lhs)
  if f then 
    return f(rhs,lhs,true) 
  end
end

local function op_unm(lhs)
  local f = getop(lhs, "unm", nil)
  if f then return f(lhs) end
end

local function op_call(lhs, ...)
  local f = getop(lhs, "call", nil)
  if f then return f(lhs, ...) end
end

local function op_add(lhs,rhs)
  local f = getop(lhs, "add", rhs, true)
  if f then 
    return f(lhs,rhs) 
  end

  f = getop(rhs, "add", lhs)
  if f then 
    return f(rhs,lhs) 
  end
end

local function op_sub(lhs,rhs) -- also deduced as lhs+(-rhs)
  local f = getop(lhs, "sub", rhs, true)
  if f then 
    return f(lhs,rhs)
  end

  f = getop(lhs, "add", rhs)
  if f then
    return f(lhs, -rhs)
  end
end

local function op_mul(lhs,rhs)
  local f = getop(lhs, "mul", rhs, true)
  if f then 
    return f(lhs,rhs) 
  end

  f = getop(rhs, "mul", lhs)
  if f then 
    return f(rhs,lhs) 
  end
end

local function op_div(lhs,rhs)
  local f = getop(lhs, "div", rhs)
  if f then 
    return f(lhs,rhs) 
  end
end

local function op_mod(lhs,rhs)
  local f = getop(lhs, "mod", rhs)
  if f then 
    return f(lhs,rhs) 
  end
end

local function op_pow(lhs,rhs)
  local f = getop(lhs, "pow", rhs)
  if f then 
    return f(lhs,rhs) 
  end
end

local function op_eq(lhs,rhs)
  local f = getop(lhs, "eq", rhs, true)
  if f then 
    return f(lhs,rhs) 
  end
end

local function op_lt(lhs,rhs)
  local f = getop(lhs, "lt", rhs)
  if f then 
    return f(lhs,rhs) 
  end
end

local function op_le(lhs,rhs)
  local f = getop(lhs, "le", rhs)
  if f then 
    return f(lhs,rhs) 
  end
end

-- create C-like FFI class
-- name: name of the class, used to define the cdata type and the functions prefix
-- statics: static functions exposed to the class object, special functions are exposed by default
-- methods: methods exposed to the instances, special methods are overridden
-- ...: inherited bases cclass 
function cclass.new(name, statics, methods, ...)
  local ctype = ffi.typeof(name)
  local pctype = ffi.typeof(name.."*")
  local bases = {...}

  local types = { [name] = true }
  -- cast functions for each base (and parent bases) type
  local casts = { [name] = function(cdata) return cdata end } -- identity cast

  -- build metatype

  local index = {} -- instance index
  local imethods = {} -- class methods index (defined function or direct ffi binding)
  local istatics = {} -- class statics index (defined function or direct ffi binding)

  -- add statics def

  -- auto register new/delete/casts static methods
  statics.new = statics.new or true
  statics.delete = statics.delete or true
  for k,base in pairs(bases) do
    local bmtable = getmetatable(base)
    if bmtable and bmtable.cclass then
      local index = "cast_"..bmtable.name
      statics[index] = statics[index] or true
    end
  end

  for k,v in pairs(statics) do
    -- bind ffi call
    local symbol = name.."_"..k
    local ok = pcall(function() return ffi.cast("void*", C[symbol]) end)
    if ok then -- ffi symbol exists
      local f = C[symbol]
      istatics[k] = f -- add to defindex
      istatics["__c_"..k] = f -- save local ffi binding
    end

    if type(v) ~= "boolean" then -- bind lua function
      istatics[k] = v  -- add to defindex
    end
  end

  -- add special statics
  istatics.name = function() return name end

  -- add methods def

  for k,base in pairs(bases) do
    -- inherit from base
    local bmtable = getmetatable(base) 
    if bmtable and bmtable.cclass then
      -- generate base cast function
      local pctype = bmtable.pctype
      local bname = bmtable.name
      local bcast = istatics["cast_"..bname] -- get defined cast
      if not bcast then -- generate ffi cast
        bcast = function(cdata) return ffi.cast(pctype, cdata) end
      end

      -- add proxied base casts
      for k,v in pairs(bmtable.casts) do
        casts[k] = function(cdata)
          return v(bcast(cdata))
        end
      end
 
      casts[bname] = bcast

      -- methods

      -- copy base defindex
      for k,v in pairs(bmtable.imethods) do
        -- casted function proxy
        local f = function(self, ...)
          return v(bcast(self), ...)
        end

        imethods[k] = f
        index[k] = f -- copy defs
        index["__s_"..k] = f -- save as super
        index["__s_"..bmtable.name.."_"..k] = f -- save as absolute super alias
      end

      -- add base types
      for k,v in pairs(bmtable.types) do
        types[k] = v
      end
    end
  end

  for k,v in pairs(methods) do
    -- bind ffi call
    local symbol = name.."_"..k
    local ok = pcall(function() return ffi.cast("void*", C[symbol]) end)
    if ok then -- ffi symbol exists
      local f = C[symbol]
      imethods[k] = f -- add to defindex
      index[k] = f -- as direct call
      index["__c_"..k] = f -- save local ffi binding
    end

    if type(v) ~= "boolean" then -- bind lua function
      index[k] = v
      imethods[k] = v  -- add to defindex
    end
  end



  -- add special methods

  index.__id = f_id -- __id()

  function index:__type() -- __type()
    return name
  end

  function index:__instanceof(stype) -- __instanceof()
    return types[stype] ~= nil
  end

  function index:__cast(stype) -- __cast()
    local f = casts[stype]
    if f then
      return f(self)
    else
      error("can't up-cast "..self:__type().." to "..stype)
    end
  end

  function index:__get(member) -- __get()
    return index[member]
  end

  -- __data() (return data table per type&instance)
  local data_tables = setmetatable({}, { __mode = "v" })
  local data_refs = setmetatable({}, { __mode = "k" })
  function index:__data()
    -- find ref to data table for this cdata
    local ref = data_refs[self]
    if not ref then
      local id = self:__id()
      -- get data table for this id/address
      local dt = data_tables[id]
      if not dt then
        -- create the data table
        dt = {}
        data_tables[id] = dt
      end

      -- set reference
      ref = dt
      data_refs[self] = ref
    end

    -- return data table
    return ref
  end

  -- setup metatype

  local mtable = {
    __index = index,
    __call = op_call,
    __unm = op_unm,
    __add = op_add,
    __sub = op_sub,
    __mul = op_mul,
    __div = op_div,
    __pow = op_pow,
    __mod = op_mod,
    __eq = op_eq,
    __le = op_le,
    __lt = op_lt,
    __tostring = op_tostring,
    __concat = op_concat
  }

  ffi.metatype(ctype, mtable)

  -- setup class
  
  local instanciate = function(c, ...)
    local new = c.new
    local delete = c.delete
    if new and delete then
      return ffi.gc(new(...), delete)
    else
      error("can't instanciate cclass "..name.." : missing new and/or delete functions")
    end
  end

  return setmetatable({}, { __call = instanciate, __index = istatics, __new_index = function() end, cclass = true, name = name, imethods = imethods, pctype = pctype, casts = casts, types = types })
end

-- SHORTCUTS
setmetatable(cclass, { __call = function(t, ...) 
  return t.new(...)
end})

Luaoop.cclass = cclass
end

return Luaoop
