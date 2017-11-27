-- add package path for the example
package.path = ";../../src/?.lua;"..package.path

-- lib
local ffi = require("ffi")

local Luaoop = require("Luaoop")
cclass = Luaoop.cclass

-- def
ffi.cdef([[
typedef struct{} Animal;
Animal* Animal_new();
void Animal_eat(Animal*);
void Animal_delete(Animal*);

typedef struct{} Cat;
Cat* Cat_new();
void Cat_scratch(Cat*);
void Cat_delete(Cat*);
int Cat___mul_number(Cat*, int);

typedef struct{
  int x;
  int y;
} Vec2;
]])

local libanimal = ffi.load("animal", true)

local Animal = cclass("Animal", {}, { eat = true })
local Cat = cclass("Cat", {}, { scratch = true, __mul_number = true }, Animal)

local ct_Vec2 = ffi.typeof("Vec2")
local Vec2 = cclass("Vec2", {}, {
  __mul_number = function(self, rhs) 
    local v = ct_Vec2()
    v.x = self.x*rhs
    v.y = self.y*rhs

    return v
  end,
  __tostring = function(self)
    return "("..self.x..","..self.y..")"
  end
})

-- test

local cat = Cat()
local an = Animal()

an:eat()
cat:eat()
cat:scratch()

print("an", an:__id(), an:__type())
print("cat", cat:__id(), cat:__type())

-- vec test
local vec = ct_Vec2()
vec.x = 1
vec.y = 2
print("vec", vec*10)

for i=0,1000000 do
  local tcat = Cat()
  local a = tcat*5
end
