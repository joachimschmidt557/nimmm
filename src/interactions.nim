import terminal

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
