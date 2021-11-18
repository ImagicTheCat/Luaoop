package = "Luaoop"
version = "scm-3"
source = {
  url = "git://github.com/ImagicTheCat/Luaoop",
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
  "xtype"
}

build = {
  type = "builtin",
  modules = {
    Luaoop = "src/Luaoop.lua"
  }
}
