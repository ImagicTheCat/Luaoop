-- test general usage

-- lib
package.path = ";src/?.lua;"..package.path
local Luaoop = require("Luaoop")
class = Luaoop.class

-- DEF

Object = class("Object")

function Object:__construct()
  print("Object constructor")
end

Bottle = class("Bottle", Object)

function Bottle:__construct(max)
  Object.__construct(self)

  print("Bottle constructor")

  self.max = max
  self.amount = 0
end

function Bottle:fill()
  self.amount = self.max
end

function Bottle:drink()
  if self.amount >= 1 then
    self.amount = self.amount-1
  end
end

Bottle.__mul["number"] = function(self, rhs)
  local b = Bottle(self.max*rhs)
  b.amount = self.amount*rhs
  return b
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

print("create bottle")
local bottle = Bottle(10)
print(bottle)
print("fill bottle")
bottle:fill()
print(bottle)
print("drink bottle")
bottle:drink()
print(bottle)
print("drink bottle")
bottle:drink()
print(bottle)

if class.is(bottle, Object) then print("bottle is Object") end
if class.is(bottle, Bottle) then print("bottle is Bottle") end
if not class.is(bottle, Glass) then print("bottle is not Glass") end

print("Object", Object, class.name(Object))
print("Bottle", Bottle, class.name(Bottle))
print("bottle", bottle, class.name(bottle))

print("bottle types:")
local types = class.types(bottle)

for k,v in pairs(types) do
  print("- "..class.name(k))
end

print("bottle*2", bottle*2)
print("2*bottle", 2*bottle)
print("bottle*bottle", bottle*bottle)
print("bottle-bottle", bottle-bottle)
