
;--- "Hello world" for OS/2 32bit.
;--- assemble: jwasm os232.asm
;--- link:     wlink sys os2v2 file os232.obj

    .386
    .model flat

DosWrite proto syscall :DWORD, :ptr BYTE, :DWORD, :ptr DWORD
DosExit  proto syscall :DWORD

    includelib <os2386.lib>

    .stack 4096
    
    .data

written dd 0
string db "Hello world",13,10

    .code
    
start:
    invoke DosWrite, 1, addr string, sizeof string, addr written
    invoke DosExit, 0

    END start
