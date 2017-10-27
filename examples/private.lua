-- add package path for the example
package.path = ";../src/?.lua;"..package.path

-- lib
local Luaoop = require("Luaoop")
class = Luaoop.class

-- def

A = class("A")

function A:__construct(name)
  local private = A^self
  private.name = name or "anonymous"

  print("A ("..name..") constructor")
end

function A:__destruct()
  local name = (A^self).name
  print("A ("..name..") destructor")
end

local safe_A = class.safeaccess(A, true)
B = class("B", safe_A)

function B:__construct(name)
  self.A.__construct(self, name)

  print((B^self).name) -- nil, A private is not B private
  -- local private = safe_A^self -- error, only original class can access private
end

-- test

local b = B("test")

print(A^B) -- nil, class can't have private tables
