-- Benchmark instantiation.
package.path = "src/?.lua;"..package.path

local class = require("Luaoop").class

local Entity = class("Entity")

--function Entity:__destruct() end

local n = ...; n = tonumber(n) or 1e6
local entities = {}
for i=1, n do
  table.insert(entities, Entity())
end
