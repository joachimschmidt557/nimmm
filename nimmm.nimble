# Package

version       = "0.1.0"
author        = "joachimschmidt557"
description   = "A terminal file manager written in nim"
license       = "GPL-3.0"
srcDir        = "src"
bin           = @["nimmm"]


# Dependencies

requires "nim >= 0.19.9"
requires "noise >= 0.1.3"
requires "nimbox >= 0.1.0"
requires "lscolors >= 0.2.2"