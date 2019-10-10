import tables, options

import nimbox

type
  Action* = enum
    AcQuit,
    AcShell,
    AcToggleHidden,
    AcUp,
    AcDown,
    AcLeft,
    AcRight,
    AcFirst,
    AcLast,
    AcHomeDir,
    AcEdit,
    AcPager,
    AcRename,
    AcNewFile,
    AcNewDir,
    AcSelect,
    AcSelectAll,
    AcClearSelection,
    AcDeleteSelected,
    AcCopySelected,
    AcMoveSelected,
    AcNewTab,
    AcCloseTab,
    AcTab1,
    AcTab2,
    AcTab3,
    AcTab4,
    AcTab5,
    AcTab6,
    AcTab7,
    AcTab8,
    AcTab9,
    AcTab10,
    AcSearch,

  Keymap* = object
    chars: TableRef[char, Action]
    symbols: TableRef[Symbol, Action]
    mouse: TableRef[Mouse, Action]

let
  defaultChars = {'q':AcQuit, '!':AcShell, '.':AcToggleHidden,
                 'a':AcSelectAll, 's':AcClearSelection,
                 'g':AcFirst, 'G':AcLast, 'j':AcDown,
                 'k':AcUp, 'h':AcLeft, 'l':AcLeft,
                 '~':AcHomeDir, 't':AcHomeDir, 'w':AcCloseTab,
                 '1':AcTab1, '2':AcTab2, '3':AcTab3,
                 '4':AcTab4, '5':AcTab5, '6':AcTab6,
                 '7':AcTab7, '8':AcTab8, '9':AcTab9,
                 '0':AcTab10, 'e':AcEdit, 'p':AcPager,
                 'f':AcNewFile, 'd':AcNewDir, 'P':AcCopySelected,
                 'V':AcMoveSelected, 'X':AcDeleteSelected,
                 '/':AcSearch,
                 }.newTable
  defaultSymbols = {Symbol.Enter:AcRight, Symbol.Backspace:AcLeft,
                    Symbol.Space:AcSelect, Symbol.Up:AcUp,
                    Symbol.Down:AcDown, Symbol.Left:AcLeft,
                    Symbol.Right:AcRight}.newTable
  defaultMouse = {Mouse.WheelUp:AcUp, Mouse.WheelDown:AcDown}.newTable
  defaultKeymap* = Keymap(chars:defaultChars, symbols:defaultSymbols, mouse:defaultMouse)

proc keymapFromEnv*(): Keymap =
  ## Loads the keymap from environment variables
  defaultKeymap

proc nimboxEventToAction*(event:nimbox.Event, keymap:Keymap): Option[Action] =
  ## Decides whether an action is associated with this
  ## event and in that case, returns that action
  case event.kind:
  of EventType.Key:
    if keymap.chars.contains(event.ch):
      return some keymap.chars[event.ch]
    if keymap.symbols.contains(event.sym):
      return some keymap.symbols[event.sym]
    return none Action
  of EventType.Mouse:
    if keymap.mouse.contains(event.action):
      return some keymap.mouse[event.action]
    return none Action
  of EventType.Resize:
    return none Action
  of EventType.None:
    return none Action
