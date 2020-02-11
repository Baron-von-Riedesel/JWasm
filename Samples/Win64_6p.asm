
;--- Win64 "hello world" console application.
;--- uses CRT functions (MSVCRT).
;--- unlike Win64_6.asm, this version is to be created with option -pe
;---
;--- assemble: JWasm -pe Win64_6p.asm

    .x64                ; -pe requires to set cpu, model & language
    .model flat, fastcall

    option casemap:none
    option frame:auto   ; generate SEH-compatible prologues and epilogues
    option win64:3      ; init shadow space, reserve stack at PROC level

    option dllimport:<msvcrt>
printf proto :ptr byte, :vararg
exit   proto :dword
_kbhit proto
_flushall proto
    option dllimport:NONE

    .data

szFmt db 10,"%u + %u = %u",10,0

    .code

main proc FRAME

    invoke printf, addr szFmt, 3, 4, 3+4
    .repeat
        invoke _kbhit
    .until eax
    invoke _flushall
    invoke exit, 0

main endp

    end main
