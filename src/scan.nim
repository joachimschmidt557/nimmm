import os, re, algorithm, strutils

import lscolors

import core

proc scan*(showHidden: bool, lsc: LsColors): tuple[entries: seq[DirEntry], error: bool] =
  var
    error = false
    entries: seq[DirEntry]
  for kind, path in walkDir(getCurrentDir()):
    if showHidden or not isHidden(path):
      try:
        entries.add(DirEntry(path: path,
                             info: getFileInfo(path),
                             relative: extractFilename(path),
                             style: lsc.styleForPath(path)))
      except:
        error = true
  entries.sort do (x, y: DirEntry) -> int:
    cmpIgnoreCase(x.path, y.path)
  return (entries, error)

proc search*(pattern: string, showHidden: bool, lsc: LsColors): tuple[
    entries: seq[DirEntry], error: bool] =
  let
    regex = re(pattern, flags = {reStudy, reIgnoreCase})
  var
    error = false
    entries: seq[DirEntry]
  for kind, path in walkDir(getCurrentDir()):
    let
      relative = extractFilename(path)
    if relative.contains(regex):
      if showHidden or not isHidden(path):
        try:
          entries.add(DirEntry(path: path,
                               info: getFileInfo(path),
                               relative: relative,
                               style: lsc.styleForPath(path)))
        except:
          error = true
  entries.sort do (x, y: DirEntry) -> int:
    cmpIgnoreCase(x.path, y.path)
  return (entries, error)

