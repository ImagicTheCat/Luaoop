package = "Luaoop"
version = "1.3-1"
source = {
  url = "git://github.com/ImagicTheCat/Luaoop",
  tag = "1.3"
}

description = {
  summary = "One file Lua library to do OOP (Object Oriented Programming).",
  detailed = [[
    Luaoop is a library to do OOP (Object Oriented Programming) which aims to be simple, powerful and optimized (for LuaJIT).
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
