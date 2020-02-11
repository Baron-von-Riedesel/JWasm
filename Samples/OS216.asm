
;--- "Hello world" for OS/2 16bit.
;--- assemble: jwasm os216.asm
;--- link:     wlink sys os2 file os216.obj

    .286
    .model small

DosWrite proto far pascal :WORD, :far ptr BYTE, :WORD, :far ptr WORD
DosExit  proto far pascal :WORD

    .stack 1024

    .data

written dw 0
string db "Hello world",13,10

    .code

start:
    invoke DosWrite, 1, addr string, sizeof string, addr written
    invoke DosExit, 0

    END start
