local Luaoop = {}

local lua5_1 = (string.find(_VERSION, "5.1") ~= nil)

-- CLASS MODULE

local class = {}

local classes = {}

-- __index used for multiple inheritance
local function propagate_index(t,k)
  local bases = getmetatable(t).bases
  -- find key in table properties
  for l,v in pairs(bases) do
    local p = v[k]
    if p then return p end

    --[[ -- optimization (lose flexibility)
    local p = v[k]
    if p ~= nil then 
      if type(p) == "table" or type(p) == "function" then
        t[k] = p -- direct access optimization after first access, if table
      end
      return p
    end
    --]]
  end
end 

-- force an instance to have a custom mtable (by default they share the same table for optimization)
-- mtable: current instance mtable
-- o: instance
-- return custom mtable
local function force_custom_mtable(mtable, o)
  if not mtable.custom then
    -- copy mtable
    local new_mtable = {}
    for k,v in pairs(mtable) do
      new_mtable[k] = v
    end

    -- flag custom
    new_mtable.custom = true
    setmetatable(o, new_mtable)

    mtable = new_mtable
  end

  return mtable
end

-- private access name optimization
local private_dict = {}

-- return private context or nil
local function class_pow_instance(c, o)
  local cmtable = getmetatable(c)

  if o then
    local omtable = getmetatable(o)
    if omtable and omtable.instance then
      omtable = force_custom_mtable(omtable, o) -- private access requires custom properties

      -- get/gen key
      local key = private_dict[cmtable.classname]
      if not key then
        key = cmtable.classname.."_p"
        private_dict[cmtable.classname] = key
      end

      local private = omtable[key]
      if not private then
        private = {}
        omtable[key] = private
      end

      return private
    end
  end
end

-- create a new class with the passed identifier (following the Lua name notation, no special chars except underscore) and base classes (multiple inheritance possible)
-- return class or nil if name/base classes are invalid
function class.new(name, ...)
  if type(name) == "string" and string.len(name) > 0 then
    local c = {}
    local bases = {...}

    -- replace safe access
    for k,v in pairs(bases) do
      local c, mt = class.unsafe(v)
      if c and mt.class then -- is safe access with class functionalities
        bases[k] = c 
      end
    end

    -- check inheritance validity and generate safe access
    for k,v in pairs(bases) do
      local mtable = getmetatable(v)

      if not mtable or (not mtable.classname and not mtable.bases) then -- if not a class
        return nil
      else -- generate safe access for bases direct tables in this class ("hide" parent tables)
        for l,w in pairs(v) do
          if type(w) == "table" and not class.unsafe(w) then -- if not already a safeaccess
            c[l] = class.safeaccess(w)
          end
        end
      end
    end

    if #bases > 1 then -- multiple inheritance, proxy
      setmetatable(c,{ __index = propagate_index, bases = bases })
      return class.new(name, c) -- then single inheritance of the proxy
    else -- single inheritance
      setmetatable(c, { __index = bases[1], class = true, classname = name, __call = class.instanciate, __pow = class_pow_instance})

      -- add class methods access in classname namespace -> instance.Class.method(instance, ...)
      c[name] = class.safeaccess(c)

      if not classes[name] then
        classes[name] = c -- reference class
      else
        error("redefinition of class "..name)
      end

      return c
    end
  end
end

-- return the class definition for the specified class name (nil if not found)
-- it is a raw access, any method can be modified/added/removed
function class.definition(name)
  return classes[name]
end

-- same as class.definition but returning a safe access class
function class.safedef(name)
  return class.safeaccess(class.definition(name), true)
end

-- return a new table giving access to the passed table properties (prevents adding/removing/modifying properties)
-- (deep, recursive safe access on subtables)
-- useful to protect global class data from modifications (only if getmetatable is not allowed)
-- works also to get a safe class definition for inheritance and instantiation
--
-- fclass: if passed/true, will preserve class table functionalities
function class.safeaccess(t, fclass)
  if t then
    local mtable = getmetatable(t) or {}
    local _t = {}

    local mt = {
      safe_access = t, -- define special property to recognize safe access, save original table
      __index = function(_t, k)
        local v = t[k]
        if type(v) == "table" then -- create subtable safe access
          v = class.safeaccess(v, fclass)
          rawset(_t,k,v) -- save access
        end
        
        return v -- return regular value
      end
      , __newindex = function(t,k,v) end -- prevents methods obfuscation with newindex
    }

    -- flags
    if fclass then 
      mt.__call = mtable.__call 
      mt.class = true
    end

    return setmetatable(_t, mt)
  end
end

-- return the original table from a safe access table, or nil if not a safe access
-- return also the safe access metatable as second return values
function class.unsafe(safe_access)
  local mtable = getmetatable(safe_access)
  if mtable and mtable.safe_access then
    return mtable.safe_access, mtable
  end
end

-- return classname or nil if not a class or instance of class
function class.name(t)
  local cname = nil

  local c, mt = class.unsafe(t)
  if c and mt.class then t = c end -- is safe access with class functionalities, replace with class

  if t ~= nil then
    local mtable = getmetatable(t)
    if mtable ~= nil then
      -- optimization
      if mtable.classname ~= nil then return mtable.classname end

      -- first unoptimized call
      local class = mtable.__index
      if class ~= nil then
        local submtable = getmetatable(class)
        if submtable ~= nil then
          local name = submtable.classname 
          if name ~= nil then cname = name end
        end
      end

      -- set optimization
      mtable.classname = cname
    end
  end

  return cname
end

-- return the defined classname or the lua type for an instance or class
function class.type(t)
  local name = class.name(t)
  if name == nil then
    name = type(t)
  end

  return name
end

-- used by instanceof
local function fill_classlist(classlist, mtable)
  while mtable ~= nil do
    if mtable.classname ~= nil then
      classlist[mtable.classname] = true
    end

    mtable = getmetatable(mtable.__index)
    if mtable ~= nil and mtable.bases ~= nil then
      for k,v in pairs(mtable.bases) do -- recursively explore multiple heritances
        fill_classlist(classlist,getmetatable(v))
      end
    end
  end
end

-- check if the instance is derivated from a specific classname
function class.instanceof(o, name)
  if o ~= nil then
    local mtable = getmetatable(o)
    if mtable ~= nil then
      -- optimization
      local classlist = mtable.classlist
      if classlist ~= nil then return classlist[name] ~= nil end

      -- first unoptimized call, build list
      mtable.classlist = {}
      classlist = mtable.classlist

      -- add all class names to the list
      fill_classlist(classlist,mtable)

      -- check from list
      return classlist[name] ~= nil
    end
  end

  return false
end

-- optimize special method name resolution
local op_dict = {}

-- get operator from instance/class, rhs_class can be nil for unary operators
function class.getop(lhs_class, name, rhs_class, no_error)
  local f = nil

  local mtable = getmetatable(lhs_class)
  if mtable and (mtable.instance or mtable.classname) then -- check if class or instance
    local rtype = class.type(rhs_class)

    -- optimization using op_dict
    local dict = op_dict[name]
    if not dict then
      dict = {}
      op_dict[name] = dict
    end

    -- method name
    local fname = dict[rtype]
    if not fname then -- generate fname
      if rhs_class then
        fname = "__"..name.."_"..rtype
      else
        fname = "__"..name
      end

      dict[rtype] = fname
    end

    f = lhs_class[fname]
  end

  if f then
    return f
  elseif not no_error then
    error("operator <"..class.type(lhs_class).."> ["..name.."] <"..class.type(rhs_class).."> undefined")
  end
end

local getop = class.getop

-- proxy lua operators
local function op_tostring(lhs)
  local f = getop(lhs, "tostring", nil)
  if f then return f(lhs) end
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

-- optimize instanciation for basic instances (no custom mtable properties)
local insmt_dict = {}

-- create object with a specific class and constructor arguments 
function class.instanciate(_class, ...)
  local c, mt = class.unsafe(_class)
  if c and mt.class then _class = c end -- is safe access with class functionalities, replace with class

  local cmtable = getmetatable(_class)

  if cmtable.class and cmtable.classname then -- if a class
    local o = {}

    -- generate safe access for _class direct tables in this instance ("hide" inherited tables)
    for k,v in pairs(_class) do
      if type(v) == "table" and not class.unsafe(v) then -- if not already a safeaccess
        o[k] = class.safeaccess(v)
      end
    end

    local mtable = insmt_dict[cmtable.classname]
    if not mtable then
      -- build instance
      mtable = {
        __index = _class, 
        instance = true,

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

      insmt_dict[cmtable.classname] = mtable
    end

    setmetatable(o,mtable)

    local constructor = o.__construct
    local destructor = o.__destruct

    if destructor then
      mtable = force_custom_mtable(mtable, o) -- gc requires custom properties

      local gc = function()
        destructor(o)
      end

      if lua5_1 then -- Lua 5.1
        local proxy = newproxy(true)
        getmetatable(proxy).__gc = gc
        mtable.proxy = proxy
      else
        mtable.proxy = setmetatable({}, { __gc = gc })
      end
    end

    -- construct
    if constructor then constructor(o, ...) end
    return o
  end
end

-- return address number from table (tostring hack, return nil on failure)
local function table_addr(t)
  local hex = string.match(tostring(t), ".*(0x%x+).*")
  if hex then return tonumber(hex) end
end

local addr_counter = 0 -- addr counter in replacement of table_addr

-- return unique instance id (or nil if not an instance)
-- works by using tostring(table) address hack or using a counter instead on failure
function class.instanceid(o)
  if o then
    local mtable = getmetatable(o)
    mtable = force_custom_mtable(mtable, o) -- instanceid requires custom properties

    if mtable.id then -- return existing id
      return mtable.id
    elseif mtable.instance then  -- generate id
      -- remove tostring proxy
      mtable.__tostring = nil
      -- generate addr
      mtable.id = table_addr(o)
      -- reset tostring proxy
      mtable.__tostring = op_tostring

      if not mtable.id then
        mtable.id = addr_counter
        addr_counter = addr_counter+1
      end

      return mtable.id
    end
  end
end

-- SHORTCUTS
setmetatable(class, { __call = function(t, name, ...) 
  return class.new(name, ...)
end})

-- NAMESPACES
Luaoop.class = class

return Luaoop
