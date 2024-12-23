
;--- Win32 "hello world" console application.
;--- Similar to Win32_1.asm, but uses JWasm's -pe option
;--- and OPTION dllimport ( so no libraries are needed )
;--- assemble: JWasm -pe Win32_1p.ASM

;--- To see in the listing what code jwasm adds to the source,
;--- add option -Sg.

    .386
    .MODEL FLAT, stdcall
    option casemap:none

STD_OUTPUT_HANDLE equ -11

    option dllimport:<kernel32.dll>
WriteConsoleA proto :dword, :dword, :dword, :dword, :dword
GetStdHandle  proto :dword
ExitProcess   proto :dword
    option dllimport:none

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
