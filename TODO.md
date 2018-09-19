# TODO

* full instance members propagation (not based on member usage) to prevent lookup overhead of nil values on instances (and class same optimization, harder)
* no more class identification by string, but by reference (operators, types, instanceof...), allow for more natural Lua scoped classes, no global definitions

=> Rework Luaoop with a more simple approach, more clarity, more flexible, less tricks (more consistency).
