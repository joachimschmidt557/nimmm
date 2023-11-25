# Package

version       = "0.3.0"
author        = "joachimschmidt557"
description   = "A terminal file manager written in nim"
license       = "GPL-3.0"
srcDir        = "src"
bin           = @["nimmm"]


# Dependencies

requires "nim >= 1.4.4"
requires "nimbox >= 0.1.0"
requires "lscolors >= 0.3.3"
requires "wcwidth >= 0.1.3"
