-- add package path for the example
package.path = package.path..";../src/?.lua;"

-- lib
local Luaoop = require("Luaoop")
class = Luaoop.class

-- DEF OBJECT
Object = class("Object")

function Object:classname()
  return class.name(self)
end

-- DEF BOTTLE

Bottle = class("Bottle", Object)

function Bottle:construct(max)
  self.max = max
  self.amount = 0
end

function Bottle:print()
  print(self.amount.."/"..self.max)
end

function Bottle:fill()
  self.amount = self.max
end

function Bottle:drink()
  if self.amount >= 2 then
    self.amount = self.amount-2
  end
end

-- DEF OPERATORS

class.defop(Bottle, "*number", function(lhs, rhs)
  return lhs.amount*rhs
end)

-- USE

local bottle = Bottle(10)

bottle:print()
bottle:fill()
bottle:print()
bottle:drink()
bottle:print()
bottle:drink()
bottle:print()

if class.instanceof(bottle, "Object") then print("is object") end
if class.instanceof(bottle, "Bottle") then print("is bottle") end
if not class.instanceof(bottle, "Glass") then print("is not glass") end

print(class.type(bottle))
print(bottle*2)
print(2*bottle)
