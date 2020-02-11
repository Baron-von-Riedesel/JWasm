
;--- Win64 console application, uses WinInc v2+
;--- assemble:
;---   jwasm -c -win64 -Zp8 -I\WinInc\Include Win64_4.asm
;--- link:
;--- JWlink: jwlink format win pe f Win64_4.obj Libpath \WinInc\Lib64 
;--- MS link: link /subsystem:console /Libpath:\WinInc\Lib64 Win64_4.obj

    option casemap:none
    option frame:auto

    .nolist
    .nocref
WIN32_LEAN_AND_MEAN equ 1
    include windows.inc
    .list
    .cref

    includelib <kernel32.lib>

;--- CStr(): macro function to simplify defining a string

CStr macro Text:VARARG
local szText
    .const
szText  db Text,0
    .code
    exitm <offset szText>
endm

    .CODE

main proc FRAME uses rbx rsi rdi

local dwWritten:DWORD

    invoke GetStdHandle,STD_OUTPUT_HANDLE
    mov rbx,rax
    lea rsi, CStr("Hello, world",13,10)
    invoke lstrlen, rsi
    mov edi, eax
    invoke WriteConsoleA, rbx, rsi, edi, addr dwWritten, 0
    ret

main endp

mainCRTStartup proc FRAME
    invoke main
    invoke ExitProcess, eax
mainCRTStartup endp

    END mainCRTStartup
