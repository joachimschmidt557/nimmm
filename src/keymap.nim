import tables, strutils, os
import std/parsecfg
import std/[strutils, streams]

import nimbox

type
  Action* = enum
    ## An action nimmm can perform (in normal mode or search results mode)
    AcNone,
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
    AcEndSearch,

  Keymap* = object
    ## Configurable keymap information is stored in objects of this type
    chars: TableRef[char, Action]
    symbols: TableRef[Symbol, Action]
    mouse: TableRef[Mouse, Action]

let
  actionNames = {"quit": AcQuit, "shell": AcShell, "toggle-hidden": AcToggleHidden,
                  "select-all": AcSelectAll, "select-none": AcClearSelection,
                  "first": AcFirst, "last": AcLast, "down": AcDown,
                  "up": AcUp, "left": AcLeft, "right": AcRight,
                  "home": AcHomeDir, "new-tab": AcNewTab,
                  "close-tab": AcCloseTab,
                  "tab-1": AcTab1, "tab-2": AcTab2, "tab-3": AcTab3,
                  "tab-4": AcTab4, "tab-5": AcTab5, "tab-6": AcTab6,
                  "tab-7": AcTab7, "tab-8": AcTab8, "tab-9": AcTab9,
                  "tab-10": AcTab10, "edit": AcEdit, "pager": AcPager,
                  "rename": AcRename,
                  "new-file": AcNewFile, "new-dir": AcNewDir,
                  "copy": AcCopySelected,
                  "move": AcMoveSelected, "delete": AcDeleteSelected,
                  "search": AcSearch, "none": AcNone, "select": AcSelect,
                  "end-search": AcEndSearch
    }.newTable

  symbolNames = {"insert": Symbol.Insert, "delete": Symbol.Delete,
                  "home": Symbol.Home, "end": Symbol.End,
                  "pgup": Symbol.PgUp, "pgdn": Symbol.PgDn,
                  "up": Symbol.Up, "down": Symbol.Down,
                  "left": Symbol.Left, "right": Symbol.Right,
                  "ESC": Symbol.Escape, "SPC": Symbol.Space,
                  "TAB": Symbol.Tab, "RET": Symbol.Enter,
                  "DEL": Symbol.Backspace}.newTable
  mouseNames = {"left": Mouse.Left, "right": Mouse.Right,
                 "middle": Mouse.Middle, "wheel-up": Mouse.WheelUp,
                 "wheel-down": Mouse.WheelDown}.newTable

  defaultChars = {'q': AcQuit, '!': AcShell, '.': AcToggleHidden,
                   'a': AcSelectAll, 's': AcClearSelection,
                   'g': AcFirst, 'G': AcLast, 'j': AcDown,
                   'k': AcUp, 'h': AcLeft, 'l': AcRight,
                   '~': AcHomeDir, 't': AcNewTab, 'w': AcCloseTab,
                   '1': AcTab1, '2': AcTab2, '3': AcTab3,
                   '4': AcTab4, '5': AcTab5, '6': AcTab6,
                   '7': AcTab7, '8': AcTab8, '9': AcTab9,
                   '0': AcTab10, 'e': AcEdit, 'p': AcPager, 'r': AcRename,
                   'f': AcNewFile, 'd': AcNewDir, 'P': AcCopySelected,
                   'V': AcMoveSelected, 'X': AcDeleteSelected,
                   '/': AcSearch,
    }.newTable
  defaultSymbols = {Symbol.Enter: AcRight, Symbol.Backspace: AcLeft,
                     Symbol.Space: AcSelect, Symbol.Up: AcUp,
                     Symbol.Down: AcDown, Symbol.Left: AcLeft,
                     Symbol.Right: AcRight, Symbol.Escape: AcEndSearch}.newTable
  defaultMouse = {Mouse.WheelUp: AcUp, Mouse.WheelDown: AcDown}.newTable
  defaultKeymap* = Keymap(chars: defaultChars, symbols: defaultSymbols,
      mouse: defaultMouse)

proc keymapFromConfig*(): Keymap =
  ## Loads the keymap from configuration file
  result = defaultKeymap

  let configFile = getConfigDir() / "nimmm.conf"
  if not fileExists(configFile): return
  var f = newFileStream(configFile, fmRead)
  if f == nil: return

  var
    p: CfgParser
    section = ""
  open(p, f, configFile)
  while true:
    var e = next(p)
    case e.kind
    of cfgEof: break
    of cfgSectionStart:
      section = e.section
    of cfgKeyValuePair:
      if section == "Keybindings":
        let action = actionNames.getOrDefault(e.value, AcNone)
        if e.key.len == 1:
          result.chars[e.key[0]] = action
        elif e.key in mouseNames:
          result.mouse[mouseNames[e.key]] = action
        elif e.key in symbolNames:
          result.symbols[symbolNames[e.key]] = action
    of cfgOption:
      discard
    of cfgError:
      discard
  close(p)

proc nimboxEventToAction*(event: nimbox.Event, keymap: Keymap): Action =
  ## Decides whether an action is associated with this event and in that case,
  ## returns that action
  case event.kind:
  of EventType.Key:
    if keymap.chars.contains(event.ch):
      return keymap.chars[event.ch]
    if keymap.symbols.contains(event.sym):
      return keymap.symbols[event.sym]
    return AcNone
  of EventType.Mouse:
    if keymap.mouse.contains(event.action):
      return keymap.mouse[event.action]
    return AcNone
  of EventType.Resize:
    return AcNone
  of EventType.None:
    return AcNone
