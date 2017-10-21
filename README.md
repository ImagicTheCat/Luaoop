Luaoop is a small library to do OOP.
The library aim interesting features like the C++ OOP with additional reflexive tools.

Look at the examples for more understanding of the library.

# Luaoop

## Install

Instead of adding the file manually, you can use luarocks:

`luarocks install https://raw.githubusercontent.com/ImagicTheCat/Luaoop/master/rockspecs/luaoop-0.1-1.rockspec`

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

-- get private storage table of the instantiated object
class.getprivate(o)

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

-- check if the instance is an instance of a specific classname
class.instanceof(o, name)

-- create object with a specific class and constructor arguments 
class.instanciate(class, ...)
-- SHORTCUT Class(...)

-- (internal) get operator from instance/class, rhs_class can be nil for unary operators
class.getop(lhs_class, name, rhs_class, no_error)
```

## Inheritance

Single and multiple inheritances are possibles, "static" variables and methods (all properties) will be overridden by each new definition of the child class.
In case of multiple inheritance with methods/members with the same name, one will be taken arbitrarily. You can solve this issue by accessing directly to a specific parent method/member using the super access.

Inheritance is resolved dynamically, it means you can modify any class and the changes will be applied to already instantiated objects.

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
  self.B.test(self)
end

```

## Super access

You can access any parent class method in the instance with the namespace named as the desired class.

Example:
```lua
A = class("A")

function A:__construct()
  print("a")
end

B = class("B", A)
function B:__construct()
  self.A.__construct(self) -- call parent (A) constructor
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

### Operators (or things similar)

Operators are defined like this:
```lua
Object:__op() -- unary
Object:__op_rhstype(rhs) -- binary
```

Unary
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

## "Security / Sandbox"

Luaoop doesn't aim to "sandbox" things, but if you want to add private properties to the object instances (for example, to keep a luajit FFI pointer away from users), use the `class.getprivate` function and remove it from the user env (`class.getprivate` use `getmetatable`, so you will need to remove it too).
Instantiated objects are safe to handle, users can't touch the class definitions from the instance if they don't have access to the original class table (for example, an enumeration in a class should not be modified from the instance and any child class).

With some tweaks, you can allow scripts to create classes based on other classes, without allowing them to mess with the previous definitions.

Here are a non-exhaustive list of functions you should remove from the sandbox for safe class sharing and/or app private storage for instances:
* `getmetatable`
* `setmetatable`
* `rawset`
* `rawget`
* `class.unsafe`
* `class.definition`
* `class.getprivate`

Which let:
* `class.new`
* `class.safeaccess`
* `class.safedef`: only if you want all the class definitions to be accessibles
* `class.name`
* `class.type`
* `class.instanceof`
* `class.instanciate`

See `sandbox.lua` example for usage.

## TODO

* inheritance performance (cached inheritance) with modification propagation on instantiaded objects (maybe)
