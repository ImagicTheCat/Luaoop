-- add package path for the example
package.path = ";../src/?.lua;"..package.path

-- lib
local Luaoop = require("Luaoop")
class = Luaoop.class

-- DEF OBJECT
Object = class("Object")

Object.color = {
  BLACK = 0,
  BLUE = 1,
  YELLOW = 2,
  RED = 3,
  GREEN = 4,
  WHITE = 5
}

function Object:__construct()
  print("new object")
end

function Object:classname()
  return class.name(self)
end

-- DEF BOTTLE

Bottle = class("Bottle", Object)

function Bottle:__construct(max)
  Object.__construct(self)

  self.max = max
  self.amount = 0
end

function Bottle:fill()
  self.amount = self.max
end

function Bottle:drink()
  if self.amount >= 2 then
    self.amount = self.amount-2
  end
end

function Bottle:__mul_number(rhs)
  return self.amount*rhs
end

function Bottle:__mul_Bottle(rhs)
  local b = Bottle(self.max*rhs.max)
  b.amount = self.amount*rhs.amount
  return b
end

function Bottle:__add_Bottle(rhs)
  local b = Bottle(self.max+rhs.max)
  b.amount = self.amount+rhs.amount
  return b
end

function Bottle:__unm()
  local b = Bottle(-self.max)
  b.amount = -self.amount
  return b
end

function Bottle:__tostring()
  return self.amount.."/"..self.max
end

function Bottle:__eq_Bottle(rhs)
  return self.amount == rhs.amount
end

-- USE

local bottle = Bottle(10)

print(bottle)
bottle:fill()
print(bottle)
bottle:drink()
print(bottle)
bottle:drink()
print(bottle)

if class.instanceof(bottle, "Object") then print("is object") end
if class.instanceof(bottle, "Bottle") then print("is bottle") end
if not class.instanceof(bottle, "Glass") then print("is not glass") end

print(class.type(bottle))
print(class.type(Bottle))
print(class.type(Object))

local types = class.types(bottle)

for k,v in pairs(types) do
  print("bottle has type "..k)
end

print(bottle*2)
print(2*bottle)

print("bottle id: "..class.instanceid(bottle))

-- multiply a bottle by the same bottle
local b = bottle*bottle
print(b)

print("b id: "..class.instanceid(b))

-- sub a bottle by itself (0/0 bottle)
b = bottle-bottle
print(b)

print("b id: "..class.instanceid(b))

-- get bottle definition
local cbottle = class.definition("Bottle")
print(cbottle(42)) -- create a bottle
