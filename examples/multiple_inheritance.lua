-- add package path for the example
package.path = ";../src/?.lua;"..package.path

-- lib
local Luaoop = require("Luaoop")
class = Luaoop.class

-- A
local A = class("A")

function A:__construct()
  print("A constructor")
end

function A:left()
  print("call LEFT")
end

-- B
local B = class("B")

function B:__construct()
  print("B constructor")
end

function B:right()
  print("call RIGHT")
end

-- C
local C = class("C", A, B)

function C:__construct()
  A.__construct(self)
  B.__construct(self)
  print("C constructor")
end

function C:all()
  self:left()
  self:right()
end

-- test

local c = C()
c:all()
