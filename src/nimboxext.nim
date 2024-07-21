## Extension templates for the nimbox library
##
## These functions help in toggling the 256-colors option

import std/os

import nimbox

export
  nimbox.Colors256,
  nimbox.Modifier,
  nimbox.Symbol,
  nimbox.Mouse,
  nimbox.EventType,
  nimbox.Event,

  nimbox.Color,
  nimbox.Style,
  nimbox.InputMode,
  nimbox.OutputMode,

  nimbox.newNimbox,
  nimbox.`inputMode=`,
  nimbox.`outputMode=`,
  nimbox.shutdown,
  nimbox.width,
  nimbox.height,
  nimbox.clear,
  nimbox.present,
  nimbox.print,
  nimbox.`cursor=`,
  nimbox.peekEvent,

  nimbox.TB_HIDE_CURSOR

type
  Nimbox* = object of nimbox.Nimbox
    enable256Colors: bool

proc newNb*(enable256Colors: bool): Nimbox =
  ## Wrapper for `newNimbox`

  # This is not optimal, but we use the fact that nimbox.Nimbox is just an empty object. Therefore, we do not use nb further
  let nb = newNimbox()
  nb.inputMode = inpEsc and inpMouse
  if enable256Colors:
    nb.outputMode = out256

  Nimbox(enable256Colors: enable256Colors)

template withoutNimbox*(nb: var Nimbox, body: untyped) =
  let enable256Colors = nb.enable256Colors
  nb.shutdown()
  body
  nb = newNb(enable256Colors)

proc c8*(nb: Nimbox, color: int): int =
  ## Convert this color (`ck8`) into
  ## an int with regards to the current color mode
  if nb.enable256Colors:
    color - 1
  else:
    color

proc c8*(nb: Nimbox, color: Color): int =
  ## Convert this color enum into an int
  ## with regards to the current color mode
  nb.c8(ord(color))

proc fgHighlight*(nb: Nimbox): int =
  ## Provides a viable foreground color for highlighted items
  if nb.enable256Colors:
    16
  else:
    ord(clrBlack)
