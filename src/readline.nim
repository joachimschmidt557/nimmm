import std/unicode

import nimboxext

type
  ProcessInputTextModeResult* = enum
    PrNoAction,
    PrCanceled,
    PrComplete,

proc editMoveLeft(input: string, cursorPos: var int) =
  if cursorPos > 0:
    let (_, runeLen) = lastRune(input, cursorPos - 1)
    cursorPos -= runeLen

proc editMoveRight(input: string, cursorPos: var int) =
  if cursorPos < input.len:
    let runeLen = runeLenAt(input, cursorPos)
    cursorPos += runeLen

proc editBackspace(input: var string, cursorPos: var int) =
  if cursorPos > 0:
    let (_, runeLen) = lastRune(input, cursorPos - 1)
    input = input[0..cursorPos - 1 - runeLen] & input.substr(cursorPos)
    cursorPos -= runeLen

proc editDelete(input: var string, cursorPos: int) =
  if cursorPos < input.len:
    let runeLen = runeLenAt(input, cursorPos)
    input = input[0..cursorPos - 1] & input.substr(cursorPos + runeLen)

proc processInputTextMode*(event: nimboxext.Event,
                           input: var string,
                           cursorPos: var int): ProcessInputTextModeResult =
  ## common input processing for MdInputText and MdSearch
  case event.kind
  of EventType.Key:
    if event.mods == @[Modifier.Ctrl]:
      case event.sym
      # normal escape key press, no ctrl, but still here
      of Symbol.Escape:
        return PrCanceled
      # normal backspace key press, no ctrl, but still here
      of Symbol.Backspace:
        editBackspace(input, cursorPos)
      # normal enter key press, no ctrl, but still here
      of Symbol.Enter:
        return PrComplete
      of Symbol.Character:
        case event.ch
        of 'C':
          return PrCanceled
        of 'B':
          editMoveLeft(input, cursorPos)
        of 'F':
          editMoveRight(input, cursorPos)
        of 'A':
          cursorPos = 0;
        of 'E':
          cursorPos = input.len;
        else:
          discard
      else:
        discard
    elif event.mods == @[Modifier.Alt]:
      discard
    else:
      case event.sym
      of Symbol.Delete:
        editDelete(input, cursorPos)
      of Symbol.Space:
        let inserted = " "
        input.insert(inserted, cursorPos)
        cursorPos += inserted.len
      of Symbol.Character:
        let inserted = $event.ch.Rune
        input.insert(inserted, cursorPos)
        cursorPos += inserted.len
      of Symbol.Left:
        editMoveLeft(input, cursorPos)
      of Symbol.Right:
        editMoveRight(input, cursorPos)
      of Symbol.Home:
        cursorPos = 0;
      of Symbol.End:
        cursorPos = input.len;
      else:
        discard
  of EventType.Mouse, EventType.Resize, EventType.None:
    discard

  return PrNoAction
