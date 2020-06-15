import noise

proc askYorN*(question: string): bool =
  stdout.write(question)
  while true:
    case getCh():
      of 'y', 'Y':
        return true
      of 'n', 'N':
        return false
      else:
        continue

proc askString*(question: string, preload = ""): string =
  var noise = Noise.init()
  noise.preloadBuffer(preload)
  noise.setPrompt(question)
  let ok = noise.readLine()

  if not ok: return ""
  return noise.getLine
