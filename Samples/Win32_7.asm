
;--- Win32_7 - Shows how to use OPTION DLLIMPORT and cmdline option -Fd.
;---           As a result, no import libraries are needed in the link step.
;---
;--- assemble: JWasm -coff -Fd Win32_7.ASM
;--- link:     JWlink format windows pe f Win32_7.OBJ

    .386
    .MODEL FLAT, stdcall
    option casemap:none

STD_OUTPUT_HANDLE equ -11

   option dllimport:<kernel32>
WriteConsoleA proto :dword, :dword, :dword, :dword, :dword
GetStdHandle  proto :dword
ExitProcess   proto :dword
   option dllimport:<user32>
MessageBoxA   proto :dword, :dword, :dword, :dword
   option dllimport:<none>

    .CONST

string  db 13,10,"hello, world.",13,10
    db 0

    .CODE

main proc

local   dwWritten:dword

    invoke  GetStdHandle, STD_OUTPUT_HANDLE
    mov     ebx, eax
    invoke  WriteConsoleA, ebx, addr string, sizeof string, addr dwWritten, 0
    invoke  MessageBoxA, 0, addr string, 0, 0
    ret

main endp

;--- entry

start:

    invoke  main
    invoke  ExitProcess, 0

    END start
