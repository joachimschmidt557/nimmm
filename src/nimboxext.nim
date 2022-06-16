## Extension templates for the nimbox library
##
## These functions help in toggling the 256-colors option

import std/os

import nimbox

template newNb*(enable256Colors: bool): Nimbox =
  ## Wrapper for `newNimbox`
  let nb = newNimbox()
  nb.inputMode = inpEsc and inpMouse
  if enable256Colors:
    nb.outputMode = out256
  nb

template colors256Mode*(): bool =
  ## Should the 256-colors mode be turned on?
  existsEnv("NIMMM_256")

template withoutNimbox*(nb: var Nimbox, enable256Colors: bool, body: untyped) =
  nb.shutdown()
  body
  nb = newNb(enable256Colors)

template c8*(color: int): int =
  ## Convert this color (`ck8`) into
  ## an int with regards to the current color mode
  if colors256Mode():
    color - 1
  else:
    color

template c8*(color: Color): int =
  ## Convert this color enum into an int
  ## with regards to the current color mode
  c8(ord(color))

template fgBlack*(): int =
  ## Provides a viable foreground-black color
  if colors256Mode():
    8
  else:
    ord(clrBlack)
