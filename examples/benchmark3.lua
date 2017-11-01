
-- add package path for the example
package.path = ";../src/?.lua;"..package.path

-- lib
local Luaoop = require("Luaoop")
class = Luaoop.class

local Object = class("Object")

function Object:__pow_number(n)
  return n
end

print("benchmark operator resolution")

local o = Object()
print(o^42)

local time = os.clock()
for i=1,20000000 do
  local r = o^i
end

print("time = "..(os.clock()-time).." s")

print("\nbenchmark private access")

time = os.clock()
for i=1,20000000 do
  local private = Object^o
end

print("time = "..(os.clock()-time).." s")
