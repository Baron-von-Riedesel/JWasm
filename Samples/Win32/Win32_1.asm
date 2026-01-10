
;--- Win32 "hello world" console application.
;--- assemble: JWasm -coff Win32_1.ASM
;--- link:     JWlink format win pe file Win32_1.OBJ lib kernel32.lib
;--- or, linking with MS link:
;---           link Win32_1.obj kernel32.lib

    .386
    .MODEL FLAT, stdcall
    option casemap:none

STD_OUTPUT_HANDLE equ -11

WriteConsoleA proto :dword, :dword, :dword, :dword, :dword
GetStdHandle  proto :dword
ExitProcess   proto :dword

    .CONST

string  db 13,10,"hello, world.",13,10

    .CODE

main proc c

local   dwWritten:dword
local   hConsole:dword

    invoke  GetStdHandle, STD_OUTPUT_HANDLE
    mov     hConsole,eax

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
