import os, terminal, osproc, algorithm, times, strformat, sequtils, strutils, re, sets, noise

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

proc getTopIndex(lenEntries:int, index:int): int =
    let
        entriesHeight = terminalHeight() - 4
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

proc getBottomIndex(lenIndexes:int, topIndex:int): int =
    let
        entriesHeight = terminalHeight() - 4
    # Terminal window is very small
    if entriesHeight <= 0:
        result = topIndex
    else:
        result = min(lenIndexes - 1, topIndex + entriesHeight - 1)

proc getEmptyLines(lenEntries:int): int = 
    let
        entriesHeight = terminalHeight() - 4
    # Leave space for the "Empty directory" line
    if lenEntries == 0:
        result = entriesHeight - 1
    elif lenEntries >= entriesHeight:
        result = 0
    else:
        result = entriesHeight - lenEntries

proc formatPath(path:string, length:int): string =
    if path.len <= length:
        result = path
    else:
        result = path
        result.setLen(length)

proc drawDirEntry(entry:DirEntry, highlight:bool, selected:bool) =
    const
        paddingLeft = 32
    let
        isDir = entry.info.kind == pcDir
        pathWidth = terminalWidth() - paddingLeft
    if isDir: stdout.setStyle({styleBright})
    stdout.styledWriteLine(
        (if highlight: bgWhite else: bgBlack),
        (if highlight:
            fgBlack elif isDir: 
            fgYellow else:
            fgWhite),
        (if highlight: " -> " else: "    ") &
        (if selected: "+ " else: "  ") &
        (entry.info.lastWriteTime.format("yyyy-MM-dd HH:mm")) &
        " " &
        (if isDir:
            "       /" else: sizeToString(entry.info.size)) &
        " " &
        entry.relative.formatPath(pathWidth))

proc drawHeader(tabs:seq[Tab], currentTab:int) =
    stdout.styledWrite(fgYellow, "nimmm ")
    if tabs.len > 1:
        for i in tabs.low .. tabs.high:
            if i == currentTab:
                stdout.styledWrite(fgYellow, styleBright, $(i+1) & " ")
            else:
                stdout.write($(i+1) & " ")
    stdout.styledWriteLine(fgYellow, styleBright, getCurrentDir())
    stdout.writeLine("")

proc drawFooter(index:int, lenEntries:int, lenSelected:int, hidden:bool, errMsg:string) = 
    stdout.writeLine("")
    stdout.styledWrite(fgYellow, 
        $(index + 1) &
        "/" &
        $lenEntries)
    if hidden:
        stdout.styledWrite(fgYellow, styleBright, " H")
    if lenSelected > 0: 
        stdout.styledWrite(fgYellow,
            " " & $lenSelected & " selected")
    if errMsg.len > 0:
        stdout.styledWrite(fgRed, styleBright, " " & errMsg)
 
proc redraw(entries:seq[DirEntry], index:int, selectedEntries:HashSet[string], tabs:seq[Tab], currentTab:int, hidden:bool, errMsg:string) =
    eraseScreen(stdout)
    setCursorXPos(0)
    let
        topIndex = getTopIndex(entries.len, index)
        bottomIndex = getBottomIndex(entries.len, topIndex)
        emptyLines = getEmptyLines(entries.len)

    if terminalHeight() > 4:
        drawHeader(tabs, currentTab)
   
    if entries.len < 1:
        stdout.styledWriteLine(fgYellow, "Empty directory")
    for i in topIndex .. bottomIndex:
        let entry = entries[i]
        drawDirEntry(entry,
                    (i == index),
                    (selectedEntries.contains(entry.path)))

    for i in 1 .. emptyLines:
        stdout.writeLine("")

    if terminalHeight() > 4:
        drawFooter(index, entries.len, selectedEntries.len,
                   hidden, errMsg)

proc getIndexOfDir(entries:seq[DirEntry], dir:string): int =
    for i in entries.low .. entries.high:
        if entries[i].path == dir:
            return i
    return 0

proc scan(showHidden:bool): seq[DirEntry] =
    for kind, path in walkDir(getCurrentDir()):
        if showHidden or not isHidden(path):
            result.add(DirEntry(path:path,
                info:getFileInfo(path),
                relative:extractFilename(path)))
    result.sort do (x, y: DirEntry) -> int:
        cmpIgnoreCase(x.path, y.path)

proc search(pattern:string): seq[DirEntry] =
    let
        regex = re(pattern)
    for kind, path in walkDir(getCurrentDir()):
        let
            relative = extractFilename(path)
        if relative.match(regex):
            result.add(DirEntry(path:path,
                info:getFileInfo(path),
                relative:relative))
    result.sort do (x, y: DirEntry) -> int:
        cmpIgnoreCase(x.path, y.path)

proc askYorN(question:string): bool =
    stdout.write(question)
    while true:
        case getCh():
            of 'y', 'Y':
                result = true
                break
            of 'n', 'N':
                result = false
                break
            else:
                continue

proc askString(question:string, preload=""): string =
    stdout.showCursor()
    setCursorXPos(0)

    var noise = Noise.init()
    noise.preloadBuffer(preload)    
    noise.setPrompt(question)
    let ok = noise.readLine()
    stdout.hideCursor()

    if not ok: return ""
    return noise.getLine
            
proc spawnShell() =
    const
        fallback = "/bin/sh"
    showCursor(stdout)
    stdout.writeLine("")
    stdout.writeLine("")
    stdout.writeLine(r"  /\^/\^/\^/\ ")
    stdout.writeLine(r" #############")
    stdout.writeLine(r" ### nimmm ###")
    stdout.writeLine(r" #############")
    stdout.writeLine("")
    discard execCmd(getEnv("SHELL", fallback))
    hideCursor(stdout)

proc safePath(path:string):string = 
    "\"" & path & "\""

proc editFile(file:string) =
    const
        fallback = "vi"
    showCursor(stdout)
    discard execCmd(getEnv("EDITOR", fallback) & " " & file)
    hideCursor(stdout)

proc viewFile(file:string) =
    const
        fallback = "/bin/less"
    showCursor(stdout)
    discard execCmd(getEnv("PAGER", fallback) & " " & file)
    hideCursor(stdout)

proc openFile(file:string) =
    const
        fallback = "xdg-open"
    let
        opener = getEnv("NIMMM_OPEN", fallback)
    discard startProcess(opener & " " & file,
        options = {poStdErrToStdOut, poUsePath, poEvalCommand})

proc copyEntries(entries:HashSet[string]) =
    const
        prog = "cp"
        args = " -r -i "
    if entries.len < 1: return
    showCursor(stdout)
    let
        entriesSeq = toSeq(entries.items)
        paths = entriesSeq.map(safePath)
        files = paths.foldl(a & " " & b)
        dest  = getCurrentDir().safePath
        cmd = prog & args & files & " " & dest
    stdout.writeLine("")
    stdout.writeLine(" -> " & cmd)
    discard execCmd(cmd)
    hideCursor(stdout)

proc deleteEntries(entries:HashSet[string]) =
    const
        prog = "rm"
        args = " -r -i "
    if entries.len < 1: return
    showCursor(stdout)
    let
        entriesSeq = toSeq(entries.items)
        paths = entriesSeq.map(safePath)
        files = paths.foldl(a & " " & b)
        force = if askYorN("use force? [y/n]"): "-f " else: " "
        cmd = prog & args & force & files
    stdout.writeLine("")
    stdout.writeLine(" -> " & cmd)
    discard execCmd(cmd)
    hideCursor(stdout)

proc moveEntries(entries:HashSet[string]) =
    const
        prog = "mv"
        args = " -i "
    if entries.len < 1: return
    showCursor(stdout)
    let
        entriesSeq = toSeq(entries.items)
        paths = entriesSeq.map(safePath)
        files = paths.foldl(a & " " & b)
        dest  = getCurrentDir().safePath
        cmd = prog & args & files & " " & dest
    stdout.writeLine("")
    stdout.writeLine(" -> " & cmd)
    discard execCmd(cmd)
    hideCursor(stdout)

proc newFile() =
    const
        cmd = "touch "
    let
        name = askString(" -> " & cmd)
    discard execCmd(cmd & name)

proc newDir() =
    const
        cmd = "mkdir "
    let
        name = askString(" -> " & cmd)
    discard execCmd(cmd & name)

proc rename(path:string) =
    const
        cmd = "mv "
    let
        newName = askString(" -> " & cmd & path & " ", path)
    discard execCmd(cmd & path & " " & newName)

proc startSearch(): seq[DirEntry] =
    let
        pattern = askString(" /")
    result = search(pattern)

proc mainLoop() =
    var
        showHidden = false
        currentIndex = 0
        currentDirEntries:seq[DirEntry]
        currentEntry:DirEntry
        selectedEntries = initSet[string]()
        tabs:seq[Tab]
        currentTab = 0
        err = ""

    proc refresh() =
        currentDirEntries = scan(showHidden)
        if currentDirEntries.len > 0:
            if currentIndex < 0:
                currentIndex = 0
            elif currentIndex > currentDirEntries.high:
                currentIndex = currentDirEntries.high
        else:
            currentIndex = -1
        err = ""
         
    proc switchTab(index:int) =
        if index < tabs.len:
            currentTab = index
            setCurrentDir(tabs[currentTab].cd)
            currentIndex = tabs[currentTab].index
            refresh()
 
    tabs.add(Tab(cd:getCurrentDir(), index:0))
    refresh()
    while true:
        if currentDirEntries.len > 0:
            currentEntry = currentDirEntries[currentIndex]
        tabs[currentTab].cd = getCurrentDir()
        tabs[currentTab].index = currentIndex
        redraw(currentDirEntries, currentIndex, selectedEntries,
               tabs, currentTab, showHidden, err)
        case getch():
            of 'q':
                break
            of '!':
                spawnShell()
                refresh()
            of '.':
                showHidden = not showHidden
                refresh()
            of ' ':
                if currentIndex >= 0:
                    if not selectedEntries.contains(currentEntry.path):
                        selectedEntries.incl(currentEntry.path)
                    else:
                        selectedEntries.excl(currentEntry.path)
            of 'a':
                if currentIndex >= 0:
                    for entry in currentDirEntries:
                        selectedEntries.incl(entry.path)
            of 's':
                selectedEntries.clear()
            of 'g':
                currentIndex = 0
            of 'G':
                currentIndex = currentDirEntries.high
            of 'j':
                inc currentIndex
                if currentIndex > currentDirEntries.high:
                    currentIndex = 0
            of 'k':
                dec currentIndex
                if currentIndex < 0:
                    currentIndex = currentDirEntries.high
            of 'h':
                let prevDir = getCurrentDir()
                if parentDir(getCurrentDir()) == "":
                    setCurrentDir("/")
                else:
                    setCurrentDir(parentDir(getCurrentDir()))
                refresh()
                currentIndex = getIndexOfDir(currentDirEntries, prevDir)
            of 'l':
                if currentIndex >= 0:
                    if currentEntry.info.kind == pcDir:
                        let prev = getCurrentDir()
                        try:
                            setCurrentDir(currentEntry.path)
                            refresh()
                            currentIndex = 0
                        except:
                            err = "Cannot open directory"
                            setCurrentDir(prev)
                    elif currentEntry.info.kind == pcFile:
                        openFile(currentEntry.path)
            of '~':
                setCurrentDir(getHomeDir())
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
                    if currentEntry.info.kind == pcFile:
                        editFile(currentEntry.path)
            of 'p':
                if currentIndex >= 0:
                    if currentEntry.info.kind == pcFile:
                        viewFile(currentEntry.path)
            of 'f':
                newFile()
                refresh()
            of 'd':
                newDir()
                refresh()
            of 'r':
                rename(currentEntry.relative)
                refresh()
            of 'P':
                copyEntries(selectedEntries)
                selectedEntries.clear()
                refresh()
            of 'V':
                moveEntries(selectedEntries)
                selectedEntries.clear()
                refresh()
            of 'X':
                deleteEntries(selectedEntries)
                selectedEntries.clear()
                refresh()
            of '/':
                currentDirEntries = startSearch()
                currentIndex = 0
            else:
                continue

when isMainModule:
    hideCursor(stdout)
    addQuitProc(proc () {.noconv.} = showCursor(stdout))
    addQuitProc(resetAttributes)
    mainLoop()
