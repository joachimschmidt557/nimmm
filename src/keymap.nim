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
  actionNames = {"quit":AcQuit, "shell":AcShell, "toggle-hidden":AcToggleHidden,
                  "select-all":AcSelectAll, "clear-selection":AcClearSelection,
                  "first":AcFirst, "last":AcLast, "down":AcDown,
                  "up":AcUp, "left":AcLeft, "right":AcRight,
                  "home":AcHomeDir, "new-tab":AcNewTab, "close-tab":AcCloseTab,
                  "tab-1":AcTab1, "tab-2":AcTab2, "tab-3":AcTab3,
                  "tab-4":AcTab4, "tab-5":AcTab5, "tab-6":AcTab6,
                  "tab-7":AcTab7, "tab-8":AcTab8, "tab-9":AcTab9,
                  "tab-10":AcTab10, "edit":AcEdit, "pager":AcPager, "rename":AcRename,
                  "new-file":AcNewFile, "new-dir":AcNewDir, "copy":AcCopySelected,
                  "move":AcMoveSelected, "delete":AcDeleteSelected,
                  "search":AcSearch,
                }.newTable
  defaultChars = {'q':AcQuit, '!':AcShell, '.':AcToggleHidden,
                   'a':AcSelectAll, 's':AcClearSelection,
                   'g':AcFirst, 'G':AcLast, 'j':AcDown,
                   'k':AcUp, 'h':AcLeft, 'l':AcRight,
                   '~':AcHomeDir, 't':AcNewTab, 'w':AcCloseTab,
                   '1':AcTab1, '2':AcTab2, '3':AcTab3,
                   '4':AcTab4, '5':AcTab5, '6':AcTab6,
                   '7':AcTab7, '8':AcTab8, '9':AcTab9,
                   '0':AcTab10, 'e':AcEdit, 'p':AcPager, 'r':AcRename,
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
