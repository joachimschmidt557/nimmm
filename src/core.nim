import os, sets

import lscolors/style

type
  Tab* = object
    ## Represents a tab
    cd*: string
    index*: int

  DirEntry* = object
    ## Represents an entry
    path*: string
    relative*: string
    info*: FileInfo
    style*: Style

  State* = object
    ## Represents a possible state of nimmm
    tabs*: seq[Tab]
    currentTab*: int
    showHidden*: bool
    entries*: seq[DirEntry]
    selected*: HashSet[string]

proc initState*(): State =
  ## Initializes the default startup state
  State(tabs: @[Tab(cd: getCurrentDir(), index: 0)],
        currentTab: 0,
        showHidden: false,
        entries: @[],
        selected: initHashSet[string]())

proc currentIndex*(s: State): int =
  ## Gets the current index, basically sugar for
  ## getting the current index of the current tab
  s.tabs[s.currentTab].index

proc `currentIndex=`*(s: var State, i: int) =
  ## Sets the current index, basically sugar for
  ## setting the current index of the current tab
  s.tabs[s.currentTab].index = i

proc currentEntry*(s: State): DirEntry =
  ## Gets the current entry
  s.entries[s.currentIndex]

proc empty*(s: State): bool =
  ## Returns whether there are no entries
  s.entries.len < 1
