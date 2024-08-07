import std/[times, sets, os, strformat, strutils, options]

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

proc lsColorToNimboxColor(c: style.Color): nimboxext.Color =
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

proc lsColorToNimboxColors256(c: style.Color): Option[nimboxext.Colors256] =
  case c.kind
  of ckFixed:
    return some nimboxext.Colors256(int(c.ckFixedVal))
  else: return none nimboxext.Colors256

proc getFgColor(entry: DirEntry): nimboxext.Color =
  let
    sty = entry.style
  if sty.fg.isSome:
    sty.fg.get.lsColorToNimboxColor()
  else:
    clrWhite

proc getFgColors256(entry: DirEntry): Option[nimboxext.Colors256] =
  let
    sty = entry.style
  if sty.fg.isSome:
    sty.fg.get.lsColorToNimboxColors256()
  else:
    none nimboxext.Colors256

proc lsColorToNimboxStyle(sty: style.Style): nimboxext.Style =
  let font = sty.font

  if font.bold: styBold
  elif font.underline: styUnderline
  else: styNone

proc getStyle(entry: DirEntry): nimboxext.Style =
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
      relativePath.formatPath(pathWidth)
    fgC8 = nb.c8(getFgColor(entry))
    fg = if highlight: nb.fgHighlight() else: getFgColors256(entry).get(fgC8)
    bg = if highlight: nb.c8(clrWhite) else: defaultOrBlack
    style = if highlight: styBold else: getStyle(entry)

  nb.print(0, y, line, fg, bg, style)

proc drawHeader(numTabs: int, currentTab: int, path: string, nb: var Nimbox) =
  var
    offsetCd = 6
  nb.print(0, 0, "nimmm", nb.c8(clrYellow), defaultOrBlack, styNone)
  if numTabs > 1:
    for i in 1 .. numTabs:
      let text = $i
      if i == currentTab+1:
        nb.print(offsetCd, 0, text, nb.c8(clrYellow), defaultOrBlack, styBold)
      else:
        nb.print(offsetCd, 0, text)
      offsetCd += text.len + 1 # no wcwidth necessary, only digits + 1 space
  let
    pathWidth = nb.width() - offsetCd
  nb.print(offsetCd, 0, path.formatPath(pathWidth), nb.c8(clrYellow),
      defaultOrBlack, styBold)

proc drawFooter(index: int, lenEntries: int, lenSelected: int, hidden: bool,
                searchQuery: string, message: string, nb: var Nimbox) =
  const
    searchPrefix = "search:"
    searchPrefixLen = searchPrefix.len + 1
  let
    y = nb.height() - 1
    entriesStr = $(index + 1) & "/" & $lenEntries
    selectedStr = $lenSelected & " selected"
    searchWidth = searchPrefixLen + searchQuery.wcswidth

    offsetH = entriesStr.len + 1 # no wcwidth necessary, only digits + '/'
    offsetS = offsetH + (if hidden: 2 else: 0)
    offsetSelected = offsetS + (if searchQuery.len > 0: searchWidth + 1 else: 0)
    offsetMessageLeft = offsetSelected + (if lenSelected >
        0: selectedStr.len + 1 else: 0)
    offsetMessageRight = nb.width() - message.wcswidth
    offsetMessage = max(offsetMessageLeft, offsetMessageRight)
  nb.print(0, y, entriesStr, nb.c8(clrYellow), defaultOrBlack)
  if hidden:
    nb.print(offsetH, y, "H", nb.c8(clrYellow), defaultOrBlack, styBold)
  if searchQuery.len > 0:
    nb.print(offsetS, y, searchPrefix, nb.c8(clrYellow), defaultOrBlack)
    nb.print(offsetS + searchPrefixLen, y, searchQuery)
  if lenSelected > 0:
    nb.print(offsetSelected, y, selectedStr, nb.c8(clrYellow), defaultOrBlack)
  if message.len > 0:
    nb.print(offsetMessage, y, message, nb.c8(clrYellow), defaultOrBlack)
  nb.cursor = (TB_HIDE_CURSOR, TB_HIDE_CURSOR)

proc drawInputFooter(prompt: string, query: string, cursorPos: int,
    nb: var Nimbox) =
  let
    y = nb.height() - 1
    offset = prompt.wcswidth + 1
    cursorPos = offset + query[0..cursorPos - 1].wcswidth
  nb.print(0, y, prompt, nb.c8(clrYellow), defaultOrBlack, styBold)
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
    drawHeader(s.tabs.len, s.currentTab, getCurrentDir(), nb)

  if s.visibleEntries.len < 1:
    let message =
      if s.currentSearchQuery == "":
        "Empty directory"
      else:
        "No matching results"
    nb.print(0, 2, message, nb.c8(clrYellow), defaultOrBlack)
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
                 s.showHidden, s.currentSearchQuery,
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
