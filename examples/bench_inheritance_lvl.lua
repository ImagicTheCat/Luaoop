-- benchmark class inheritance levels (build)
-- params: <n>
--- n: max level

-- lib
package.path = ";src/?.lua;"..package.path
local Luaoop = require("Luaoop")
class = Luaoop.class

local n = tonumber(arg[1] or 1000)

print("n:", n)
print()
print("create class levels:", n)

local Base = class("Base")

function Base:__construct()
  print("Base constructor called")
end

local base = Base
for i=1,n do 
  base = class("base", base)
end

local instance = base()
