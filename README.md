# nimmm

A terminal file manager written in [nim](https://nim-lang.org/)
inspired by the awesome [nnn](https://github.com/jarun/nnn). 

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
| `q` | quit |
| `!` | spawn shell in current directory |

### Navigation

| Key | Function |
| --- | --- |
| `j` | next entry |
| `k` | previous entry |
| `h` | go to the parent directory |
| `l` | navigate to directory / open file |
| `g` | first entry |
| `G` | last entry |
| `~` | go to home directory |

### File operations

| Key | Function |
| --- | --- |
| `e` | edit file in `$EDITOR` |
| `p` | view file in `$PAGER` |

### Selections

| Key | Function |
| --- | --- |
| `Space` | select / deselect current entry |
| `a` | select all entries in current directory |
| `s` | clear selection |
| `X` | delete selected entries |
| `P` | copy selected entries |
| `V` | move selected entries |

### Tabs

| Key | Function |
| --- | --- |
| `t` | new tab |
| `w` | close tab |
| `1`..`0` | go to tab 1..10 |

## ToDo

* Help page

## Dependencies

### Compile-time

The main dependency nimmm needs is the `nim` development
toolchain, i.e. the `nim` compiler and the `nimble`
package manager. A C compiler (gcc, clang, etc.) or
a C++ compiler is necessary for compiling the generated
C/C++ code to binaries.

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
