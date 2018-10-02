local Luaoop = {}

local lua5_1 = (string.find(_VERSION, "5.1") ~= nil)
local unpack = table.unpack or unpack
local _getmetatable = getmetatable
local getmetatable = _getmetatable

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
  local mtable = getmetatable(classdef)
  local luaoop
  if mtable then luaoop = mtable.luaoop end

  if luaoop and not luaoop.type then -- valid class
    if not luaoop.build then
      class.build(classdef)
    end

    local __instantiate = luaoop.__instantiate
    if __instantiate then -- instantiate hook
      return __instantiate(classdef, ...)
    else -- regular
      -- create instance
      local t = setmetatable({}, luaoop.meta) 

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
      end

      -- add self type
      luaoop.types[classdef] = true

      -- postbuild hook
      if luaoop.__postbuild then
        luaoop.__postbuild(classdef, luaoop.build)
      end

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

        -- postmeta hook
        if luaoop.__postmeta then
          luaoop.__postmeta(classdef, luaoop.meta)
        end
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
      if luaoop.__id then -- id hook
        return luaoop.__id(t)
      else -- regular
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
end

-- t: instance
-- return unique instance data table or nil
function class.data(t)
  if t then
    local mtable = getmetatable(t)
    local luaoop
    if mtable then luaoop = mtable.luaoop end
    if luaoop and luaoop.type then
      if luaoop.__data then -- data hook
        return luaoop.__data(t)
      else -- regular
        mtable, luaoop = force_custom_mtable(mtable, t) -- data requires custom properties

        if not luaoop.data then -- create data table
          luaoop.data = {}
        end

        return luaoop.data
      end
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

-- cclass ffi.metatype getmetatable compatibility fix
-- getmetatable is local, defined at the begining of this file
local metatypes = {}
getmetatable = function(t) 
  if type(t) ~= "cdata" then
    return _getmetatable(t)
  else
    return metatypes[tostring(ffi.typeof(t))]
  end
end

-- change the symbols dict for the next following cclass (ffi.C by default)
function cclass.symbols(symbols)
  C = symbols
end

local cintptr_t = ffi.typeof("intptr_t")
local function f_id(t)
  return tonumber(ffi.cast(cintptr_t, t))
end

-- define cclass C function with parameters cast
-- func(C, ...): proxy function, nil for direct C call
--- C: original C function
--- ...: function arguments
-- ...: list of cclass types expected (as class) for function arguments (nil for any type of value)
-- return cclass C function definition structure
function cclass.define(func, ...)
  return {
    luaoop_cclass_def = true,
    f = func,
    types = {...}
  }
end

-- cast instance
-- t: cclass instance
-- c: cast type
-- return casted instance or nil
function cclass.cast(t, c)
  if t then
    local mtable = getmetatable(t)
    local luaoop
    if mtable then luaoop = mtable.luaoop end
    if luaoop and luaoop.type and luaoop.type.__cast then -- t is a cclass instance
      local fcast = luaoop.type.__cast[c]
      if fcast then
        return fcast(t)
      end
    end
  end
end

-- create C-like FFI class
-- name: name of the class, used to define the cdata type and the functions prefix
-- ...: inherited base classes 
-- return created cclass
function cclass.new(name, ...)
  local c = class.new(name, ...)
  if c then
    c.__cast = {} -- cast special table

    local ctype = ffi.typeof(name)
    local pctype = ffi.typeof(name.."*")

    local mtable = getmetatable(c)
    local luaoop = mtable.luaoop
    local luaoop_cclass = {
      ctype = ctype,
      pctype = pctype
    }
    mtable.luaoop_cclass = luaoop_cclass -- mark as cclass

    luaoop.__postbuild = function(c, build)
      -- auto register new/delete/casts special statics
      c.__new = c.__new or cclass.define()
      c.__delete = c.__delete or cclass.define(nil, c)

      for k,base in pairs(luaoop.bases) do -- casts to base cclasses
        local bmtable = getmetatable(base)
        if bmtable and bmtable.luaoop_cclass then
          c.__cast[base] = c.__cast[base] or function(self)
            if class.is(self, base) then
              -- simple cast default
              return ffi.cast(bmtable.luaoop_cclass.pctype, self)
            end
          end
        end
      end

      -- register class functions
      for k,v in pairs(c) do
        if type(v) == "table" and v.luaoop_cclass_def then -- if a cclass C function define
          -- check argument types
          for i,_type in pairs(v.types) do
            local mtable = getmetatable(_type)
            if not mtable or not mtable.luaoop_cclass then
              error("wrong parameter type of cclass C function definition")
            end
          end

          -- bind FFI call
          local symbol = name.."_"..k
          local ok = pcall(function() return ffi.cast("void*", C[symbol]) end)
          if ok then -- FFI symbol exists
            local cf = C[symbol] -- C function
            local f = v.f -- Lua function
            local pf = function(...) -- proxy function
              -- cast arguments
              local args = {...}

              for i,_type in pairs(v.types) do 
                local arg = args[i]
                if class.type(arg) ~= _type then -- not good type, try cast
                  local casted = cclass.cast(arg, _type)
                  if casted then
                    args[i] = casted
                  else
                    local arg_type = class.type(arg)
                    error("can't cast "..(arg_type and tostring(arg_type) or type(arg)).." to "..tostring(_type))
                  end
                end
              end

              -- compute max argument
              local max = 0
              for i in pairs(args) do
                if i > max then max = i end
              end

              -- call
              if f then -- Lua function proxy
                return f(cf, unpack(args, 1, max))
              else -- direct FFI call
                return cf(unpack(args, 1, max))
              end
            end

            c[k] = pf
          else 
            error("can't find FFI symbol "..symbol)
          end
        end
      end
    end

    local data_tables = setmetatable({}, { __mode = "v" })
    local data_refs = setmetatable({}, { __mode = "k" })

    local function f_data(t)
      -- find ref to data table for this cdata
      local ref = data_refs[t]
      if not ref then
        local id = class.id(t)
        -- get data table for this id/address
        local dt = data_tables[id]
        if not dt then
          -- create the data table
          dt = {}
          data_tables[id] = dt
        end

        -- set reference
        ref = dt
        data_refs[t] = ref
      end

      -- return data table
      return ref
    end

    luaoop.__instantiate = function(c, ...)
      local new = c.__new
      local delete = c.__delete
      if new and delete then
        return ffi.gc(new(...), delete)
      else
        error("can't instanciate cclass "..class.name(c).." : missing new and/or delete functions")
      end
    end

    luaoop.__postmeta = function(c, meta)
      meta.luaoop.__id = f_id -- id behavior
      meta.luaoop.__data = f_data -- data behavior (return data table per type&instance)

      -- setup metatype
      ffi.metatype(ctype, meta)
      metatypes[tostring(ctype)] = meta 
      metatypes[tostring(pctype)] = meta 
    end

    return c
  end
end

-- SHORTCUTS
setmetatable(cclass, { __call = function(t, ...) 
  return t.new(...)
end})

Luaoop.cclass = cclass

end

return Luaoop
