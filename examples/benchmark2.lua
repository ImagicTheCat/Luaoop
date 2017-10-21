-- add package path for the example
package.path = package.path..";../src/?.lua;"

-- lib
local Luaoop = require("Luaoop")
class = Luaoop.class

function test(n)
  print("Test "..n.." inheritance levels")

  local base = nil
  for i=1,n do 
    base = class(n.."Class"..i, base)
    local prev = n.."Class"..(i-1)

    function base:f()
      local v = 1
      local namespace = self[prev]
      if namespace then
        v = namespace.f(self)+1
      end

      return v
    end
  end

  local ins = base()
  local time = os.clock()
  local v = ins:f()
  print("f => "..v.." ("..(os.clock()-time).." s)")
end


local time = os.clock()
local n = 10
while true do
  test(n)
  n = n+10
end
