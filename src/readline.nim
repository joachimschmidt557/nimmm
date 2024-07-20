import std/unicode

import nimbox

type
  ProcessInputTextModeResult* = enum
    PrNoAction,
    PrCanceled,
    PrComplete,

proc processInputTextMode*(event: nimbox.Event,
                           input: var string,
                           cursorPos: var int): ProcessInputTextModeResult =
  ## common input processing for MdInputText and MdSearch
  case event.kind
  of EventType.Key:
    case event.sym
    of Symbol.Escape:
      return PrCanceled
    of Symbol.Backspace:
      if cursorPos > 0:
        let (_, runeLen) = lastRune(input, cursorPos - 1)
        input = input[0..cursorPos - 1 - runeLen] & input.substr(cursorPos)
        cursorPos -= runeLen
    of Symbol.Delete:
      if cursorPos < input.len:
        let runeLen = runeLenAt(input, cursorPos)
        input = input[0..cursorPos - 1] & input.substr(cursorPos + runeLen)
    of Symbol.Enter:
      return PrComplete
    of Symbol.Space:
      let inserted = " "
      input.insert(inserted, cursorPos)
      cursorPos += inserted.len
    of Symbol.Character:
      let inserted = $event.ch.Rune
      input.insert(inserted, cursorPos)
      cursorPos += inserted.len
    of Symbol.Left:
      if cursorPos > 0:
        let (_, runeLen) = lastRune(input, cursorPos - 1)
        cursorPos -= runeLen
    of Symbol.Right:
      if cursorPos < input.len:
        let runeLen = runeLenAt(input, cursorPos)
        cursorPos += runeLen
    of Symbol.Home:
      cursorPos = 0;
    of Symbol.End:
      cursorPos = input.len;
    else:
      discard
  of EventType.Mouse, EventType.Resize, EventType.None:
    discard

  return PrNoAction
