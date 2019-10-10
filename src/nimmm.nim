import os, osproc, sequtils, strutils, re, sets, nimbox, options, parseopt

import lscolors

import core, scan, draw, fsoperations, interactions, nimboxext, keymap

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
    lsc = parseLsColorsEnv()
    err = ""
    keymap = keyMapFromEnv()

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
    redraw(s, err, nb, lsc)

    let
      event = nb.pollEvent()
      action = nimboxEventToAction(event, keymap)

    if action.isNone:
      continue

    case action.get:
    of AcQuit:
      break
    of AcShell:
      spawnShell(nb)
      refresh()
    of AcToggleHidden:
      s.showHidden = not s.showHidden
      refresh()
    of AcSelect:
      if not s.empty:
        if not s.selected.contains(s.currentEntry.path):
          s.selected.incl(s.currentEntry.path)
        else:
          s.selected.excl(s.currentEntry.path)
    of AcSelectAll:
      for entry in s.entries:
        s.selected.incl(entry.path)
    of AcClearSelection:
      s.selected.clear()
    of AcFirst:
      s.currentIndex = 0
    of AcLast:
      s.currentIndex = s.entries.high
    of AcDown:
      down()
    of AcUp:
      up()
    of AcLeft:
      left()
    of AcRight:
      right()
    of AcHomeDir:
      safeSetCurDir(s, getHomeDir())
      refresh()
      s.currentIndex = 0
    of AcNewTab:
      s.tabs.add(Tab(cd: getCurrentDir(), index: s.currentIndex))
      switchTab(s.tabs.high)
    of AcCloseTab:
      if s.tabs.len > 1:
        s.tabs.del(s.currentTab)
      switchTab(max(0, s.currentTab - 1))
    of AcTab1:
      switchTab(0)
    of AcTab2:
      switchTab(1)
    of AcTab3:
      switchTab(2)
    of AcTab4:
      switchTab(3)
    of AcTab5:
      switchTab(4)
    of AcTab6:
      switchTab(5)
    of AcTab7:
      switchTab(6)
    of AcTab8:
      switchTab(7)
    of AcTab9:
      switchTab(8)
    of AcTab10:
      switchTab(9)
    of AcEdit:
      if not s.empty:
        if s.currentEntry.info.kind == pcFile:
          editFile(s.currentEntry.path, nb)
          refresh()
    of AcPager:
      if not s.empty:
        if s.currentEntry.info.kind == pcFile:
          viewFile(s.currentEntry.path, nb)
    of AcNewFile:
      newFile(nb)
      refresh()
    of AcNewDir:
      newDir(nb)
      refresh()
    of AcRename:
      rename(s.currentEntry.relative, nb)
      refresh()
    of AcCopySelected:
      copyEntries(s.selected, nb)
      s.selected.clear()
      refresh()
    of AcMoveSelected:
      moveEntries(s.selected, nb)
      s.selected.clear()
      refresh()
    of AcDeleteSelected:
      deleteEntries(s.selected, nb)
      s.selected.clear()
      refresh()
    of AcSearch:
      let result = startSearch(nb, s.showHidden)
      s.entries = result.entries
      if result.error:
        err = "Some entries could not be displayed."
      s.currentIndex = 0

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
