import std/[os, sets, parseopt, sequtils, algorithm, strutils,
            options, re, segfaults, selectors, dirs, paths]

import posix, posix/inotify

import lscolors

import core, scan, draw, external, nimboxext, keymap, readline

type
  State = object of core.State
    lsc: LsColors
    inotifyHandle: FileHandle
    currentDirWatcher: cint

proc getIndexOfItem(s: State, name: string): int =
  let
    paths = s.entries.mapIt(it.path)
    i = paths.binarySearch(name, cmpPaths)
  if i > 0 and s.visibleEntriesMask[i]: s.visibleEntries.binarySearch(i) else: 0

proc safeSetCurDir(s: var State, path: Path) =
  var safeDir = path
  while not dirExists(safeDir):
    safeDir = safeDir.parentDir
  setCurrentDir(safeDir)
  s.tabs[s.currentTab].cd = paths.getCurrentDir()

  doAssert s.inotifyHandle.inotifyRmWatch(s.currentDirWatcher) >= 0
  s.currentDirWatcher = s.inotifyHandle.inotifyAddWatch(os.getCurrentDir(),
      IN_CREATE or IN_DELETE or IN_MOVED_FROM or IN_MOVED_TO)
  doAssert s.currentDirWatcher >= 0

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
    s.currentIndex = clamp(s.currentIndex, 0, s.visibleEntries.high)

proc rescan(s: var State) =
  s.error = ErrNone

  let scanResult = scan(s.lsc)
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

proc switchTab(s: var State, i: int) =
  if i < s.tabs.len:
    s.currentTab = i
    s.safeSetCurDir(s.tabs[s.currentTab].cd)
    s.rescan()

proc up(s: var State) =
  s.currentIndex = s.currentIndex - 1
  if s.currentIndex < 0:
    s.currentIndex = s.visibleEntries.high

proc down(s: var State) =
  s.currentIndex = s.currentIndex + 1
  if s.currentIndex > s.visibleEntries.high:
    s.currentIndex = 0

proc left(s: var State) =
  if parentDir(paths.getCurrentDir()) == Path(""):
    return
  let prevDir = os.getCurrentDir()
  s.safeSetCurDir(parentDir(paths.getCurrentDir()))
  s.resetTab()
  s.rescan()
  s.currentIndex = getIndexOfItem(s, prevDir)

proc right(s: var State) =
  if not s.empty:
    if s.currentEntry.info.kind == pcDir:
      let prev = paths.getCurrentDir()
      try:
        s.safeSetCurDir(Path(s.currentEntry.path))
        s.resetTab()
        s.rescan()
      except:
        s.error = ErrCannotCd
        s.safeSetCurDir(prev)
    elif s.currentEntry.info.kind == pcFile:
      try:
        openFile(s.currentEntry.path)
      except:
        s.error = ErrCannotOpen

proc mainLoop(nb: var Nimbox) =
  let
    keymap = keyMapFromConfig()
  var
    s: State

    events = newSeq[nimboxext.Event]()
    terminalFile = open("/dev/tty")
    selector = newSelector[int]()

  # init core state
  s.initState()

  # init extra state
  s.lsc = parseLsColorsEnv()
  s.inotifyHandle = inotifyInit()
  doAssert s.inotifyHandle >= 0
  s.currentDirWatcher = s.inotifyHandle.inotifyAddWatch(os.getCurrentDir(),
      IN_CREATE or IN_DELETE or IN_MOVED_FROM or IN_MOVED_TO)
  doAssert s.currentDirWatcher >= 0

  defer:
    selector.close()
    terminalFile.close()

  s.rescan()

  selector.registerHandle(terminalFile.getOsFileHandle().int, {
      selectors.Event.Read}, 0)
  selector.registerHandle(s.inotifyHandle.int, {
      selectors.Event.Read}, 1)

  while true:
    redraw(s, nb)

    let selectorEvents = selector.select(-1)
    for ev in selectorEvents:
      let data = selector.getData(ev.fd)
      case data
      of 0:
        events = @[]
        while true:
          let nextEvent = nb.peekEvent(0)
          if nextEvent.kind == EventType.None:
            break
          else:
            events.add(nextEvent)

        for event in events:
          case s.modeInfo.mode
          # Input bool mode: Only allow y/n
          of MdInputBool:
            case event.kind
            of EventType.Key:
              case event.sym
              of Symbol.Escape:
                s.modeInfo = ModeInfo(mode: MdNormal)
              of Symbol.Character:
                case event.ch
                of 'y', 'Y', 'n', 'N':
                  let yes = event.ch == 'y' or event.ch == 'Y'
                  withoutNimBox(nb):
                    case s.modeInfo.boolAction:
                    of IBADelete:
                      let pwdBackup = paths.getCurrentDir()
                      deleteEntries(s.selected, yes)
                      s.selected.clear()
                      s.safeSetCurDir(pwdBackup)
                      s.rescan()

                  s.modeInfo = ModeInfo(mode: MdNormal)
                else:
                  discard
              else:
                discard
            else:
              discard
          # Input text mode: Ignore keymap
          of MdInputText:
            case processInputTextMode(event, s.modeInfo.input,
                s.modeInfo.textCursorPos)
            of PrCanceled:
              s.modeInfo = ModeInfo(mode: MdNormal)
            of PrComplete:
              withoutNimbox(nb):
                let input = s.modeInfo.input
                case s.modeInfo.textAction:
                of ITANewFile:
                  newFile(input)
                  s.rescan()
                of ITANewDir:
                  newDir(input)
                  s.rescan()
                of ITARename:
                  let relativePath = extractFilename(s.currentEntry.path)
                  rename(relativePath, input)
                  s.rescan()

              s.modeInfo = ModeInfo(mode: MdNormal)
            of PrNoAction:
              discard
          # Incremental search mode: Ignore keymap
          of MdSearch:
            case processInputTextMode(event, s.currentSearchQuery,
                s.modeInfo.searchCursorPos)
            of PrCanceled:
              s.resetTab()
            of PrComplete:
              s.modeInfo = ModeInfo(mode: MdNormal)
            of PrNoAction:
              discard

            s.refresh()
          # Normal keymap
          of MdNormal:
            case nimboxEventToAction(event, keymap):
            of AcNone: discard
            of AcQuit:
              return
            of AcShell:
              let cwdBackup = paths.getCurrentDir()
              withoutNimbox(nb):
                spawnShell()
              s.safeSetCurDir(cwdBackup)
              s.rescan()
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
              s.left()
            of AcRight:
              s.right()
            of AcHomeDir:
              let
                cd = paths.getCurrentDir()
                home = Path(getHomeDir())
              if cd != home:
                s.safeSetCurDir(home)
                s.currentIndex = 0
                s.rescan()
            of AcNewTab:
              s.tabs.add(Tab(cd: paths.getCurrentDir(),
                             index: s.currentIndex,
                             searchQuery: ""))
              s.switchTab(s.tabs.high)
            of AcCloseTab:
              if s.tabs.len > 1:
                s.tabs.del(s.currentTab)
              s.switchTab(max(0, s.currentTab - 1))
            of AcNextTab:
              if s.currentTab < s.tabs.high:
                s.switchTab(s.currentTab + 1)
              else:
                s.switchTab(0)
            of AcTab1:
              s.switchTab(0)
            of AcTab2:
              s.switchTab(1)
            of AcTab3:
              s.switchTab(2)
            of AcTab4:
              s.switchTab(3)
            of AcTab5:
              s.switchTab(4)
            of AcTab6:
              s.switchTab(5)
            of AcTab7:
              s.switchTab(6)
            of AcTab8:
              s.switchTab(7)
            of AcTab9:
              s.switchTab(8)
            of AcTab10:
              s.switchTab(9)
            of AcEdit:
              if not s.empty:
                if s.currentEntry.info.kind == pcFile:
                  withoutNimbox(nb):
                    editFile(s.currentEntry.path)
                  s.rescan()
            of AcPager:
              if not s.empty:
                if s.currentEntry.info.kind == pcFile:
                  withoutNimbox(nb):
                    viewFile(s.currentEntry.path)
            of AcNewFile:
              s.modeInfo = ModeInfo(mode: MdInputText,
                                    textAction: ITANewFile)
            of AcNewDir:
              s.modeInfo = ModeInfo(mode: MdInputText,
                                    textAction: ITANewDir)
            of AcRename:
              let relativePath = extractFilename(s.currentEntry.path)
              s.modeInfo = ModeInfo(mode: MdInputText,
                                    input: relativePath,
                                    textCursorPos: relativePath.len,
                                    textAction: ITARename)
            of AcCopySelected:
              withoutNimbox(nb):
                copyEntries(s.selected)
              s.selected.clear()
              s.rescan()
            of AcMoveSelected:
              let pwdBackup = paths.getCurrentDir()
              withoutNimbox(nb):
                moveEntries(s.selected)
              s.selected.clear()
              s.safeSetCurDir(pwdBackup)
              s.rescan()
            of AcDeleteSelected:
              s.modeInfo = ModeInfo(mode: MdInputBool,
                                    boolAction: IBADelete)
            of AcSearch:
              s.modeInfo = ModeInfo(mode: MdSearch,
                                    searchCursorPos: s.currentSearchQuery.len)
            of AcEndSearch:
              s.currentSearchQuery = ""
              s.refresh()
      of 1:
        var
          evs = newSeq[byte](8192)
          rescan = false
        let n = read(s.inotifyHandle, evs[0].addr, evs.len)
        for e in inotify_events(evs[0].addr, n):
          if e.mask != IN_IGNORED: rescan = true
        if rescan: s.rescan()
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

  let enable256Colors = existsEnv("NIMMM_256")
  var nb = newNb(enable256Colors)
  addQuitProc(proc () {.noconv.} = nb.shutdown())
  mainLoop(nb)
