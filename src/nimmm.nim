import os, osproc, sets, nimbox, parseopt

import lscolors

import core, scan, draw, external, nimboxext, keymap, interactions

proc safeSetCurDir(s: var State, path: string) =
  var safeDir = path
  while not existsDir(safeDir):
    safeDir = safeDir.parentDir
  setCurrentDir(safeDir)
  s.tabs[s.currentTab].cd = getCurrentDir()

proc refresh(s: var State, lsc: LsColors) =
  s.error = ErrNone

  case s.tabStateInfo.state
  of TsNormal:
    var scanResult = scan(s.showHidden, lsc)
    s.entries = scanResult.entries
    if scanResult.error:
      s.error = ErrCannotShow
  of TsSearch, TsSearchResults:
    var scanResult = search(s.tabStateInfo.query, s.showHidden, lsc)
    s.entries = scanResult.entries
    if scanResult.error:
      s.error = ErrCannotShow

  if s.entries.len > 0:
    if s.currentIndex < 0:
      s.currentIndex = 0
    elif s.currentIndex > s.entries.high:
      s.currentIndex = s.entries.high

proc resetTab(s: var State) =
  s.tabStateInfo = TabStateInfo(state: TsNormal)
  s.currentIndex = 0

proc switchTab(s: var State, lsc: LsColors, i: int) =
  if i < s.tabs.len:
    s.currentTab = i
    s.safeSetCurDir(s.tabs[s.currentTab].cd)
    s.refresh(lsc)

proc up(s: var State) =
  s.currentIndex = s.currentIndex - 1
  if s.currentIndex < 0:
    s.currentIndex = s.entries.high

proc down(s: var State) =
  s.currentIndex = s.currentIndex + 1
  if s.currentIndex > s.entries.high:
    s.currentIndex = 0

proc left(s: var State, lsc: LsColors) =
  let prevDir = getCurrentDir()
  if parentDir(getCurrentDir()) == "":
    s.safeSetCurDir("/")
  else:
    s.safeSetCurDir(parentDir(getCurrentDir()))
  s.resetTab()
  s.refresh(lsc)
  if prevDir != "/":
    s.currentIndex = getIndexOfDir(s.entries, prevDir)

proc right(s: var State, lsc: LsColors) =
  if not s.empty:
    if s.currentEntry.info.kind == pcDir:
      let prev = getCurrentDir()
      try:
        s.safeSetCurDir(s.currentEntry.path)
        s.resetTab()
        s.refresh(lsc)
      except:
        s.error = ErrCannotCd
        s.safeSetCurDir(prev)
    elif s.currentEntry.info.kind == pcFile:
      openFile(s.currentEntry.path)

proc mainLoop(nb: var Nimbox) =
  let
    lsc = parseLsColorsEnv()
    keymap = keyMapFromEnv()
  var
    s = initState()

  s.refresh(lsc)

  while true:
    nb.inputMode = inpEsc and inpMouse
    redraw(s, nb)

    let
      event = nb.pollEvent()

    case s.tabStateInfo.state
    # Special keymap for incremental search (overrides custom keymaps)
    of TsSearch:
      case event.kind
      of EventType.Key:
        case event.sym
        of Symbol.Escape:
          s.resetTab()
        of Symbol.Backspace:
          if s.tabStateInfo.query.len == 0:
            s.resetTab()
          else:
            s.tabStateInfo.query.setLen(s.tabStateInfo.query.high)
        of Symbol.Enter:
          s.tabStateInfo = TabStateInfo(state: TsSearchResults, query: s.tabStateInfo.query)
        else:
          s.tabStateInfo.query.add(event.ch)

        s.refresh(lsc)
      of EventType.Mouse, EventType.Resize, EventType.None:
        discard
    # Normal keymap
    of TsNormal, TsSearchResults:
      case nimboxEventToAction(event, keymap):
      of AcNone: discard
      of AcQuit:
        break
      of AcShell:
        withoutNimbox(nb):
          spawnShell()
        s.refresh(lsc)
      of AcToggleHidden:
        s.showHidden = not s.showHidden
        s.refresh(lsc)
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
        s.down()
      of AcUp:
        s.up()
      of AcLeft:
        s.left(lsc)
      of AcRight:
        s.right(lsc)
      of AcHomeDir:
        s.safeSetCurDir(getHomeDir())
        s.resetTab()
        s.refresh(lsc)
      of AcNewTab:
        s.tabs.add(Tab(cd: getCurrentDir(),
                       index: s.currentIndex,
                       stateInfo: TabStateInfo(state: TsNormal)))
        s.switchTab(lsc, s.tabs.high)
      of AcCloseTab:
        if s.tabs.len > 1:
          s.tabs.del(s.currentTab)
        s.switchTab(lsc, max(0, s.currentTab - 1))
      of AcTab1:
        s.switchTab(lsc, 0)
      of AcTab2:
        s.switchTab(lsc, 1)
      of AcTab3:
        s.switchTab(lsc, 2)
      of AcTab4:
        s.switchTab(lsc, 3)
      of AcTab5:
        s.switchTab(lsc, 4)
      of AcTab6:
        s.switchTab(lsc, 5)
      of AcTab7:
        s.switchTab(lsc, 6)
      of AcTab8:
        s.switchTab(lsc, 7)
      of AcTab9:
        s.switchTab(lsc, 8)
      of AcTab10:
        s.switchTab(lsc, 9)
      of AcEdit:
        if not s.empty:
          if s.currentEntry.info.kind == pcFile:
            withoutNimbox(nb):
              editFile(s.currentEntry.path)
            s.refresh(lsc)
      of AcPager:
        if not s.empty:
          if s.currentEntry.info.kind == pcFile:
            withoutNimbox(nb):
              viewFile(s.currentEntry.path)
      of AcNewFile:
        withoutNimbox(nb):
          newFile(askString("new file: "))
        s.refresh(lsc)
      of AcNewDir:
        withoutNimbox(nb):
          newDir(askString("new directory: "))
        s.refresh(lsc)
      of AcRename:
        withoutNimbox(nb):
          rename(s.currentEntry.relative, askString("rename to: "))
        s.refresh(lsc)
      of AcCopySelected:
        withoutNimbox(nb):
          copyEntries(s.selected)
        s.selected.clear()
        s.refresh(lsc)
      of AcMoveSelected:
        withoutNimbox(nb):
          moveEntries(s.selected)
        s.selected.clear()
        s.refresh(lsc)
      of AcDeleteSelected:
        withoutNimbox(nb):
          deleteEntries(s.selected, askYorN("use force? [y/n]: "))
        s.selected.clear()
        s.refresh(lsc)
      of AcSearch:
        s.tabStateInfo = TabStateInfo(state: TsSearch, query: "")
        s.refresh(lsc)
      of AcEndSearch:
        s.resetTab()
        s.refresh(lsc)

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
