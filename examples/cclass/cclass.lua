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
int Cat_mult(Cat*, int, int);
]])

local libanimal = ffi.load("animal", true)

local Animal = cclass("Animal", {}, { eat = true })
local Cat = cclass("Cat", {}, { scratch = true, mult = true }, Animal)

-- test

local cat = Cat()
local an = Animal()

an:eat()
cat:eat()
cat:scratch()

print("an", an:_id(), an:_type())
print("cat", cat:_id(), cat:_type())

for i=0,1000000 do
  local tcat = Cat()
  tcat:mult(5,5)
end
