import os, osproc, sequtils, strutils, re, sets, nimbox, options, parseopt

import core, scan, draw, fsoperations, interactions, nimboxext

proc spawnShell(nb: var Nimbox) =
  const
    fallback = "/bin/sh"
  nb.shutdown()
  stdout.writeLine("")
  stdout.writeLine("")
  stdout.writeLine(r"  /\^/\^/\^/\ ")
  stdout.writeLine(r" #############")
  stdout.writeLine(r" ### nimmm ###")
  stdout.writeLine(r" #############")
  stdout.writeLine("")
  try:
    let process = startProcess(getEnv("SHELL", fallback),
        options = {poUsePath, poParentStreams, poInteractive})
    let exitCode = process.waitForExit()
    process.close()
  except:
    discard
  nb = newNb()

proc startSearch(nb: var Nimbox, showHidden: bool): tuple[entries: seq[
    DirEntry], error: bool] =
  nb.shutdown()
  let
    pattern = askString(" /", nb)
  result = search(pattern, showHidden)
  nb = newNb()

proc safeSetCurDir(s: var State, path: string) =
  var safeDir = path
  while not existsDir(safeDir):
    safeDir = safeDir.parentDir
  setCurrentDir(safeDir)
  s.tabs[s.currentTab].cd = getCurrentDir()

proc mainLoop(nb: var Nimbox) =
  var
    s = initState()
    err = ""

  proc refresh() =
    var scanResult = scan(s.showHidden)
    err = ""
    s.entries = scanResult.entries
    if scanResult.error:
      err = "Some entries couldn't be displayed"
    if s.entries.len > 0:
      if s.currentIndex < 0:
        s.currentIndex = 0
      elif s.currentIndex > s.entries.high:
        s.currentIndex = s.entries.high

  proc switchTab(i: int) =
    if i < s.tabs.len:
      s.currentTab = i
      safeSetCurDir(s, s.tabs[s.currentTab].cd)
      refresh()

  proc up() =
    s.currentIndex = s.currentIndex - 1
    if s.currentIndex < 0:
      s.currentIndex = s.entries.high

  proc down() =
    s.currentIndex = s.currentIndex + 1
    if s.currentIndex > s.entries.high:
      s.currentIndex = 0

  proc left() =
    let prevDir = getCurrentDir()
    if parentDir(getCurrentDir()) == "":
      safeSetCurDir(s, "/")
    else:
      safeSetCurDir(s, parentDir(getCurrentDir()))
    refresh()
    if prevDir != "/":
      s.currentIndex = getIndexOfDir(s.entries, prevDir)

  proc right() =
    if not s.empty:
      if s.currentEntry.info.kind == pcDir:
        let prev = getCurrentDir()
        try:
          safeSetCurDir(s, s.currentEntry.path)
          refresh()
          s.currentIndex = 0
        except:
          err = "Cannot open directory"
          safeSetCurDir(s, prev)
      elif s.currentEntry.info.kind == pcFile:
        openFile(s.currentEntry.path)

  refresh()

  while true:
    nb.inputMode = inpEsc and inpMouse
    redraw(s, err, nb)

    let event = nb.pollEvent()
    case event.kind:
    of EventType.Key:
      case event.ch:
      of 'q':
        break
      of '!':
        spawnShell(nb)
        refresh()
      of '.':
        s.showHidden = not s.showHidden
        refresh()
      of 'a':
        for entry in s.entries:
          s.selected.incl(entry.path)
      of 's':
        s.selected.clear()
      of 'g':
        s.currentIndex = 0
      of 'G':
        s.currentIndex = s.entries.high
      of 'j':
        down()
      of 'k':
        up()
      of 'h':
        left()
      of 'l':
        right()
      of '~':
        safeSetCurDir(s, getHomeDir())
        refresh()
        s.currentIndex = 0
      of 't':
        s.tabs.add(Tab(cd: getCurrentDir(), index: s.currentIndex))
        switchTab(s.tabs.high)
      of 'w':
        if s.tabs.len > 1:
          s.tabs.del(s.currentTab)
        switchTab(max(0, s.currentTab - 1))
      of '1':
        switchTab(0)
      of '2':
        switchTab(1)
      of '3':
        switchTab(2)
      of '4':
        switchTab(3)
      of '5':
        switchTab(4)
      of '6':
        switchTab(5)
      of '7':
        switchTab(6)
      of '8':
        switchTab(7)
      of '9':
        switchTab(8)
      of '0':
        switchTab(9)
      of 'e':
        if not s.empty:
          if s.currentEntry.info.kind == pcFile:
            editFile(s.currentEntry.path, nb)
            refresh()
      of 'p':
        if not s.empty:
          if s.currentEntry.info.kind == pcFile:
            viewFile(s.currentEntry.path, nb)
      of 'f':
        newFile(nb)
        refresh()
      of 'd':
        newDir(nb)
        refresh()
      of 'r':
        rename(s.currentEntry.relative, nb)
        refresh()
      of 'P':
        copyEntries(s.selected, nb)
        s.selected.clear()
        refresh()
      of 'V':
        moveEntries(s.selected, nb)
        s.selected.clear()
        refresh()
      of 'X':
        deleteEntries(s.selected, nb)
        s.selected.clear()
        refresh()
      of '/':
        let result = startSearch(nb, s.showHidden)
        s.entries = result.entries
        if result.error:
          err = "Some entries could not be displayed."
        s.currentIndex = 0
      else:
        discard
      case event.sym:
      of Enter:
        right()
      of Backspace:
        left()
      of Space:
        if not s.empty:
          if not s.selected.contains(s.currentEntry.path):
            s.selected.incl(s.currentEntry.path)
          else:
            s.selected.excl(s.currentEntry.path)
      of Up:
        up()
      of Down:
        down()
      of Symbol.Left:
        left()
      of Symbol.Right:
        right()
      of Escape:
        refresh()
      else:
        discard
    of EventType.None:
      discard
    of EventType.Resize:
      discard
    of EventType.Mouse:
      case event.action:
      of WheelUp:
        up()
      of WheelDown:
        down()
      else:
        discard

when isMainModule:
  var p = initOptParser()
  while true:
    p.next()
    case p.kind
      of cmdEnd: break
      of cmdArgument:
        setCurrentDir(p.key)
      else: continue

  var nb = newNb()
  addQuitProc(proc () {.noconv.} = nb.shutdown())
  mainLoop(nb)
