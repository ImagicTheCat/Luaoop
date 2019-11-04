-- benchmark operator call
-- params: <n>
--- n: number of iterations

-- lib
package.path = ";src/?.lua;"..package.path
local Luaoop = require("Luaoop")
class = Luaoop.class

local n = tonumber(arg[1]) or 1e8

print("n:", n)
print()

-- DEF

local Value = class("Value")

function Value:__construct(a)
  self.a = a
end

Value.__add["number"] = function(self, rhs)
  return self.a+rhs
end

function Value:__tostring()
  return tostring(self.a)
end

-- DO

print("iterations:", n)

local v = Value(0)

for i=1,n do
  v.a = v+1
end

print("value:", v)
