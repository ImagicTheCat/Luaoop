# TODO

* full instance members propagation (not based on member usage) to prevent lookup overhead of nil values on instances (and class same optimization, harder)
* no more class identification by string, but by reference (operators, types, instanceof...), allow for more natural Lua scoped classes, no global definitions
* don't try to make Luaoop sandbox-friendly, probably better that sandboxes build themselves around Luaoop: inherit all properties without processing, no safe access, no private per class (class.data instead)
* class.id instead of instance id
* class.type: return class definition or nil if not an instance
* remove class.instanceof (alias of class.is)

=> Rework Luaoop with a more simple approach, more clarity, more flexible, less tricks (more consistency).
