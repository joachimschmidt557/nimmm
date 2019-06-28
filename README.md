# nimmm

[![Build Status](https://travis-ci.org/joachimschmidt557/nimmm.svg?branch=master)](https://travis-ci.org/joachimschmidt557/nimmm)
![GitHub](https://img.shields.io/github/license/joachimschmidt557/nimmm.svg)

A terminal file manager written in [nim](https://nim-lang.org/)
inspired by the awesome [nnn](https://github.com/jarun/nnn). 

![screenshot of nimmm](screenshot.png "nimmm in action")

The goal of `nimmm` is not to replace `nnn`; I just
wanted to code my own version of `nnn` to my liking.
`nimmm` does not nearly have the same amount of features
and power than `nnn` but it has enough features to be
usable as a daily driver for me.

## Usage

### Command-line options

There are no command line options! I designed `nimmm`
to be purely interactive and handle the configuration
with environment variables just like `nnn` does.

### Configuration

| Environment variable | Setting |
| --- | --- |
| `EDITOR` | file editor |
| `PAGER` | file viewer |
| `NIMMM_OPEN` | file opener |

### Basic commands

| Key | Function |
| --- | --- |
| <kbd>q</kbd> | quit |
| <kbd>!</kbd> | spawn shell in current directory |

### Navigation

| Key | Function |
| --- | --- |
| <kbd>j</kbd> | next entry |
| <kbd>k</kbd> | previous entry |
| <kbd>h</kbd> | go to the parent directory |
| <kbd>l</kbd> | navigate to directory / open file |
| <kbd>g</kbd> | first entry |
| <kbd>G</kbd> | last entry |
| <kbd>~</kbd> | go to home directory |
| <kbd>/</kbd> | start searching |
| <kbd>Esc</kbd> | stop searching |

### File operations

| Key | Function |
| --- | --- |
| <kbd>e</kbd> | edit file in `$EDITOR` |
| <kbd>p</kbd> | view file in `$PAGER` |
| <kbd>r</kbd> | rename file/directory |

### Selections

| Key | Function |
| --- | --- |
| <kbd>Space</kbd> | select / deselect current entry |
| <kbd>a</kbd> | select all entries in current directory |
| <kbd>s</kbd> | clear selection |
| <kbd>X</kbd> | delete selected entries |
| <kbd>P</kbd> | copy selected entries |
| <kbd>V</kbd> | move selected entries |

### Tabs

| Key | Function |
| --- | --- |
| <kbd>t</kbd> | new tab |
| <kbd>w</kbd> | close tab |
| <kbd>1</kbd>..<kbd>0</kbd> | go to tab 1..10 |

## ToDo

* Help page

## Dependencies

### Compile-time

The main dependency nimmm needs is the `nim` development
toolchain, i.e. the `nim` compiler and the `nimble`
package manager. A C compiler (gcc, clang, etc.) or
a C++ compiler is necessary for compiling the generated
C/C++ code to binaries.

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

    $ git clone https://github.com/joachimschmidt557/nimmm
    $ cd nimmm
    $ nimble install
