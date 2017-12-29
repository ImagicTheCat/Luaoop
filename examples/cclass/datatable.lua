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

local mAnimal = { eat = true }
local Animal = cclass("Animal", {}, mAnimal)

local mCat = { scratch = true, __mul_number = true }

function mCat:memorize(any)
  local data = self:__data()
  local memory = data.memory
  if not memory then
    memory = {}
    data.memory = memory
  end

  table.insert(memory, any)
end

function mCat:remember()
  local data = self:__data()
  local memory = data.memory
  if memory then
    print("the cat has "..#memory.." memories")
    for k,v in pairs(memory) do
      print(k,v)
    end
  else
    print("the cat has no memory")
  end
end

local Cat = {}
function Cat.delete(self)
  print("delete", self:__type())
  Cat.__c_delete(self)
end
Cat = cclass("Cat", Cat, mCat, Animal)

local cat1 = Cat()
local cat2 = Cat()

cat1:memorize("name cat1")
cat1:memorize("think scratch")
cat1:memorize("think fish")
cat1:memorize("friend with cat2")

cat2:memorize("name cat2")
cat2:memorize("think toy")
cat2:memorize("think outside")
cat2:memorize("friend with cat1")

cat1:remember()
cat2:remember()

local cat2bis = ffi.cast("Cat*", ffi.cast("void*", cat2)) -- clone pointer

-- to be sure that data is removed on garbage collection, do an unsafe operation
-- free memory
cat2 = nil
collectgarbage()
collectgarbage()

cat2bis:remember() -- no memory
