import std/[os, sets, parseopt, sequtils, algorithm, strutils,
    options, re]

import nimbox
import lscolors

import core, scan, draw, external, nimboxext, keymap, interactions

proc getIndexOfItem(s: State, name: string): int =
  let
    paths = s.entries.mapIt(it.path)
    i = paths.binarySearch(name, cmpIgnoreCase)
  if i > 0 and s.visibleEntriesMask[i]: s.visibleEntries.binarySearch(i) else: 0

proc safeSetCurDir(s: var State, path: string) =
  var safeDir = path
  while not dirExists(safeDir):
    safeDir = safeDir.parentDir
  setCurrentDir(safeDir)
  s.tabs[s.currentTab].cd = getCurrentDir()

proc visible(entry: DirEntry, showHidden: bool, regex: Option[Regex]): bool =
  let
    notHidden = showHidden or not isHidden(entry.path)
    matchesRe = if regex.isSome: extractFilename(entry.path).contains(
        regex.get) else: true
  matchesRe and notHidden

proc compileRegex(searchQuery: string): Option[Regex] =
  if searchQuery != "":
    try:
      let compiled = re(searchQuery, flags = {reStudy, reIgnoreCase})
      some(compiled)
    except RegexError:
      none(Regex)
  else:
    none(Regex)

proc refresh(s: var State) =
  let regex = compileRegex(s.currentSearchQuery)

  s.visibleEntries = @[]

  for i, entry in s.entries:
    let visible = visible(entry, s.showHidden, regex)
    s.visibleEntriesMask[i] = visible
    if visible: s.visibleEntries &= i

  if s.visibleEntries.len > 0:
    if s.currentIndex < 0:
      s.currentIndex = 0
    elif s.currentIndex > s.visibleEntries.high:
      s.currentIndex = s.visibleEntries.high

proc rescan(s: var State, lsc: LsColors) =
  s.error = ErrNone

  let scanResult = scan(lsc)
  s.entries = scanResult.entries
  s.visibleEntriesMask = repeat(true, s.entries.len)
  s.visibleEntries = @[]
  if scanResult.error:
    s.error = ErrCannotShow

  s.refresh()

proc resetTab(s: var State) =
  s.currentSearchQuery = ""
  s.modeInfo = ModeInfo(mode: MdNormal)
  s.currentIndex = 0

proc switchTab(s: var State, lsc: LsColors, i: int) =
  if i < s.tabs.len:
    s.currentTab = i
    s.safeSetCurDir(s.tabs[s.currentTab].cd)
    s.rescan(lsc)

proc up(s: var State) =
  s.currentIndex = s.currentIndex - 1
  if s.currentIndex < 0:
    s.currentIndex = s.visibleEntries.high

proc down(s: var State) =
  s.currentIndex = s.currentIndex + 1
  if s.currentIndex > s.visibleEntries.high:
    s.currentIndex = 0

proc left(s: var State, lsc: LsColors) =
  if parentDir(getCurrentDir()) == "":
    return
  let prevDir = getCurrentDir()
  s.safeSetCurDir(parentDir(getCurrentDir()))
  s.resetTab()
  s.rescan(lsc)
  s.currentIndex = getIndexOfItem(s, prevDir)

proc right(s: var State, lsc: LsColors) =
  if not s.empty:
    if s.currentEntry.info.kind == pcDir:
      let prev = getCurrentDir()
      try:
        s.safeSetCurDir(s.currentEntry.path)
        s.resetTab()
        s.rescan(lsc)
      except:
        s.error = ErrCannotCd
        s.safeSetCurDir(prev)
    elif s.currentEntry.info.kind == pcFile:
      try:
        openFile(s.currentEntry.path)
      except:
        s.error = ErrCannotOpen

proc mainLoop(nb: var Nimbox, enable256Colors: bool) =
  let
    lsc = parseLsColorsEnv()
    keymap = keyMapFromConfig()
  var
    s = initState()

  s.rescan(lsc)

  while true:
    redraw(s, nb)

    let event = nb.pollEvent()

    case s.modeInfo.mode
    # Input mode: Ignore keymap
    of MdInput:
      case event.kind
      of EventType.Key:
        case event.sym
        of Symbol.Escape:
          s.resetTab()
        of Symbol.Backspace:
          if s.modeInfo.input.len > 0:
            s.modeInfo.input.setLen(s.modeInfo.input.high)
        of Symbol.Enter:
          withoutNimbox(nb, enable256Colors):
            s.modeInfo.callback(s.modeInfo.input)
          s.rescan(lsc)
          s.resetTab()
        of Symbol.Space:
          s.modeInfo.input.add(" ")
        of Symbol.Character:
          s.modeInfo.input.add(event.ch)
        else:
          discard

        s.refresh()
      of EventType.Mouse, EventType.Resize, EventType.None:
        discard
    # Incremental search mode: Ignore keymap
    of MdSearch:
      case event.kind
      of EventType.Key:
        case event.sym
        of Symbol.Escape:
          s.resetTab()
        of Symbol.Backspace:
          if s.currentSearchQuery.len == 0:
            s.resetTab()
          else:
            s.currentSearchQuery.setLen(s.currentSearchQuery.high)
        of Symbol.Enter:
          s.modeInfo = ModeInfo(mode: MdNormal)
        of Symbol.Space:
          s.currentSearchQuery.add(" ")
        of Symbol.Character:
          s.currentSearchQuery.add(event.ch)
        else:
          discard

        s.refresh()
      of EventType.Mouse, EventType.Resize, EventType.None:
        discard
    # Normal keymap
    of MdNormal:
      case nimboxEventToAction(event, keymap):
      of AcNone: discard
      of AcQuit:
        break
      of AcShell:
        let cwdBackup = getCurrentDir()
        withoutNimbox(nb, enable256Colors):
          spawnShell()
        s.safeSetCurDir(cwdBackup)
        s.rescan(lsc)
      of AcToggleHidden:
        s.showHidden = not s.showHidden
        s.refresh()
      of AcSelect:
        if not s.empty:
          if not s.selected.contains(s.currentEntry.path):
            s.selected.incl(s.currentEntry.path)
          else:
            s.selected.excl(s.currentEntry.path)
      of AcSelectAll:
        for i in s.visibleEntries:
          let entry = s.entries[i]
          s.selected.incl(entry.path)
      of AcClearSelection:
        s.selected.clear()
      of AcFirst:
        s.currentIndex = 0
      of AcLast:
        s.currentIndex = s.visibleEntries.high
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
        s.rescan(lsc)
      of AcNewTab:
        s.tabs.add(Tab(cd: getCurrentDir(),
                       index: s.currentIndex,
                       searchQuery: ""))
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
            withoutNimbox(nb, enable256Colors):
              editFile(s.currentEntry.path)
            s.rescan(lsc)
      of AcPager:
        if not s.empty:
          if s.currentEntry.info.kind == pcFile:
            withoutNimbox(nb, enable256Colors):
              viewFile(s.currentEntry.path)
      of AcNewFile:
        s.modeInfo = ModeInfo(mode: MdInput,
                              prompt: "new file:",
                              input: "",
                              callback: newFile)
      of AcNewDir:
        s.modeInfo = ModeInfo(mode: MdInput,
                              prompt: "new directory:",
                              input: "",
                              callback: newDir)
      of AcRename:
        let relativePath = extractFilename(s.currentEntry.path)
        s.modeInfo = ModeInfo(mode: MdInput,
                              prompt: "rename to:",
                              input: relativePath,
                              callback: proc (input: string) =
          rename(relativePath, input))
      of AcCopySelected:
        withoutNimbox(nb, enable256Colors):
          copyEntries(s.selected)
        s.selected.clear()
        s.rescan(lsc)
      of AcMoveSelected:
        let pwdBackup = getCurrentDir()
        withoutNimbox(nb, enable256Colors):
          moveEntries(s.selected)
        s.selected.clear()
        s.safeSetCurDir(pwdBackup)
        s.rescan(lsc)
      of AcDeleteSelected:
        let pwdBackup = getCurrentDir()
        withoutNimbox(nb, enable256Colors):
          deleteEntries(s.selected, askYorN("use force? [y/n]: "))
        s.selected.clear()
        s.safeSetCurDir(pwdBackup)
        s.rescan(lsc)
      of AcSearch:
        s.currentSearchQuery = ""
        s.modeInfo = ModeInfo(mode: MdSearch)
      of AcEndSearch:
        s.currentSearchQuery = ""
        s.refresh()

when isMainModule:
  var p = initOptParser()
  while true:
    p.next()
    case p.kind
      of cmdEnd: break
      of cmdArgument:
        setCurrentDir(p.key)
      else: continue

  let enable256Colors = colors256Mode()
  var nb = newNb(enable256Colors)
  addQuitProc(proc () {.noconv.} = nb.shutdown())
  mainLoop(nb, enable256Colors)
