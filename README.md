# nimmm

[![Build](https://github.com/joachimschmidt557/nimmm/actions/workflows/build.yml/badge.svg)](https://github.com/joachimschmidt557/nimmm/actions/workflows/build.yml)
![GitHub](https://img.shields.io/github/license/joachimschmidt557/nimmm.svg)

A terminal file manager written in [nim](https://nim-lang.org/)
inspired by the awesome [nnn](https://github.com/jarun/nnn).

[![asciicast](https://asciinema.org/a/aEEz3wkiAvjx2vlBZbQqxOga3.svg)](https://asciinema.org/a/aEEz3wkiAvjx2vlBZbQqxOga3)

The goal of `nimmm` is not to replace `nnn`; I just wanted to code my own
version of `nnn` to my liking. `nimmm` does not nearly have the same amount of
features and power than `nnn` but it has enough features to be usable as a daily
driver for me.

## Features

* Support for all plaforms where `nim` and `termbox` can be installed on
* Colorizing with `LS_COLORS`
* Custom keymaps (see below)
* Simple selection mechanism
* Incremental search

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

### Default keymap

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
| <kbd>1</kbd>..<kbd>0</kbd> | `tab-x` | go to tab 1..10 |

If you prefer more Emacs-oriented movement keybindings, you can add
this to your configuration file:

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

## Dependencies

### Compile-time

The main dependency nimmm needs is the `nim` development toolchain, i.e. the
`nim` compiler and the `nimble` package manager. A C compiler (gcc, clang, etc.)
or a C++ compiler is necessary for compiling the generated C/C++ code to
binaries.

Apart from that, these libraries are required:

* `termbox-devel` or `libtermbox-dev` is required in order
for the terminal user interface to work.

### Run-time

| Dependency | Use |
| --- | --- |
| `cp`, `mv`, `rm`, `mkdir`, `touch` | `nimmm` delegates all operations on files and directories to these utilities to save all the error-handling and permission-checking work. These utilities should (hopefully) be on your UNIX system |
| `$SHELL` or fallback `/bin/sh` | a shell |
| `$EDITOR` or fallback `vi` | an editor |
| `$PAGER` or fallback `less` | a pager |
| `$NIMMM_OPEN` or fallback `xdg-open` | a file opener |

## Installation

### From source

```shell
$ git clone https://github.com/joachimschmidt557/nimmm
$ cd nimmm
$ nimble install
```

### With nimble

```shell
$ nimble install nimmm
```

### With Nix

```shell
$ nix-env -i nimmm
```

## License

`nimmm` is licensed under the GNU General Public License v3.0 only.
