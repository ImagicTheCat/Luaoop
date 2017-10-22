-- add package path for the example
package.path = ";../src/?.lua;"..package.path

-- lib
local Luaoop = require("Luaoop")
class = Luaoop.class

-- Vec3 class

Vec3 = class("Vec3")

function Vec3:__construct(x,y,z)
  if class.instanceof(x) == "Vec3" then
    self.x = x.x
    self.y = x.y
    self.z = x.z
  else
    self.x = x or 0
    self.y = y or 0
    self.z = z or 0
  end
end

function Vec3:__add_Vec3(rhs)
  return Vec3(self.x+rhs.x, self.y+rhs.y, self.z+rhs.z)
end

function Vec3:__mul_number(rhs)
  return Vec3(self.x*rhs, self.y*rhs, self.z*rhs)
end

function Vec3:__unm()
  return Vec3(-self.x, -self.y, -self.z)
end

function Vec3:__tostring()
  return "("..self.x..","..self.y..","..self.z..")"
end

function Vec3:__concat_string(rhs, inverse)
  if inverse then
    return rhs..self:__tostring()
  else
    return self:__tostring()..rhs
  end
end

-- Entity class

Entity = class("Entity")

function Entity:__construct(name)
  self.name = name
  self.pos = Vec3()

  local angle = math.random()*math.pi*2
  self.vel = Vec3(math.cos(angle), math.sin(angle), 0)*2
end

function Entity:frame(time)
  self.pos = self.pos+self.vel*time
end

function Entity:__tostring()
  return "E("..self.name..") = "..self.pos
end

-- Simulation class

Simulation = class("Simulation")

function Simulation:__construct(n)
  print("\ncreate simulation with "..n.." entities")
  self.entities = {}

  for i=1,n do
    table.insert(self.entities, Entity("ent"..i))
  end
end

function Simulation:frame(time, no_display)
  if not no_display then
    print("--")
    print("do simulation step ("..time.." s)")
  end

  for i=1,#self.entities do
    local v = self.entities[i]
    v:frame(time)
    if not no_display then
      print(v)
    end
  end
end

-- Clock class

Clock = class("Clock")

function Clock:__construct()
  self.clock = 0
end

function Clock:start()
  self.clock = os.clock()
end

function Clock:stop()
  print("time = "..(os.clock()-self.clock).." s")
end

clock = Clock()

-- test

local sim = Simulation(10)
sim:frame(1)


clock:start()
local bigsim = Simulation(1000)
clock:stop()

clock:start()
print("\ndo 1000 ticks")
for i=1,1000 do
  bigsim:frame(1, true)
end
clock:stop()

print("\ncompute 100000 vectors")

local vec = Vec3(0.5454,0.2554,0.784)
clock:start()
for i=1,100000 do
  local vec = vec+vec*0.42
end
clock:stop()

clock:start()
local verybigsim = Simulation(100000)
clock:stop()


