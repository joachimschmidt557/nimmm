import os, sets

import lscolors/style

type
  TabState* = enum
    ## The states a specific tab can be in
    TsNormal,
    TsSearch,
    TsSearchResults,

  TabStateInfo* = object
    case state*: TabState
    of TsNormal: discard
    of TsSearch, TsSearchResults:
      query*: string

  Tab* = object
    ## Represents a tab
    cd*: string
    index*: int
    stateInfo*: TabStateInfo

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
  State(tabs: @[Tab(cd: getCurrentDir(), index: 0,
                    stateInfo: TabStateInfo(state: TsNormal))],
        currentTab: 0,
        showHidden: false,
        entries: @[],
        selected: initHashSet[string]())

template currentIndex*(s: State): int =
  ## Gets the current index, basically sugar for getting the current index of
  ## the current tab
  s.tabs[s.currentTab].index

template `currentIndex=`*(s: var State, i: int) =
  ## Sets the current index, basically sugar for setting the current index of
  ## the current tab
  s.tabs[s.currentTab].index = i

template currentEntry*(s: State): DirEntry =
  ## Gets the current entry
  s.entries[s.currentIndex]

template empty*(s: State): bool =
  ## Returns whether there are no entries
  s.entries.len < 1

template tabStateInfo*(s: State): TabStateInfo =
  ## Gets the state info for the current tab
  s.tabs[s.currentTab].stateInfo

template `tabStateInfo=`*(s: var State, info: TabStateInfo) =
  ## Sets the state info for the current tab
  s.tabs[s.currentTab].stateInfo = info
