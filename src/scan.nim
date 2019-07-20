import os, re, algorithm, strutils

import core

proc scan*(showHidden:bool): tuple[entries: seq[DirEntry], error: bool] =
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

proc search*(pattern:string, showHidden:bool): tuple[entries: seq[DirEntry], error:bool] =
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

