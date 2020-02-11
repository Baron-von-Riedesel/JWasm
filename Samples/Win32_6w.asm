
;--- sample how to use Unicode in assembly
;--- similar to Win32_6.asm, but uses the WinInc include files
;--- assemble the ANSI version:    jwasm -coff Win32_6w.ASM
;--- assemble the UNICODE version: jwasm -coff -DUNICODE Win32_6w.ASM
;--- link:
;---  MS Link: link /subsystem:console Win32_6w.OBJ kernel32.lib
;---  JWLink: jwlink format win pe file Win32_6w.OBJ lib kernel32.lib

    .386
    .MODEL FLAT, stdcall
    option casemap:none

    pushcontext listing ;suppress listing of includes
    .nolist
    .nocref
WIN32_LEAN_AND_MEAN equ 1 ;this is to reduce assembly time
    include \wininc\include\windows.inc
    include \wininc\include\tchar.inc
    popcontext listing

    .CONST

string TCHAR _T(13,10,"Hello, world.",13,10)

    .CODE

main proc

local   dwWritten:dword
local   hConsole:dword

    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov hConsole,eax
    invoke WriteConsole, hConsole, addr string, lengthof string, addr dwWritten, 0
    xor eax,eax
    ret
main endp

;--- entry

mainCRTStartup proc c

    invoke main
    invoke ExitProcess, eax

mainCRTStartup endp

    END mainCRTStartup
