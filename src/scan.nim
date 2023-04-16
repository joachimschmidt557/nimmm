import std/[os, algorithm]

import lscolors

import core

proc scan*(lsc: LsColors): tuple[entries: seq[DirEntry], error: bool] =
  var
    error = false
    entries: seq[DirEntry]
  for kind, path in walkDir(getCurrentDir()):
    try:
      entries.add(DirEntry(path: path,
                           info: getFileInfo(path, false),
                           style: lsc.styleForPath(path)))
    except:
      error = true
  entries.sort do (x, y: DirEntry) -> int:
    cmpPaths(x.path, y.path)
  return (entries, error)
