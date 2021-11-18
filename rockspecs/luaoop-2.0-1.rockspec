package = "Luaoop"
version = "2.0-1"
source = {
  url = "git://github.com/ImagicTheCat/Luaoop",
  tag = "2.0"
}

description = {
  summary = "Pure Lua library for OOP (Object Oriented Programming).",
  detailed = [[
    Luaoop is a pure Lua library for OOP (Object Oriented Programming).
    It depends on the xtype dynamic type system library.
  ]],
  homepage = "https://github.com/ImagicTheCat/Luaoop",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1, <= 5.4",
  "xtype >= 1.0"
}

build = {
  type = "builtin",
  modules = {
    Luaoop = "src/Luaoop.lua"
  }
}
