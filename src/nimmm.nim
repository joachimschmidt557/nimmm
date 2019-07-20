import os, osproc, sequtils, strutils, re, sets, nimbox, options

import scan, draw, fsoperations, interactions
            
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
    let process = startProcess(getEnv("SHELL", fallback),
        options = {poUsePath, poParentStreams, poInteractive})
    let exitCode = process.waitForExit()
    process.close()
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
    var nb = newNimbox()
    addQuitProc(proc () {.noconv.} = nb.shutdown())
    mainLoop(nb)