import os, osproc, nimbox, sets, sequtils

import interactions

proc editFile*(file:string, nb:var Nimbox) =
    const
        fallback = "vi"
    let
        editor = getEnv("EDITOR", fallback)
    nb.shutdown()
    let process = startProcess(editor,
        args = @[file],
        options = {poUsePath, poParentStreams, poInteractive})
    let exitCode = process.waitForExit()
    process.close()
    nb = newNimbox()

proc viewFile*(file:string, nb:var Nimbox) =
    const
        fallback = "less"
    let
        pager = getEnv("PAGER", fallback)
    nb.shutdown()
    let process = startProcess(pager,
        args = @[file],
        options = {poUsePath, poParentStreams, poInteractive})
    let exitCode = process.waitForExit()
    process.close()
    nb = newNimbox()

proc openFile*(file:string) =
    const
        fallback = "xdg-open"
    let
        opener = getEnv("NIMMM_OPEN", fallback)
    discard startProcess(opener,
        args = @[file],
        options = {poStdErrToStdOut, poUsePath})

proc copyEntries*(entries:HashSet[string], nb: var Nimbox) =
    const
        prog = "cp"
        args = @["-r", "-i"]
    if entries.len < 1: return
    nb.shutdown()
    let
        files = toSeq(entries.items)
        dest  = getCurrentDir()
    let process = startProcess(prog,
        args = args & files & @[dest],
        options = {poUsePath, poParentStreams, poInteractive})
    let exitCode = process.waitForExit()
    process.close()
    nb = newNimbox()

proc moveEntries*(entries:HashSet[string], nb: var Nimbox) =
    const
        prog = "mv"
        args = @["-i"]
    if entries.len < 1: return
    nb.shutdown()
    let
        files = toSeq(entries.items)
        dest  = getCurrentDir()
    let process = startProcess(prog,
        args = args & files & @[dest],
        options = {poUsePath, poParentStreams, poInteractive})
    let exitCode = process.waitForExit()
    process.close()
    nb = newNimbox()

proc deleteEntries*(entries:HashSet[string], nb:var Nimbox) =
    const
        prog = "rm"
        args = @["-r", "-i"]
    if entries.len < 1: return
    nb.shutdown()
    let
        files = toSeq(entries.items)
        force = if askYorN("use force? [y/n]", nb): @["-f"] else: @[]
    let process = startProcess(prog,
        args = args & force & files,
        options = {poUsePath, poParentStreams, poInteractive})
    let exitCode = process.waitForExit()
    process.close()
    nb = newNimbox()

proc newFile*(nb:var Nimbox) =
    const
        cmd = "touch"
    nb.shutdown()
    let
        name = askString(" -> " & cmd & " ", nb)
    let process = startProcess(cmd,
        args = @[name],
        options = {poUsePath, poParentStreams, poInteractive})
    let exitCode = process.waitForExit()
    process.close()
    nb = newNimbox()

proc newDir*(nb:var Nimbox) =
    const
        cmd = "mkdir"
    nb.shutdown()
    let
        name = askString(" -> " & cmd & " ", nb)
    let process = startProcess(cmd,
        args = @[name],
        options = {poUsePath, poParentStreams, poInteractive})
    let exitCode = process.waitForExit()
    process.close()
    nb = newNimbox()

proc rename*(path:string, nb:var Nimbox) =
    const
        cmd = "mv"
    nb.shutdown()
    let
        oldName = path
        newName = askString(" -> " & cmd & oldName & " ", nb, oldName)
    let process = startProcess(cmd,
        args = @[oldName, newName],
        options = {poUsePath, poParentStreams, poInteractive})
    let exitCode = process.waitForExit()
    process.close()
    nb = newNimbox()

