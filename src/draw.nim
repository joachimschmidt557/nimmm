import times, sets, os, strformat, nimbox, strutils, sequtils, algorithm

import core

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

proc getIndexOfDir*(entries:seq[DirEntry], dir:string): int =
    let
        paths = entries.mapIt(it.path)
    result = paths.binarySearch(dir, cmpIgnoreCase)
    if result < 0: result = 0

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
 
proc redraw*(s:State, errMsg:string, nb:var Nimbox) =
    nb.clear()
    let
        entries = s.entries
        index = s.currentIndex
        selectedEntries = s.selected
        tabs = s.tabs
        currentTab = s.currentTab
        hidden = s.showHidden
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

