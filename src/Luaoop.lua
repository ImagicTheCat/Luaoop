local Luaoop = {}

-- CLASS MODULE

local class = {}

-- __index used for multiple inheritance
local function propagate_index(t,k)
  local bases = getmetatable(t).bases
  -- find key in table properties
  for l,v in pairs(bases) do
    local p = v[k]
    if p ~= nil then 
      if type(p) == "table" or type(p) == "function" then
        t[k] = p -- direct access optimization after first access, if table
      end
      return p
    end
  end
end

-- create a new class with the passed identifier and base classes (multiple inheritance possible)
-- return class or nil if name/base classes are invalid
function class.new(name, ...)
  if type(name) == "string" then
    local c = {}
    local bases = {...}

    -- check inheritance validity
    for k,v in pairs(bases) do
      if class.name(v) == nil then
        return nil
      end
    end

    if #bases > 1 then -- multiple inheritance
      setmetatable(c,{ __index = propagate_index, bases = bases })
      return class.new(name, c)
    else -- single inheritance
      setmetatable(c, { __index = bases[1], classname = name, private = {}, __call = function(t, ...) return class.instanciate(c, ...) end})
      return c
    end
  end
end

-- get private space table of the instantiated object
function class.getprivate(o)
  local mtable = getmetatable(o)
  if mtable then return mtable.private else return nil end
end

-- return classname or nil if not a class or instance of class
function class.name(t)
  local cname = nil

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

-- contains operators definitions
local ops = {}

local function get_op(idname, no_error)
  local f = ops[idname]
  if f then
    return f
  elseif not no_error then
    error("operator "..idname.." undefined.")
  end
end

-- proxy lua operators
local function op_unm(lhs)
  local f = get_op(class.type(lhs).."-")
  if f then return f(lhs) end
end

local function op_add(lhs,rhs)
  local f = get_op(class.type(lhs).."+"..class.type(rhs), true)
  if f then 
    return f(lhs,rhs) 
  end

  f = get_op(class.type(rhs).."+"..class.type(lhs))
  if f then 
    return f(rhs,lhs) 
  end
end

local function op_sub(lhs,rhs) -- defined as lhs+(-rhs)
  local f = get_op(class.type(lhs).."+"..class.type(rhs))
  if f then 
    return f(lhs,-rhs)
  end
end

local function op_mul(lhs,rhs)
  local f = get_op(class.type(lhs).."*"..class.type(rhs), true)
  if f then 
    return f(lhs,rhs) 
  end

  f = get_op(class.type(rhs).."*"..class.type(lhs))
  if f then 
    return f(rhs,lhs) 
  end
end

local function op_div(lhs,rhs)
  local f = get_op(class.type(lhs).."/"..class.type(rhs))
  if f then 
    return f(lhs,rhs) 
  end
end

-- define an operator
-- ex: defineOp(Vec,"*type",f)
-- ex: defineOp(Vec,"/type",f)
-- ex: defineOp(Vec,"+type",f)
-- ex: defineOp(Vec,"-",f)
-- a-b is handled as a+(-b)
function class.defop(_class,op_type,f)
  ops[class.name(_class)..op_type] = f
end

-- define global operator (full notation)
function class.defgop(full_op_type,f)
  ops[full_op_type] = f
end

-- build lua metamethods to read defined operators
local function buildOps(instance)
  local mtable = getmetatable(instance)
  if mtable then
    mtable.__unm = op_unm
    mtable.__add = op_add
    mtable.__sub = op_sub
    mtable.__mul = op_mul
    mtable.__div = op_div
  end
end

-- create object with a specific class and constructor arguments 
function class.instanciate(class, ...)
  local o = {}

  -- build instance
  local mtable = {__index = class, private = {}}
  setmetatable(o,mtable)

  -- build operators metamethods
  buildOps(o)

  -- construct
  if o.construct then o:construct(...) end
  return o
end

-- SHORTCUTS
setmetatable(class, { __call = function(t, name, ...) 
  return class.new(name, ...)
end})

-- NAMESPACES
Luaoop.class = class

return Luaoop