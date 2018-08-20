Luaoop is a small library to do OOP.
The library aim interesting features like the C++ OOP with additional reflexive tools.

Look at the examples for more understanding of the library.

# Luaoop

## Install

Instead of adding the file manually, you can use luarocks:

`luarocks install https://raw.githubusercontent.com/ImagicTheCat/Luaoop/master/rockspecs/luaoop-scm-1.rockspec`

Replace the rockspec with the one you want.

## Version

It is designed to work with luajit (Lua 5.1), but the code should work on latest versions.

## API

```lua
-- create a new class with the passed identifier (following the Lua name notation, no special chars except underscore) and base classes (multiple inheritance possible)
-- return class or nil if name/base classes are invalid
class.new(name, ...)
-- SHORTCUT class(name, ...)

-- return the class definition for the specified class name (nil if not found)
-- it is a raw access, any method can be modified/added/removed
class.definition(name)

-- same as class.definition but returning a safe access class
class.safedef(name)

-- return a new table giving access to the passed table properties (prevents adding/removing/modifying properties)
-- (deep, recursive safe access on subtables)
-- useful to protect global class data from modifications (only if getmetatable is not allowed)
-- works also to get a safe class definition for inheritance and instantiation
--
-- fclass: if passed/true, will preserve class table functionalities (instantiation, type, etc)
class.safeaccess(t, fclass)

-- return the original table from a safe access table, or nil if not a safe access
-- return also the safe access metatable (second rvalue)
class.unsafe(safe_access)

-- return classname or nil if not a class or instance of class
class.name(t)

-- return the defined classname or the lua type for an instance or class
class.type(t)

-- check if an instance/class is/inherits from a specific classname
class.is(t, name)

-- alias for class.is()
class.instanceof(t, name)

-- return instance/class types map (type => true)
class.types(t)

-- return unique instance id (or nil if not an instance)
-- works by using tostring(table) address hack or using a counter instead on failure
class.instanceid(o)

-- get the class metatable applied to the instances
-- useful to apply class behaviour to a custom table
-- (not a safe access)
class.meta(class)

-- create object with a specific class and constructor arguments 
class.instanciate(class, ...)
-- SHORTCUT Class(...)

-- propagate changes for the specified string instance types
-- this function is not about class propagation (since class properties are not cached), but instance type propagation
-- you need to call it for every instantiated types that should inherit the new modifications
-- ...: list of types (strings) that will be updated
class.propagate(...)

-- (internal) get operator from instance/class, rhs_class can be nil for unary operators
class.getop(lhs_class, name, rhs_class, no_error)
```

## Inheritance

Single and multiple inheritances are possibles, only direct functions will be overridden by each new definition of the child class.
In case of multiple inheritance with functions with the same name, one will be taken arbitrarily. You can solve this issue by accessing directly to a specific parent method/function using the class definition.

Class inheritance is resolved dynamically, it means that the access to a Class function (through a safe access or in a child class) is not cached, so changes will be directly applied.

Instead, instance functions are cached for each instance type when accessed the first time, this means that modifications of parent methods will require a `class.propagate` for any instantiated type that should be affected by the changes. `class.propagate` is not about Class functions propagation, but instantiated type functions propagation, it will trigger an error when used for uninstantiated types.

*NOTE: When accessing a nil property, it will search in the entire class tree. For undefined checked properties like callbacks, initialize the property to false to prevent the overhead.*

```lua
A = class("A")
function A:test()
  print("a")
end

B = class("B")
function B:test()
  print("b")
end

C = class("C", A, B) -- inheritance from A and B
function C:test() -- force the usage of B:test()
  B.test(self)
end

```

## Super methods

You can access any parent class method using the class/safeclass directly.

Example:
```lua
A = class("A")

function A:__construct()
  print("a")
end

B = class("B", A)
function B:__construct()
  A.__construct(self) -- call parent (A) constructor
  print("b")
end
```

If you seek performance over flexibility, you can call super methods like this:

```lua
B = class("B", A)

local s__construct = B.__construct -- cache inherited before overload
function B:__construct()
  s__construct(self)
  print("b")
end
```
Since the method is cached, later modification of the A constructor will not be applied to B.

## Special methods

You can define special methods for a class, they will be overridden the same way other methods are.
Every special method start with `__` (they are not metamethods, they are named like this to keep consistency with the Lua notation).

### Misc

* `construct`: called at initialization
* `destruct`: called at garbage collection

### Operators (or things similar)

Operators are defined like this:
```lua
Object:__op() -- unary
Object:__op_rhstype(rhs) -- binary
```

Unary
* `call`: like the metamethod
* `tostring`: like the metamethod
* `unm`: like the metamethod

Binary
* `concat`: like the metamethod (no order, but has a second parameter "inverse" when the concat is not forward)
* `add`: like the metamethod (no order)
* `sub`: like the metamethod (can be omitted if `add` is defined and `unm` is defined for rhs)
* `mul`: like the metamethod (no order)
* `div`: like the metamethod
* `mod`: like the metamethod 
* `pow`: like the metamethod
* `eq`: like the metamethod (doesn't throw an error if the operator is missing, will be false by default)
* `le`: like the metamethod
* `lt`: like the metamethod

Be careful with `eq`, `le`, `lt`, they will be called like any binary operator, following the type of rhs and they will not be called if the comparison is not between two Luaoop instances.

Comparison of different instances with different types is possible, but this may change in the future.

## Private members

Private methods can be achieved with local functions in the class definition, but "private members" are instance dependents.

Each instance can have a private table per class definition (the instance is not required to be an instance of the class).
To access this private table, the `Class^instance` operator is used. This operator only works with original definitions (not with a safe access class).

```lua
A = class("A")
safe_A = class.safeaccess(A, true)

function A:__construct()
  local private = A^self
  private.a = 42;
end

B = class("B", A)

function B:__construct()
  A.__construct(self)

  -- to access the A private table, direct access to A definition is required
  local private_A = A^self -- private table
  -- local private_A = safe_A^self -- error
end
```

Good practice is to cache the private table when doing multiple operations in the same call to prevent overhead. 
The goal of private tables is to prevent access to critical members. It may be used to prevent collisions of instance properties, but a prefix is more natural for "public/protected" members.

## "Security / Sandbox"

Luaoop doesn't aim to "sandbox" things, but if you want to add private properties to the object instances (for example, to keep a luajit FFI pointer away from users), create a base class and use the class private operator to access the private instance table, then never give the original class definition to users.
Instantiated objects are safe to handle, users can't touch the class definitions from the instance if they don't have access to the original class table (for example, an enumeration in a class should not be modified from the instance or any child class).

With some tweaks, you can allow scripts to create classes based on other classes, without allowing them to mess with the previous definitions.

Here are a non-exhaustive list of functions you should remove from the sandbox for safe class sharing and/or app private storage for instances:
* `getmetatable`
* `setmetatable`
* `rawset`
* `rawget`
* `class.unsafe`
* `class.definition`
* `class.meta`

Which let:
* `class.new`
* `class.safeaccess`
* `class.safedef`: only if you want all the class definitions to be accessibles
* `class.name`
* `class.type`
* `class.is` `class.instanceof`
* `class.types`
* `class.instanceid`
* `class.instanciate`
* `class.propagate`

See `sandbox.lua` example for usage.

## CClass (LuaJIT)

Luaoop also have a `cclass` module to create "C-like FFI interface class", taking advange of the FFI metatype of LuaJIT.

This is a completely different module and none of the functions of `class` are related to `cclass`. 

It is following the Luaoop style.

### API

```lua
-- change the symbols dict for the following created cclass (ffi.C by default)
cclass.symbols(symbols)

-- create C-like FFI class
-- name: name of the class, used to define the cdata type and the functions prefix
-- statics: static functions exposed to the class object, special functions are exposed by default
-- methods: methods exposed to the instances, special methods are overridden
-- ...: inherited bases cclass 
cclass.new(name, statics, methods, ...)
-- SHORTCUT cclass(...)
```

#### Used statics

* `new`: should return a new heap instance of the cclass
* `delete`: should free the instance pointer
* `cast_Base`: should return a valid casted pointer of the passed instance to the base type

#### Special statics

* `name`: return the class name

#### Special methods

Special methods override the cclass methods, they all start by `__`.

* `id`: return the instance id (intptr address)
* `type`: return the type of the instance as a string
* `instanceof(stype)`: check if the instance is based on the passed type (as string)
* `cast(stype)`: return up-casted version of the instance in the passed type (as string)
* `c_...`: call the C method `...`
* `s_...`: call the super method `...`
* `s_Base_...`: call the super method `...` for a specific base class
* `get(member)`: get the member function of the given name (cdata throw an error when a nil member is accessed)
* `data`: return the datatable associated to this instance (per type, a cast from this instance will give a different datatable)

### Usage

* the name will be used as a FFI symbol prefix
* `statics` and `methods` contain mapped lua functions or `true` to bind the C function 
* in case of overloading with a lua function, the C function can be retrieved using `__c_function_name`
* in case of overloading of a base class method, it can be retrieved using  `__s_function_name` or in a more specific way `__s_Base_function_name` (super)
* statics are not inherited and are only availables from the class object
* Luaoop style operators are availables (allow to directly implement the operators in C)
* the `cclass` constructor will call `new` and bind the `delete` to `ffi.gc`, so new and delete are expected to manage heap memory, but having a `new/delete` is not required, any way used to obtain a valid cdata will allow the use of the methods (thanks to FFI metatypes)
* multiple inheritances is possible, but remember that LuaJIT can't know how C++ cast multiple inherited pointer types so using them will result in undefined behavior, `cclass` based on C++ inherited interface (with multiple inheritances) should define the static `cast_Base` function to generate a valid pointer casted to the base class type (it's also possible to overload the base methods in C and cast the pointer here, giving more control but losing the interest of having `cclass` inheritance)
* only up-cast is available, casting an instance back to a child class is not allowed (it's possible using ffi.cast, but this can result in undefined behavior, like a `A*` -> `void*` -> `B*`)

Example:
```lua
-- adding behavior to a struct

ffi.cdef([[
typedef struct{
  int x;
  int y;
} Vec2;
]])

-- get cdata constructor
local ct_Vec2 = ffi.typeof("Vec2")

-- define the type methods
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

-- create Vec2 instance using the ctype

local vec = ct_Vec2()
vec.x = 1
vec.y = 2
print(vec*10) -- "(10,20)"
```

See the `cclass` example directory to understand more the design and to interface with C++.
