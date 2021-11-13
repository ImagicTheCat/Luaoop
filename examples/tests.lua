package.path = "src/?.lua;"..package.path
local xtype = require("xtype")
local class = require("Luaoop").class

local function errcheck(perr, f, ...)
  local ok, err = pcall(f, ...)
  assert(not ok and not not err:find(perr))
end

local function countPairs(t)
  local count = 0
  for _ in pairs(t) do count = count+1 end
  return count
end

do -- test class/instance basics
  local A = class("A")
  local a = A()
  assert(xtype.is(A, class) and xtype.is(A, "xtype"))
  assert(xtype.is(a, A))
  assert((tostring(A):find("class<A>")))
  assert((tostring(a):find("instance<A>")))
end
do -- test constructor/destructor/GC
  local A = class("A")
  local record = {}
  function A:__construct(i) self.i = i; record[i] = true end
  function A:__destruct() record[self.i] = nil end
  local as = {}
  for i=1,3 do as[i] = A(i) end
  assert(countPairs(record) == 3)
  -- GC
  as = nil
  for i=1,2 do collectgarbage("collect") end
  assert(countPairs(record) == 0)
end
do -- test special methods: unary operator binding
  local A = class("A")
  function A:__construct(i) self.i = i end
  function A:__call(a,b) return self.i+a+b end
  function A:__tostring() return "A"..self.i end
  local a = A(5)
  assert(a(1,2) == 8)
  assert(tostring(a) == "A5")
end
do -- test multifunction / binary operator
  local vec2 = class("vec2")
  function vec2:__construct(x, y) self.x, self.y = x, y end
  xtype.op.add:define(function(a, b) return vec2(a.x+b.x, a.y+b.y) end, vec2, vec2)
  xtype.op.eq:define(function(a, b) return a.x == b.x and a.y == b.y end, vec2, vec2)
  assert(vec2(1,0) ~= vec2(0,1))
  assert(vec2(1,0)+vec2(0,1) == vec2(1,1))
end
do -- test inheritance
  -- define
  local A = class("A"); function A:test() return "A" end
  local B = class("B"); function B:test() return "B" end
  local C = class("C", A, B);
  local D = class("D", B, A);
  local E = class("E", A, B); function E:test() return "E" end
  function E:__construct() end
  -- test
  assert(C.test) -- check partial build: class inheritance
  local e = E()
  assert(xtype.of(E, A) and xtype.of(E, B))
  assert(xtype.is(e, A) and xtype.is(e, B))
  assert(E.xtype_name and E.luaoop and not e.xtype_name and not e.luaoop)
  assert(E.__construct and not e.__construct)
  assert(C():test() == "A"); assert(D():test() == "B")
  assert(e:test() == "E")
end
do -- test class re-build
  local A = class("A"); function A:A() return "A" end
  local B = class("B"); function B:B() return "B" end
  local C = class("C", A, B); function C:C() return self:A()..self:B() end
  local c = C()
  assert(c:C() == "AB")
  function A:A() return "A'" end
  function B:B() return "B'" end
  class.build(A); class.build(B); class.build(C)
  assert(c:C() == "A'B'")
end
do -- test class meta (rudimentary)
  local A = class("A")
  local a = setmetatable({}, class.meta(A))
  assert(xtype.is(a, A))
end
do -- test errors
  errcheck("class expected", class.build)
end
