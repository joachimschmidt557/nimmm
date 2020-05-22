import os, osproc, nimbox, sets, sequtils

import interactions, nimboxext

proc editFile*(file: string, nb: var Nimbox) =
  const
    fallback = "vi"
  let
    editor = getEnv("EDITOR", fallback)
    cmd = quoteShellCommand(@[editor, file])
  nb.shutdown()
  discard execShellCmd(cmd)
  nb = newNb()

proc viewFile*(file: string, nb: var Nimbox) =
  const
    fallback = "less"
  let
    pager = getEnv("PAGER", fallback)
    cmd = quoteShellCommand(@[pager, file])
  nb.shutdown()
  discard execShellCmd(cmd)
  nb = newNb()

proc openFile*(file: string) =
  const
    fallback = "xdg-open"
  let
    opener = getEnv("NIMMM_OPEN", fallback)
  discard startProcess(opener,
      args = @[file],
      options = {poStdErrToStdOut, poUsePath})

proc copyEntries*(entries: HashSet[string], nb: var Nimbox) =
  const
    cp = @["cp", "-r", "-i"]
  if entries.len < 1: return
  nb.shutdown()
  let
    files = toSeq(entries.items)
    dest = @[getCurrentDir()]
    cmd = quoteShellCommand(cp & files & dest)
  discard execShellCmd(cmd)
  nb = newNb()

proc moveEntries*(entries: HashSet[string], nb: var Nimbox) =
  const
    mv = @["mv", "-i"]
  if entries.len < 1: return
  nb.shutdown()
  let
    files = toSeq(entries.items)
    dest = @[getCurrentDir()]
    cmd = quoteShellCommand(mv & files & dest)
  discard execShellCmd(cmd)
  nb = newNb()

proc deleteEntries*(entries: HashSet[string], nb: var Nimbox) =
  const
    rm = @["rm", "-r", "-i"]
  if entries.len < 1: return
  nb.shutdown()
  let
    files = toSeq(entries.items)
    force = if askYorN("use force? [y/n]", nb): @["-f"] else: @[]
    cmd = quoteShellCommand(rm & force & files)
  discard execShellCmd(cmd)
  nb = newNb()

proc newFile*(nb: var Nimbox) =
  const
    touch = "touch"
  nb.shutdown()
  let
    name = askString(" -> " & touch & " ", nb)
    cmd = quoteShellCommand(@[touch, name])
  discard execShellCmd(cmd)
  nb = newNb()

proc newDir*(nb: var Nimbox) =
  const
    mkdir = "mkdir"
  nb.shutdown()
  let
    name = askString(" -> " & mkdir & " ", nb)
    cmd = quoteShellCommand(@[mkdir, name])
  discard execShellCmd(cmd)
  nb = newNb()

proc rename*(path: string, nb: var Nimbox) =
  const
    rename = "mv"
  nb.shutdown()
  let
    oldName = path
    newName = askString(" -> " & rename & oldName & " ", nb, oldName)
    cmd = quoteShellCommand(@[rename, oldName, newName])
  discard execShellCmd(cmd)
  nb = newNb()

