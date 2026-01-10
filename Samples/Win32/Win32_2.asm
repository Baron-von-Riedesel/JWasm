
;--- Win32 "hello world" console application.
;--- The WinInc include files are used.
;--- assemble: JWasm -coff Win32_2.ASM
;--- link:     JWlink format win pe file Win32_2.OBJ lib \wininc\lib\kernel32.lib
;--- or, linking with MS link:
;---           link Win32_2.obj \wininc\lib\kernel32.lib

    .386
    .MODEL FLAT, stdcall
    option casemap:none

    pushcontext listing ;suppress listing of includes
    .nolist
    .nocref
WIN32_LEAN_AND_MEAN equ 1 ;this is to reduce assembly time
    include \wininc\include\windows.inc
    popcontext listing

    .const

string   db 13,10,"hello, world.",13,10

    .code

main proc c

local dwWritten:dword
local hConsole:dword

    invoke  GetStdHandle, STD_OUTPUT_HANDLE
    mov     hConsole, eax

    invoke  WriteConsoleA, hConsole, addr string, sizeof string, addr dwWritten, 0

    xor     eax,eax
    ret
main endp

;--- entry

mainCRTStartup proc c

    invoke  main
    invoke  ExitProcess, eax

mainCRTStartup endp

    END mainCRTStartup
