-- example for Lua 5.1 only (setfenv)

-- add package path for the example
package.path = ";../src/?.lua;"..package.path

-- lib
local Luaoop = require("Luaoop")
class = Luaoop.class

-- setup sandbox
local sandbox = {
  -- whitelisting stuff ...
  print = print,
  pairs = pairs
}

sandbox._G = sandbox

-- add class features
sandbox.class = setmetatable({
  new = class.new,
  safeaccess = class.safeaccess,
  -- safedef = class.safedef, -- to access safe class by  name
  name = class.name,
  type = class.type,
  instanceof = class.instanceof,
  instanceid = class.instanceid,
  instanciate = class.instanciate
}, { __call = function(t, ...) return class(...)  end })

-- define some class
Entity = class("Entity")
Entity.a = 10 -- static var
Entity.enum = {
  TEST = 0
}

function Entity:__construct()
  print("new entity")
end

function Entity:speak()
  print("I am an entity.", Entity.a)
end

sandbox.Entity = class.safeaccess(Entity, true) -- bind safe class table with class functionalities

-- ... CODE IN SANDBOX, where the sandbox table is the global context

function main_sandbox()
  print("SANDBOX")
  for k,v in pairs(_G) do
    print(k,v)
  end

  print("\ntry to redefine Entity stuff")
  Entity.a = 42
  Entity.b = 42
  Entity.enum.TEST = 42

  print(Entity.a, Entity.enum.TEST, Entity.b) -- 10, 0, nil
  print(class.name(Entity)) -- Entity

  function Entity:speak()
    print("overridden!", Entity.a)
  end

  print("\ncreate Human, based on safe class Entity")
  local Human = class("Human", Entity)

  -- overload
  function Human:__construct()
    self.Entity.__construct(self)
    print("new human")

    self.Entity.enum = {TEST = 42}
    self.enum.TEST = 42 -- enum inheritance, try to modify
    self.Entity.enum.TEST = 42 
    print("self.enum.TEST still "..self.enum.TEST) -- still 0

    -- try to instantiate an Entity from the inner class reference
    -- print(class.instanciate(self.Entity)) -- nil
    -- print(self.Entity()) -- error
  end

  function Human:speak()
    self.Entity.speak(self)
    print("I am also an human.")
  end

  print("\ninstantiate Entity, test safe access")
  local ent = Entity()
  ent:speak() -- will print "I am an entity. 10" instead of "overridden! 42"
  
  print("\ninstantiate Human")
  local h = Human()
  h:speak()

  if class.instanceof(h, "Entity") then print("h instanceof Entity") end -- will print
  print(class.name(h)) -- Human
end

setfenv(main_sandbox, sandbox)
main_sandbox()
