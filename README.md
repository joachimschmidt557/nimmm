# nimmm

[![Build](https://github.com/joachimschmidt557/nimmm/actions/workflows/build.yml/badge.svg)](https://github.com/joachimschmidt557/nimmm/actions/workflows/build.yml)
![GitHub](https://img.shields.io/github/license/joachimschmidt557/nimmm.svg)

A terminal file manager for Linux

[![asciicast](https://asciinema.org/a/tGAr5PkesSBBgYBmzCQl30hE0.svg)](https://asciinema.org/a/tGAr5PkesSBBgYBmzCQl30hE0)

# Table of Contents

1. [Features](#features)
2. [Installation](#installation)
    1. [From source](#source)
    2. [Nix](#nix)
3. [Usage](#usage)
    1. [Configuration](#configuration)
    2. [Default keymap](#keymaps)
4. [ToDo](#todo)
5. [External Tools](#external-tools)

## Features

* Unlimited tab support
* Colorizing with `LS_COLORS`
* Custom keymaps (see below)
* Incremental search

## Installation

I'm not aware of any distros packaging `nimmm` apart from NixOS, so
you will probably have to compile `nimmm` from source on non-NixOS
distros.

### From source <a name="source"></a>

You will need the [Nim development
toolchain](https://nim-lang.org/install_unix.html). Furthermore,
`termbox-devel` or `libtermbox-dev` is required for the terminal user
interface.

```bash
git clone https://github.com/joachimschmidt557/nimmm
cd nimmm
nimble build
```

### Nix

`nimmm` is included in nixpkgs.

```bash
nix-env -i nimmm
# or, if you prefer nix flakes
nix profile install nixpkgs#nimmm
```

## Usage

### Configuration

Some functionality of `nimmm` is controlled via environment variables
similar to other programs:

| Environment variable | Setting |
| --- | --- |
| `EDITOR` | file editor |
| `PAGER` | file viewer |
| `NIMMM_OPEN` | file opener |
| `NIMMM_256` | enable 256 color mode |

Other configuration such as keybindings are configured in
`$XDG_CONFIG_HOME/nimmm.conf` where `$XDG_CONFIG_HOME` defaults to
`~/.config` if not set.

### Default keymap <a name="keymaps"></a>

The default keymap is similar to that of `less`.

| Key | Default binding | Description |
| --- | --- | --- |
| <kbd>q</kbd> | `quit` | quit |
| <kbd>!</kbd> | `shell` | spawn shell in current directory |
| <kbd>j</kbd> | `down` | next entry |
| <kbd>k</kbd> | `up` | previous entry |
| <kbd>h</kbd> | `left` | go to the parent directory |
| <kbd>l</kbd> | `right` | navigate to directory / open file |
| <kbd>g</kbd> | `first` | first entry |
| <kbd>G</kbd> | `last` | last entry |
| <kbd>~</kbd> | `home` | go to home directory |
| <kbd>.</kbd> | `toggle-hidden` | toggle display of hidden entries |
| <kbd>/</kbd> | `search` | start searching |
| <kbd>Esc</kbd> | `end-search` | stop searching |
| <kbd>e</kbd> | `edit` | edit file in `$EDITOR` |
| <kbd>p</kbd> | `pager` | view file in `$PAGER` |
| <kbd>r</kbd> | `rename` | rename file/directory |
| <kbd>Space</kbd> | `select` | select / deselect current entry |
| <kbd>a</kbd> | `select-all` | select all entries in current directory |
| <kbd>s</kbd> | `select-none` | clear selection |
| <kbd>X</kbd> | `delete` | delete selected entries |
| <kbd>P</kbd> | `copy` | copy selected entries |
| <kbd>V</kbd> | `move` | move selected entries |
| <kbd>f</kbd> | `new-file` | create (touch) a new file |
| <kbd>d</kbd> | `new-dir` | create a new directory |
| <kbd>t</kbd> | `new-tab` | new tab |
| <kbd>w</kbd> | `close-tab` | close tab |
| <kbd>Tab</kbd> | `next-tab` | next tab |
| <kbd>1</kbd>..<kbd>0</kbd> | `tab-x` | go to tab 1..10 |

Keybindings are customized in the configuration file. For example, if
you prefer more Emacs-oriented movement keybindings, you can do this:

``` toml
[Keybindings]

h=none
j=none
k=none
l=none

n=down
p=up
f=right
b=left
```

## ToDo

* Help page

## External programs

| Dependency | Use |
| --- | --- |
| `cp`, `mv`, `rm`, `mkdir`, `touch` | `nimmm` delegates all operations on files and directories to these utilities to save all the error-handling and permission-checking work. These utilities should (hopefully) be on your UNIX system |
| `$SHELL` or fallback `sh` | an interactive shell |
| `$EDITOR` or fallback `vi` | an editor |
| `$PAGER` or fallback `less` | a pager |
| `$NIMMM_OPEN` or fallback `xdg-open` | a file opener |


## License

`nimmm` is licensed under the GNU General Public License v3.0 only.
