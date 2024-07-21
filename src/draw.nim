import std/[times, sets, os, strformat, strutils, options]

import nimbox
import lscolors/style
import wcwidth

import core, nimboxext

const
  defaultOrBlack = 0

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
  result = path
  if path.len > length:
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

proc getFgColor(entry: DirEntry): nimbox.Color =
  let
    sty = entry.style
  if sty.fg.isSome:
    sty.fg.get.lsColorToNimboxColor()
  else:
    clrWhite

proc getFgColors256(entry: DirEntry): Option[nimbox.Colors256] =
  let
    sty = entry.style
  if sty.fg.isSome:
    sty.fg.get.lsColorToNimboxColors256()
  else:
    none nimbox.Colors256

proc lsColorToNimboxStyle(sty: style.Style): nimbox.Style =
  let font = sty.font

  if font.bold: styBold
  elif font.underline: styUnderline
  else: styNone

proc getStyle(entry: DirEntry): nimbox.Style =
  entry.style.lsColorToNimboxStyle()

proc drawDirEntry(entry: DirEntry, y: int, highlight: bool, selected: bool,
                  nb: var Nimbox) =
  const
    paddingLeft = 32
  let
    isDir = entry.info.kind == pcDir or
            entry.info.kind == pcLinkToDir
    pathWidth = nb.width() - paddingLeft
    relativePath = extractFilename(entry.path)
    line = (if highlight: " -> " else: "    ") &
      (if selected: "+ " else: "  ") &
      (entry.info.lastWriteTime.format("yyyy-MM-dd HH:mm")) &
      " " &
      (if isDir: "       /" else: sizeToString(entry.info.size)) &
      " " &
      relativePath
    fgC8 = c8(getFgColor(entry))
    fg = if highlight: fgHighlight() else: getFgColors256(entry).get(fgC8)
    bg = if highlight: c8(clrWhite) else: defaultOrBlack
    style = if highlight: styBold else: getStyle(entry)

  nb.print(0, y, line, fg, bg, style)

proc drawHeader(numTabs: int, currentTab: int, nb: var Nimbox) =
  let
    offsetCd = 6 + (if numTabs > 1: 2*numTabs else: 0)
  nb.print(0, 0, "nimmm ", c8(clrYellow), defaultOrBlack, styNone)
  if numTabs > 1:
    for i in 1 .. numTabs:
      if i == currentTab+1:
        nb.print(6+2*(i-1), 0, $(i) & " ", c8(clrYellow), defaultOrBlack, styBold)
      else:
        nb.print(6+2*(i-1), 0, $(i) & " ")
  nb.print(offsetCd, 0, getCurrentDir(), c8(clrYellow), defaultOrBlack, styBold)

proc drawFooter(index: int, lenEntries: int, lenSelected: int, hidden: bool,
                search: bool, errMsg: string, nb: var Nimbox) =
  let
    y = nb.height() - 1
    entriesStr = $(index + 1) & "/" & $lenEntries
    selectedStr = " " & $lenSelected & " selected"
    offsetH = entriesStr.len
    offsetS = offsetH + (if hidden: 2 else: 0)
    offsetSelected = offsetS + (if search: 2 else: 0)
    offsetErrMsg = offsetSelected + (if lenSelected >
        0: selectedStr.len else: 0)
  nb.print(0, y, entriesStr, c8(clrYellow), defaultOrBlack)
  if hidden:
    nb.print(offsetH, y, " H", c8(clrYellow), defaultOrBlack, styBold)
  if search:
    nb.print(offsetS, y, " S", c8(clrYellow), defaultOrBlack, styBold)
  if lenSelected > 0:
    nb.print(offsetSelected, y, selectedStr)
  if errMsg.len > 0:
    nb.print(offsetErrMsg, y, " " & errMsg, c8(clrRed), defaultOrBlack)
  nb.cursor = (TB_HIDE_CURSOR, TB_HIDE_CURSOR)

proc drawInputFooter(prompt: string, query: string, cursorPos: int,
    nb: var Nimbox) =
  let
    y = nb.height() - 1
    offset = prompt.wcswidth + 1
    cursorPos = offset + query[0..cursorPos - 1].wcswidth
  nb.print(0, y, prompt, c8(clrYellow), defaultOrBlack)
  nb.print(offset, y, query, defaultOrBlack, defaultOrBlack)
  nb.cursor = (cursorPos, y)

proc errMsg(err: ErrorKind): string =
  case err
  of ErrNone: ""
  of ErrCannotCd: "Cannot open directory"
  of ErrCannotShow: "Some entries couldn't be displayed"
  of ErrCannotOpen: "Cannot open file"

proc textInputPrompt(textAction: InputTextAction): string =
  case textAction
  of ITANewFile: "new file:"
  of ITANewDir: "new directory:"
  of ITARename: "rename:"

proc boolInputPrompt(boolAction: InputBoolAction): string =
  case boolAction
  of IBADelete: "use force? [y/n]:"

proc redraw*(s: State, nb: var Nimbox) =
  let
    topIndex = getTopIndex(s.visibleEntries.len, s.currentIndex, nb)
    bottomIndex = getBottomIndex(s.visibleEntries.len, topIndex, nb)
    errMsg = s.error.errMsg()

  nb.clear()
  if nb.height() > 4:
    drawHeader(s.tabs.len, s.currentTab, nb)

  if s.visibleEntries.len < 1:
    let message =
      if s.currentSearchQuery == "":
        "Empty directory"
      else:
        "No matching results"
    nb.print(0, 2, message, c8(clrYellow), defaultOrBlack)
  for i in topIndex .. bottomIndex:
    let entry = s.entries[s.visibleEntries[i]]
    drawDirEntry(entry,
                i-topIndex+2,
                (i == s.currentIndex),
                (s.selected.contains(entry.path)),
                nb)

  if nb.height() > 4:
    case s.modeInfo.mode:
    of MdNormal:
      drawFooter(s.currentIndex, s.visibleEntries.len, s.selected.len,
                 s.showHidden, s.currentSearchQuery != "",
                 errMsg, nb)
    of MdSearch:
      drawInputFooter("search:", s.currentSearchQuery,
          s.modeInfo.searchCursorPos, nb)
    of MdInputText:
      let prompt = textInputPrompt(s.modeInfo.textAction)
      drawInputFooter(prompt, s.modeInfo.input,
          s.modeInfo.textCursorPos, nb)
    of MdInputBool:
      let prompt = boolInputPrompt(s.modeInfo.boolAction)
      drawInputFooter(prompt, "", 0, nb)

  nb.present()
