import std/[os, osproc, sets, sequtils]

proc spawnShell*() =
  const
    fallback = "sh"
  stdout.writeLine("""

 /\^/\^/\^/\
#############
### nimmm ###
#############

  """)
  discard execShellCmd(getEnv("SHELL", fallback))

proc editFile*(file: string) =
  const
    fallback = "vi"
  let
    editor = getEnv("EDITOR", fallback)
    cmd = quoteShellCommand(@[editor, file])
  discard execShellCmd(cmd)

proc viewFile*(file: string) =
  const
    fallback = "less"
  let
    pager = getEnv("PAGER", fallback)
    cmd = quoteShellCommand(@[pager, file])
  discard execShellCmd(cmd)

proc openFile*(file: string) =
  const
    fallback = "xdg-open"
  let
    opener = getEnv("NIMMM_OPEN", fallback)
  discard startProcess(opener,
      args = @[file],
      options = {poStdErrToStdOut, poUsePath})

proc copyEntries*(entries: HashSet[string]) =
  const
    cp = @["cp", "-r", "-i"]
  if entries.len < 1: return
  let
    files = toSeq(entries.items)
    dest = @[getCurrentDir()]
    cmd = quoteShellCommand(cp & files & dest)
  discard execShellCmd(cmd)

proc moveEntries*(entries: HashSet[string]) =
  const
    mv = @["mv", "-i"]
  if entries.len < 1: return
  let
    files = toSeq(entries.items)
    dest = @[getCurrentDir()]
    cmd = quoteShellCommand(mv & files & dest)
  discard execShellCmd(cmd)

proc deleteEntries*(entries: HashSet[string], force: bool) =
  const
    rm = @["rm", "-r", "-i"]
  if entries.len < 1: return
  let
    files = toSeq(entries.items)
    forceFlag = if force: @["-f"] else: @[]
    cmd = quoteShellCommand(rm & forceFlag & files)
  discard execShellCmd(cmd)

proc newFile*(name: string) =
  const
    touch = "touch"
  let
    cmd = quoteShellCommand(@[touch, name])
  discard execShellCmd(cmd)

proc newDir*(name: string) =
  const
    mkdir = "mkdir"
  let
    cmd = quoteShellCommand(@[mkdir, name])
  discard execShellCmd(cmd)

proc rename*(oldName: string, newName: string) =
  const
    rename = "mv"
  let
    cmd = quoteShellCommand(@[rename, oldName, newName])
  discard execShellCmd(cmd)
