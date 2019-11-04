-- lib
package.path = ";src/?.lua;"..package.path
local Luaoop = require("Luaoop")
class = Luaoop.class

-- def

local A = class("A")

function A:__construct(id)
  self.id = id
  print("A("..self.id..") constructor")
end

function A:__destruct()
  print("A("..self.id..") destructor")
end

-- test

for i=1,10 do
  local a = A(i)
end
