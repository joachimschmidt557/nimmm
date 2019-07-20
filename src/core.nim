import os, sets

type
    Tab* = object
        cd*: string
        index*: int

    DirEntry* = object
        path*: string
        relative*: string
        info*: FileInfo

    State* = object
        tabs*: seq[Tab]
        currentTab*: int
        showHidden*: bool
        entries*: seq[DirEntry]
        selected*: HashSet[string]

proc initState*(): State =
    State(tabs: @[Tab(cd:getCurrentDir(), index:0)],
          currentTab: 0,
          showHidden: false,
          entries: @[],
          selected: initSet[string]())

proc currentIndex*(s:State): int =
    s.tabs[s.currentTab].index

proc currentEntry*(s:State): DirEntry =
    s.entries[s.currentIndex]

proc empty*(s:State): bool =
    s.entries.len < 1
