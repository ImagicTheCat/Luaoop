package = "Luaoop"
version = "scm-1"
source = {
  url = "git://github.com/ImagicTheCat/Luaoop",
}

description = {
  summary = "One file simple Lua library to do OOP (Object Oriented Programming).",
  detailed = [[
    Luaoop is a small library to do OOP. 
    The library aim interesting features like the C++ OOP with additional reflexive tools.
  ]],
  homepage = "https://github.com/ImagicTheCat/Luaoop",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1, < 5.4"
}

build = {
  type = "builtin",
  modules = {
    Luaoop = "src/Luaoop.lua"
  }
}
