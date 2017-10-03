Luaoop is a small library to do OOP.
The library aim interesting features like the C++ OOP with additional reflexive tools.

Look at the examples for more understanding of the library.

# API

## Special functions

You can define special functions for a class, they will be overridden the same way other functions are.
Every special function start with `__` (they are not metamethods, they are named like this to keep consistency with the Lua notation).

### Misc

* `construct`: called to instanciate a class object

### Operators (or things similar)

Operator are defined like this:
```lua
Object:__op() -- unary
Object:__op_type(rhs) -- binary
```

Unary
* `tostring`: like the metamethod
* `unm`: like the metamethod

Binary
* `concat`: like the metamethod (no order)
* `add`: like the metamethod (no order)
* `sub`: like the metamethod (can be omitted if `unm` is defined for rhs)
* `mul`: like the metamethod (no order)
* `div`: like the metamethod
* `mod`: like the metamethod 
* `pow`: like the metamethod
* `eq`: like the metamethod (doesn't throw an error if the operator is missing, will be false by default)
* `le`: like the metamethod
* `lt`: like the metamethod

Be careful with `eq`, `le`, `lt`, they will be called like any binary operator, following the type of rhsand they will not be called if the comparison is not between two Luaoop instances.
Comparison of different instances with different types is possible, but may change in the future.

# Version

It is designed to work with luajit (Lua 5.1), but the code should be easy to adapt to other Lua versions.

# TODO

* constructor/super tools
