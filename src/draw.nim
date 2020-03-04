import times, sets, os, strformat, nimbox, strutils, sequtils, algorithm, options

import lscolors
import lscolors/style

import core, nimboxext

proc sizeToString(size: BiggestInt): string =
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

proc getIndexOfDir*(entries: seq[DirEntry], dir: string): int =
  let
    paths = entries.mapIt(it.path)
  result = paths.binarySearch(dir, cmpIgnoreCase)
  if result < 0: result = 0

proc getTopIndex(lenEntries: int, index: int, nb: Nimbox): int =
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

proc getBottomIndex(lenIndexes: int, topIndex: int, nb: Nimbox): int =
  let
    entriesHeight = nb.height() - 4
  # Terminal window is very small; only
  # show one row
  if entriesHeight <= 0:
    result = topIndex
  else:
    result = min(lenIndexes - 1, topIndex + entriesHeight - 1)

proc formatPath(path: string, length: int): string =
  if path.len <= length:
    result = path
  else:
    result = path
    result.setLen(length)

proc lsColorToNimboxColor(c: style.Color): nimbox.Color =
  case c.kind
  of ck8:
    case c.ck8Val
    of c8Black: return clrBlack
    of c8Red: return clrRed
    of c8Green: return clrGreen
    of c8Yellow: return clrYellow
    of c8Blue: return clrBlue
    of c8Magenta: return clrMagenta
    of c8Cyan: return clrCyan
    of c8White: return clrWhite
  else: return clrWhite

proc lsColorToNimboxColors256(c: style.Color): Option[nimbox.Colors256] =
  case c.kind
  of ckFixed:
    return some nimbox.Colors256(int(c.ckFixedVal))
  else: return none nimbox.Colors256

proc getFgColor(entry: DirEntry, lsc: LsColors): nimbox.Color =
  let
    sty = lsc.styleForPath(entry.path)
  if sty.fg.isSome:
    sty.fg.get.lsColorToNimboxColor()
  else:
    clrWhite

proc getFgColors256(entry: DirEntry, lsc: LsColors): Option[nimbox.Colors256] =
  let
    sty = lsc.styleForPath(entry.path)
  if sty.fg.isSome:
    sty.fg.get.lsColorToNimboxColors256()
  else:
    none nimbox.Colors256

proc lsColorToNimboxStyle(sty: style.Style): nimbox.Style =
  let font = sty.font

  if font.bold: styBold
  elif font.underline: styUnderline
  else: styNone

proc getStyle(entry: DirEntry, lsc: LsColors): nimbox.Style =
  let
    sty = lsc.styleForPath(entry.path)
  sty.lsColorToNimboxStyle()

proc drawDirEntry(entry: DirEntry, y: int, highlight: bool, selected: bool,
    lsc: LsColors, nb: var Nimbox) =
  const
    paddingLeft = 32
  let
    isDir = entry.info.kind == pcDir or
            entry.info.kind == pcLinkToDir
    pathWidth = nb.width() - paddingLeft
    line = (if highlight: " -> " else: "    ") &
      (if selected: "+ " else: "  ") &
      (entry.info.lastWriteTime.format("yyyy-MM-dd HH:mm")) &
      " " &
      (if isDir: "       /" else: sizeToString(entry.info.size)) &
      " " &
      entry.relative.formatPath(pathWidth)
  if getFgColors256(entry, lsc).isSome:
    let
      fg = if highlight: fgBlack() else: getFgColors256(entry, lsc).get
      bg = if highlight: c8(clrWhite) else: c8(clrBlack)
      style = if highlight: styBold else: getStyle(entry, lsc)
    nb.print(0, y, line, fg, bg, style)
  else:
    nb.print(0, y, line,
      (if highlight: fgBlack() else: c8(getFgColor(entry, lsc))),
      (if highlight: c8(clrWhite) else: c8(clrBlack)),
      (if highlight: styBold else: getStyle(entry, lsc)))

proc drawHeader(numTabs: int, currentTab: int, nb: var Nimbox) =
  let
    offsetCd = 6 + (if numTabs > 1: 2*numTabs else: 0)
  nb.print(0, 0, "nimmm ", c8(clrYellow), c8(clrBlack), styNone)
  if numTabs > 1:
    for i in 1 .. numTabs:
      if i == currentTab+1:
        nb.print(6+2*(i-1), 0, $(i) & " ", c8(clrYellow), c8(clrBlack), styBold)
      else:
        nb.print(6+2*(i-1), 0, $(i) & " ")
  nb.print(offsetCd, 0, getCurrentDir(), c8(clrYellow), c8(clrBlack), styBold)

proc drawFooter(index: int, lenEntries: int, lenSelected: int, hidden: bool,
    errMsg: string, nb: var Nimbox) =
  let
    y = nb.height() - 1
    entriesStr = $(index + 1) & "/" & $lenEntries
    selectedStr = " " & $lenSelected & " selected"
    offsetH = entriesStr.len
    offsetSelected = offsetH + (if hidden: 2 else: 0)
    offsetErrMsg = offsetSelected + (if lenSelected >
        0: selectedStr.len else: 0)
  nb.print(0, y, entriesStr, c8(clrYellow), c8(clrBlack))
  if hidden:
    nb.print(offsetH, y, " H", c8(clrYellow), c8(clrBlack), styBold)
  if lenSelected > 0:
    nb.print(offsetSelected, y, selectedStr)
  if errMsg.len > 0:
    nb.print(offsetErrMsg, y, " " & errMsg, c8(clrRed), c8(clrBlack))

proc redraw*(s: State, errMsg: string, nb: var Nimbox, lsc: LsColors) =
  let
    topIndex = getTopIndex(s.entries.len, s.currentIndex, nb)
    bottomIndex = getBottomIndex(s.entries.len, topIndex, nb)

  nb.clear()
  if nb.height() > 4:
    drawHeader(s.tabs.len, s.currentTab, nb)

  if s.entries.len < 1:
    nb.print(0, 2, "Empty directory", c8(clrYellow), c8(clrBlack))
  for i in topIndex .. bottomIndex:
    let entry = s.entries[i]
    drawDirEntry(entry,
                i-topIndex+2,
                (i == s.currentIndex),
                (s.selected.contains(entry.path)),
                lsc,
                nb)

  if nb.height() > 4:
    drawFooter(s.currentIndex, s.entries.len, s.selected.len,
               s.showHidden, errMsg, nb)

  nb.present()

