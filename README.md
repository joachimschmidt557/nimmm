# nimmm

[![Build Status](https://travis-ci.org/joachimschmidt557/nimmm.svg?branch=master)](https://travis-ci.org/joachimschmidt557/nimmm)
![GitHub](https://img.shields.io/github/license/joachimschmidt557/nimmm.svg)

A terminal file manager written in [nim](https://nim-lang.org/)
inspired by the awesome [nnn](https://github.com/jarun/nnn). 

![screenshot of nimmm](screenshot.png "nimmm in action")

The goal of `nimmm` is not to replace `nnn`; I just wanted to code my own
version of `nnn` to my liking. `nimmm` does not nearly have the same amount of
features and power than `nnn` but it has enough features to be usable as a daily
driver for me.

## Usage

### Command-line options

There are no command line options! I designed `nimmm` to be purely interactive
and handle the configuration with environment variables just like `nnn` does.

### Configuration

| Environment variable | Setting |
| --- | --- |
| `EDITOR` | file editor |
| `PAGER` | file viewer |
| `NIMMM_OPEN` | file opener |
| `NIMMM_256` | enable 256 color mode |
| `NIMM_KEY_x` | customize keymap for key `x` |
| `NIMM_SYMBOL_x` | customize keymap for special symbol `x` |
| `NIMM_MOUSE_x` | customize action for mouse event `x` |

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

If you prefer more Emacs-oriented movement keybindings, you can do this for
example:

``` shell
$ for x in h j k l; do export "NIMMM_KEY_$x"="none"; done
$ export "NIMMM_KEY_n"="down"
$ export "NIMMM_KEY_p"="up"
$ export "NIMMM_KEY_f"="right"
$ export "NIMMM_KEY_b"="left"
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
