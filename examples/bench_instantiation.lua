-- benchmark instantiation/destruction
-- params: <n> [destructor]
--- n: number of instantiations
--- "destructor": add a destructor if passed

-- lib
package.path = ";src/?.lua;"..package.path
local Luaoop = require("Luaoop")
class = Luaoop.class

local n, destruct = tonumber(arg[1]) or 1e6, arg[2] == "destructor"

local Entity = class("Entity")

function Entity:__construct(id)
  self.id = id
end

if destruct then
  function Entity:__destruct()
  end
end

print("n:", n)
print("destructor:", destruct)
print()
print("instantiate entities:", n)

local ent
for i=1,n do
  ent = Entity(i)
end

print("last ent_id:", ent.id)

print("GC count:", collectgarbage("count"))
