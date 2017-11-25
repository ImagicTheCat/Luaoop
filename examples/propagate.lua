-- add package path for the example
package.path = ";../src/?.lua;"..package.path

-- lib
local Luaoop = require("Luaoop")
class = Luaoop.class

local Object = class("Object")

function Object:test()
  print("object")
end

function Object:test2()
  print("object test2")
end

local Rock = class("Rock", Object)

function Rock:test()
  print("rock")
end

-- test

local r = Rock()
r:test() -- "rock"

-- redefine Rock:test()

function Rock:test()
  Object.test(self)
  print("rock new")
end

print("")

r:test() -- still "rock"
class.propagate("Rock")
r:test() -- now "object" and "rock new"

-- redefine Object:test()

function Object:test()
  print("object new")
end
print("")

r:test() -- "object new" and "rock new", no need for propagate (self.Object is a class access)

function Rock:test() -- redefine
  self:test2()
end
print("")

r:test() -- still "object new" and "rock new"
class.propagate("Rock")
r:test() -- now "object test2"

function Object:test2() -- redefine
  print("object test2 new")
end
print("")

r:test() -- still "object test2"
class.propagate("Rock")
r:test() -- now "object test2 new"

