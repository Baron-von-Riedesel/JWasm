
;--- Win64 "hello world" console application.
;--- uses CRT functions (MSVCRT).
;--- assemble: JWasm -win64 Win64_6.asm
;---       or: ml64 -c Win64_6.asm
;--- link:
;---  MS Link: link /subsystem:console Win64_6.obj /libpath:\wininc\lib64
;---  JWlink:  jwlink format win pe f Win64_6.obj libpath \wininc\lib64 op start=mainCRTStartup

    option casemap:none

    includelib msvcrt.lib

externdef printf : near
externdef _kbhit : near
externdef exit : near

    .data

string   db 10,"hello, world.",10,0

    .code

main proc

    sub rsp, 28h        ; space for 4 arguments + 16byte aligned stack
    lea rcx, string
    call printf
    .repeat
        call _kbhit
    .until eax
    xor ecx, ecx
    call exit

main endp

    end main
