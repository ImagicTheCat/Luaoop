# TODO

* full instance members propagation (not based on member usage) to prevent lookup overhead of nil values on instances (and class same optimization, harder)

## dev branch

* no more class identification by string, but by reference (operators, types, instanceof...), allow for more natural Lua scoped classes, no global definitions
