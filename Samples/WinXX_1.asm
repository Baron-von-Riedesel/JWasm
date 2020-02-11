
;--- Win32/64 console application, uses WinInc v2+.
;--- It can be used to generate both Win32 and Win64 binaries:
;--- 32bit:
;---  jwasm -coff -I\WinInc\Include WinXX_1.asm
;---  link /subsystem:console /Libpath:\WinInc\Lib WinXX_1.obj
;--- 64bit:
;---  jwasm -win64 -Zp8 -I\WinInc\Include WinXX_1.asm
;---  link /subsystem:console /Libpath:\WinInc\Lib64 WinXX_1.obj

if (type near) eq 0ff02h    ;no -win64 switch?
    .386
    .model flat, stdcall
FRAME equ <>
rax equ <eax>
rbx equ <ebx>
rcx equ <ecx>
rdx equ <edx>
rsp equ <esp>
rbp equ <ebp>
rsi equ <esi>
rdi equ <edi>
else
    option win64:1  ;enable autosaving of register params to shadow space
    option frame:auto
endif
    option casemap:none

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
