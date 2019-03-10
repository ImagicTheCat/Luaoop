-- add package path for the example
package.path = ";../src/?.lua;"..package.path

-- lib
local Luaoop = require("Luaoop")
class = Luaoop.class

-- DEF OBJECT
Object = class("Object")

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

Bottle.__mul["number"] = function(self, rhs)
  return self.amount*rhs
end

Bottle.__mul[Bottle] = function(self, rhs)
  local b = Bottle(self.max*rhs.max)
  b.amount = self.amount*rhs.amount
  return b
end

Bottle.__add[Bottle] = function(self, rhs)
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

Bottle.__eq[Bottle] = function(self, rhs)
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

if class.is(bottle, Object) then print("is object") end
if class.is(bottle, Bottle) then print("is bottle") end
if not class.is(bottle, Glass) then print("is not glass") end

print(class.name(bottle), bottle:classname())
print(class.name(Bottle))
print(class.name(Object))
print(Bottle)
print(Object)

local types = class.types(bottle)

for k,v in pairs(types) do
  print("bottle has type "..class.name(k))
end

print(bottle*2)
print(2*bottle)

print("bottle id: "..class.id(bottle))

-- multiply a bottle by the same bottle
local b = bottle*bottle
print(b)

print("b id: "..class.id(b))

-- sub a bottle by itself (0/0 bottle)
b = bottle-bottle
print(b)

print("b id: "..class.id(b))
