import os, osproc, algorithm, times, strformat, sequtils, strutils, re, sets, noise, nimbox, options

type
    DirEntry = object
        path: string
        relative: string
        info: FileInfo
    Tab = object
        cd: string
        index: int

proc sizeToString(size:BiggestInt): string =
    let siz = size.int
    const
        k = 1024
        m = k * 1024
        g = m * 1024
        t = g * 1024
    if size < k:
        result = fmt"{siz:7}" & "B"
    elif size < m:
        result = fmt"{siz/k:7}" & "K"
    elif size < g:
        result = fmt"{siz/m:7}" & "M"
    elif size < t:
        result = fmt"{siz/g:7}" & "G"
    else:
        result = fmt"{siz/t:7}" & "T"

proc getTopIndex(lenEntries:int, index:int, nb:Nimbox): int =
    let
        entriesHeight = nb.height() - 4
        halfEntriesHeight = entriesHeight div 2
    # Terminal window is very small, only
    # draw one item
    if entriesHeight <= 0:
        result = index
    # All entries fit onto the screen
    elif lenEntries <= entriesHeight:
        result = 0
    # Top
    elif index < halfEntriesHeight:
        result = 0
    # Bottom
    elif index >= (lenEntries - halfEntriesHeight):
        result = lenEntries - entriesHeight
    # Middle
    else:
        result = index - halfEntriesHeight

proc getBottomIndex(lenIndexes:int, topIndex:int, nb:Nimbox): int =
    let
        entriesHeight = nb.height() - 4
    # Terminal window is very small; only
    # show one row
    if entriesHeight <= 0:
        result = topIndex
    else:
        result = min(lenIndexes - 1, topIndex + entriesHeight - 1)

proc formatPath(path:string, length:int): string =
    if path.len <= length:
        result = path
    else:
        result = path
        result.setLen(length)

proc getFgColor(entry:DirEntry):Color =
    if entry.info.kind == pcDir:
        clrYellow
    elif entry.info.kind == pcLinkToDir or
         entry.info.kind == pcLinkToFile:
        clrBlue
    elif fpOthersExec in entry.info.permissions or
         fpUserExec in entry.info.permissions or
         fpGroupExec in entry.info.permissions:
        clrGreen
    else:
        clrWhite

proc drawDirEntry(entry:DirEntry, y:int, highlight:bool, selected:bool, nb:var Nimbox) =
    const
        paddingLeft = 32
    let
        isDir = entry.info.kind == pcDir or
                entry.info.kind == pcLinkToDir
        pathWidth = nb.width() - paddingLeft
    nb.print(0, y,
        (if highlight: " -> " else: "    ") &
        (if selected: "+ " else: "  ") &
        (entry.info.lastWriteTime.format("yyyy-MM-dd HH:mm")) &
        " " &
        (if isDir:
            "       /" else: sizeToString(entry.info.size)) &
        " " &
        entry.relative.formatPath(pathWidth),
        (if highlight: clrBlack else: getFgColor(entry)),
        (if highlight: clrWhite else: clrBlack),
        (if highlight or isDir: styBold else: styNone))

proc drawHeader(numTabs:int, currentTab:int, nb:var Nimbox) =
    let
        offsetCd = 6 + (if numTabs > 1: 2*numTabs else: 0)
    nb.print(0, 0, "nimmm ", clrYellow, clrDefault, styNone)
    if numTabs > 1:
        for i in 1 .. numTabs:
            if i == currentTab+1:
                nb.print(6+2*(i-1), 0, $(i) & " ", clrYellow, clrDefault, styBold)
            else:
                nb.print(6+2*(i-1), 0, $(i) & " ")
    nb.print(offsetCd, 0, getCurrentDir(), clrYellow, clrDefault, styBold)

proc drawFooter(index:int, lenEntries:int, lenSelected:int, hidden:bool, errMsg:string, nb:var Nimbox) = 
    let
        y = nb.height() - 1
        entriesStr = $(index + 1) & "/" & $lenEntries
        selectedStr = " " & $lenSelected & " selected"
        offsetH = entriesStr.len
        offsetSelected = offsetH + (if hidden: 2 else: 0)
        offsetErrMsg = offsetSelected + (if lenSelected > 0: selectedStr.len else: 0)
    nb.print(0, y, entriesStr, clrYellow)
    if hidden:
        nb.print(offsetH, y, " H", clrYellow, clrDefault, styBold)
    if lenSelected > 0: 
        nb.print(offsetSelected, y, selectedStr)
    if errMsg.len > 0:
        nb.print(offsetErrMsg, y, " " & errMsg, clrRed)
 
proc redraw(entries:seq[DirEntry], index:int, selectedEntries:HashSet[string], tabs:seq[Tab], currentTab:int, hidden:bool, errMsg:string, nb:var Nimbox) =
    nb.clear()
    let
        topIndex = getTopIndex(entries.len, index, nb)
        bottomIndex = getBottomIndex(entries.len, topIndex, nb)

    if nb.height() > 4:
        drawHeader(tabs.len, currentTab, nb)
   
    if entries.len < 1:
        nb.print(0, 2, "Empty directory", clrYellow)
    for i in topIndex .. bottomIndex:
        let entry = entries[i]
        drawDirEntry(entry,
                    i-topIndex+2,
                    (i == index),
                    (selectedEntries.contains(entry.path)),
                    nb)

    if nb.height() > 4:
        drawFooter(index, entries.len, selectedEntries.len,
                   hidden, errMsg, nb)

    nb.present()

proc getIndexOfDir(entries:seq[DirEntry], dir:string): int =
    let
        paths = entries.mapIt(it.path)
    result = paths.binarySearch(dir, cmpIgnoreCase)
    if result < 0: result = 0

proc scan(showHidden:bool): tuple[entries: seq[DirEntry], error: bool] =
    var
        error = false
        entries:seq[DirEntry]
    for kind, path in walkDir(getCurrentDir()):
        if showHidden or not isHidden(path):
            try:
                entries.add(DirEntry(path:path,
                    info:getFileInfo(path),
                    relative:extractFilename(path)))
            except:
                error = true
    entries.sort do (x, y: DirEntry) -> int:
        cmpIgnoreCase(x.path, y.path)
    return (entries, error)

proc search(pattern:string, showHidden:bool): tuple[entries: seq[DirEntry], error:bool] =
    let
        regex = re(pattern)
    var
        error = false
        entries:seq[DirEntry]
    for kind, path in walkDir(getCurrentDir()):
        let
            relative = extractFilename(path)
        if relative.match(regex):
            if showHidden or not isHidden(path):
                try:
                    entries.add(DirEntry(path:path,
                        info:getFileInfo(path),
                        relative:relative))
                except:
                    error = true
    entries.sort do (x, y: DirEntry) -> int:
        cmpIgnoreCase(x.path, y.path)
    return (entries, error)

proc askYorN(question:string, nb:var Nimbox): bool =
    stdout.write(question)
    while true:
        case getCh():
            of 'y', 'Y':
                return true
            of 'n', 'N':
                return false
            else:
                continue

proc askString(question:string, nb:var Nimbox, preload=""): string =
    var noise = Noise.init()
    noise.preloadBuffer(preload)    
    noise.setPrompt(question)
    let ok = noise.readLine()

    if not ok: return ""
    return noise.getLine
            
proc spawnShell(nb:var Nimbox) =
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
    discard execCmd(getEnv("SHELL", fallback))
    nb = newNimbox()

proc safePath(path:string):string = 
    "\"" & path & "\""

proc editFile(file:string, nb:var Nimbox) =
    const
        fallback = "vi"
    nb.shutdown()
    discard execCmd(getEnv("EDITOR", fallback) & " " & file)
    nb = newNimbox()

proc viewFile(file:string, nb:var Nimbox) =
    const
        fallback = "/bin/less"
    nb.shutdown()
    discard execCmd(getEnv("PAGER", fallback) & " " & file)
    nb = newNimbox()

proc openFile(file:string) =
    const
        fallback = "xdg-open"
    let
        opener = getEnv("NIMMM_OPEN", fallback)
    discard startProcess(opener & " " & file,
        options = {poStdErrToStdOut, poUsePath, poEvalCommand})

proc copyEntries(entries:HashSet[string], nb: var Nimbox) =
    const
        prog = "cp"
        args = " -r -i "
    if entries.len < 1: return
    nb.shutdown()
    let
        entriesSeq = toSeq(entries.items)
        paths = entriesSeq.map(safePath)
        files = paths.foldl(a & " " & b)
        dest  = getCurrentDir().safePath
        cmd = prog & args & files & " " & dest
    stdout.writeLine(" -> " & cmd)
    discard execCmd(cmd)
    nb = newNimbox()

proc deleteEntries(entries:HashSet[string], nb:var Nimbox) =
    const
        prog = "rm"
        args = " -r -i "
    if entries.len < 1: return
    nb.shutdown()
    let
        entriesSeq = toSeq(entries.items)
        paths = entriesSeq.map(safePath)
        files = paths.foldl(a & " " & b)
        force = if askYorN("use force? [y/n]", nb): "-f " else: " "
        cmd = prog & args & force & files
    stdout.writeLine(" -> " & cmd)
    discard execCmd(cmd)
    nb = newNimbox()

proc moveEntries(entries:HashSet[string], nb: var Nimbox) =
    const
        prog = "mv"
        args = " -i "
    if entries.len < 1: return
    nb.shutdown()
    let
        entriesSeq = toSeq(entries.items)
        paths = entriesSeq.map(safePath)
        files = paths.foldl(a & " " & b)
        dest  = getCurrentDir().safePath
        cmd = prog & args & files & " " & dest
    stdout.writeLine(" -> " & cmd)
    discard execCmd(cmd)
    nb = newNimbox()

proc newFile(nb:var Nimbox) =
    const
        cmd = "touch "
    nb.shutdown()
    let
        name = askString(" -> " & cmd, nb)
    discard execCmd(cmd & name)
    nb = newNimbox()

proc newDir(nb:var Nimbox) =
    const
        cmd = "mkdir "
    nb.shutdown()
    let
        name = askString(" -> " & cmd, nb)
    discard execCmd(cmd & name)
    nb = newNimbox()

proc rename(path:string, nb:var Nimbox) =
    const
        cmd = "mv "
    nb.shutdown()
    let
        oldName = path.safePath
        newName = askString(" -> " & cmd & oldName & " ", nb, path)
    discard execCmd(cmd & oldName & " " & newName.safePath)
    nb = newNimbox()

proc startSearch(nb:var Nimbox, showHidden:bool): tuple[entries:seq[DirEntry], error:bool] =
    nb.shutdown()
    let
        pattern = askString(" /", nb)
    result = search(pattern, showHidden)
    nb = newNimbox()

proc safeSetCurDir(path:string) =
    var safeDir = path
    while not existsDir(safeDir):
        safeDir = safeDir.parentDir
    setCurrentDir(safeDir)

proc mainLoop(nb:var Nimbox) =
    var
        showHidden = false
        currentIndex = 0
        entries:seq[DirEntry]
        selectedEntries = initSet[string]()
        tabs:seq[Tab]
        currentTab = 0
        err = ""

    proc refresh() =
        var scanResult = scan(showHidden)
        err = ""
        entries = scanResult.entries
        if scanResult.error:
            err = "Some entries couldn't be displayed"
        if entries.len > 0:
            if currentIndex < 0:
                currentIndex = 0
            elif currentIndex > entries.high:
                currentIndex = entries.high
        else:
            currentIndex = -1
         
    proc switchTab(i:int) =
        if i < tabs.len:
            currentTab = i
            safeSetCurDir(tabs[currentTab].cd)
            currentIndex = tabs[currentTab].index
            refresh()

    proc up() =
        dec currentIndex
        if currentIndex < 0:
            currentIndex = entries.high

    proc down() =
        inc currentIndex
        if currentIndex > entries.high:
            currentIndex = 0

    proc left() =
        let prevDir = getCurrentDir()
        if parentDir(getCurrentDir()) == "":
            safeSetCurDir("/")
        else:
            safeSetCurDir(parentDir(getCurrentDir()))
        refresh()
        if prevDir != "/":
            currentIndex = getIndexOfDir(entries, prevDir)

    proc right() =
        if currentIndex >= 0:
            if entries[currentIndex].info.kind == pcDir:
                let prev = getCurrentDir()
                try:
                    safeSetCurDir(entries[currentIndex].path)
                    refresh()
                    currentIndex = 0
                except:
                    err = "Cannot open directory"
                    safeSetCurDir(prev)
            elif entries[currentIndex].info.kind == pcFile:
                openFile(entries[currentIndex].path)

    # Initialize first tab
    tabs.add(Tab(cd:getCurrentDir(), index:0))
    refresh()

    while true:
        tabs[currentTab].cd = getCurrentDir()
        tabs[currentTab].index = currentIndex
        redraw(entries, currentIndex, selectedEntries,
               tabs, currentTab, showHidden, err, nb)

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
                showHidden = not showHidden
                refresh()
            of 'a':
                if currentIndex >= 0:
                    for entry in entries:
                        selectedEntries.incl(entry.path)
            of 's':
                selectedEntries.clear()
            of 'g':
                currentIndex = 0
            of 'G':
                currentIndex = entries.high
            of 'j':
                down()
            of 'k':
                up()
            of 'h':
                left()
            of 'l':
                right()
            of '~':
                safeSetCurDir(getHomeDir())
                refresh()
                currentIndex = 0
            of 't':
                tabs.add(Tab(cd:getCurrentDir(), index:currentIndex))
                switchTab(tabs.high)
            of 'w':
                if tabs.len > 1:
                    tabs.del(currentTab)
                switchTab(max(0, currentTab - 1))
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
                if currentIndex >= 0:
                    if entries[currentIndex].info.kind == pcFile:
                        editFile(entries[currentIndex].path, nb)
                        refresh()
            of 'p':
                if currentIndex >= 0:
                    if entries[currentIndex].info.kind == pcFile:
                        viewFile(entries[currentIndex].path, nb)
            of 'f':
                newFile(nb)
                refresh()
            of 'd':
                newDir(nb)
                refresh()
            of 'r':
                rename(entries[currentIndex].relative, nb)
                refresh()
            of 'P':
                copyEntries(selectedEntries, nb)
                selectedEntries.clear()
                refresh()
            of 'V':
                moveEntries(selectedEntries, nb)
                selectedEntries.clear()
                refresh()
            of 'X':
                deleteEntries(selectedEntries, nb)
                selectedEntries.clear()
                refresh()
            of '/':
                let result = startSearch(nb, showHidden)
                entries = result.entries
                if result.error:
                    err = "Some entries could not be displayed."
                currentIndex = 0
            else:
                discard
            case event.sym:
            of Enter:
                right()
            of Backspace:
                left()
            of Space:
                if currentIndex >= 0:
                    if not selectedEntries.contains(entries[currentIndex].path):
                        selectedEntries.incl(entries[currentIndex].path)
                    else:
                        selectedEntries.excl(entries[currentIndex].path)
            of Up:
                up()
            of Down:
                down()
            of Symbol.Left:
                left()
            of Symbol.Right:
                right()
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
    var nb = newNimbox()
    addQuitProc(proc () {.noconv.} = nb.shutdown())
    mainLoop(nb)