# Package

version       = "0.4.0"
author        = "joachimschmidt557"
description   = "A terminal file manager for Linux"
license       = "GPL-3.0"
srcDir        = "src"
bin           = @["nimmm"]


# Dependencies

requires "nim >= 1.4.4"
requires "nimbox >= 0.1.0"
requires "lscolors >= 1.0.0"
requires "wcwidth >= 0.1.3"
