import os

type
    Tab* = object
        cd*: string
        index*: int

    DirEntry* = object
        path*: string
        relative*: string
        info*: FileInfo

