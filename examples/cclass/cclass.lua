-- add package path for the example
package.path = ";../../src/?.lua;"..package.path

-- lib
local ffi = require("ffi")

local Luaoop = require("Luaoop")
class = Luaoop.class
cclass = Luaoop.cclass

-- def
ffi.cdef([[
typedef struct{} Animal;
Animal* Animal___new();
void Animal_eat(Animal*);
void Animal___delete(Animal*);

typedef struct{} Cat;
Cat* Cat___new();
void Cat_scratch(Cat*);
void Cat___delete(Cat*);
]])

local libanimal = ffi.load("animal", true)

local Animal = cclass("Animal")
Animal.eat = cclass.define(nil, Animal)

local Cat = cclass("Cat", Animal)
Cat.scratch = cclass.define(nil, Cat)
Cat.__mul.number = function(self, n)
  return 42*n
end

-- test

local cat = Cat()
local an = Animal()

an:eat()
cat:eat()
cat:scratch()

print("an", class.id(an), class.type(an))
print("cat", class.id(cat), class.type(cat))

print(class.is(cat, Cat), class.is(cat, Animal))
print(class.type(cclass.cast(cat, Animal)))

local a
for i=0,1000000 do
  local tcat = Cat()
  a = tcat*5
end

print(a)

if not cclass.cast(an, Cat) then print("can't cast animal to cat") end
