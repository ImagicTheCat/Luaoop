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
]])

local libanimal = ffi.load("animal", true)

local Animal = cclass("Animal", {}, { eat = true })
local Cat = cclass("Cat", {}, { scratch = true, __mul_number = true }, Animal)

-- test

local cat = Cat()
local an = Animal()

an:eat()
cat:eat()
cat:scratch()

print("an", an:__id(), an:__type())
print("cat", cat:__id(), cat:__type())

print(cat:__instanceof("Cat"), cat:__instanceof(Cat.name()), cat:__instanceof("Animal"), cat:__instanceof("Object"))
print(cat:__cast("Animal"):eat())

for i=0,1000000 do
  local tcat = Cat()
  local a = tcat*5
end
