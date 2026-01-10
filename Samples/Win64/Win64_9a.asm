
;--- this is a test app that calls functions Export1 and Export2 in
;--- Win64_9d.dll. 
;---
;--  The link step needs import library Win64_9d.lib to resolve
;--- externals Export1 and Export2. Some linkers (MS link, PoLink)
;--- will always generate such an import lib when the dll is written.
;--- JWlink will do this only if OPTION IMPLIB is set; see comments in
;--- Win64_9d.asm for an example.

;--- To assemble, use JWasm:
;---   JWasm -win64 Win64_9a.asm
;---
;--- 1. To link with MS link:
;---   Link /subsystem:console Win64_9a.obj Win64_9d.lib
;--- 2. To link with JWlink:
;---   JWlink format win pe file Win64_9a.obj lib Win64_9d.lib
;--- 3. To link with PoLink:
;---   PoLink /subsystem:console Win64_9a.obj Win64_9d.lib

    option casemap:none
    option frame:auto
    option win64:3

    includelib kernel32.lib
    includelib user32.lib

;--- prototypes for functions exported by Window4d.

Export1 proto
Export2 proto :ptr DWORD

;--- standard Windows prototypes

STD_OUTPUT_HANDLE equ -11

WriteConsoleA proto :ptr, :ptr, :dword, :ptr, :dword
GetStdHandle  proto :dword
ExitProcess   proto :dword
wvsprintfA    proto :ptr, :ptr, :ptr

    .data

value2 dd 0

szFormat1 db "Export1() returned %X",13,10,0
szFormat2 db "Export2() returned %X",13,10,0

    .code

;--- simple printf() emulation

printf proc frame uses rbx rsi pszFormat:ptr byte, args:VARARG

local dwWritten:DWORD
local buffer[256]:byte

    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov rbx, rax
    invoke wvsprintfA, addr buffer, pszFormat, addr args
    lea rsi, dwWritten
    invoke WriteConsoleA, rbx, addr buffer, eax, rsi, 0
    ret

printf endp

start proc frame
    invoke Export1
    invoke printf, addr szFormat1, eax
    invoke Export2, addr value2
    invoke printf, addr szFormat2, value2
    invoke ExitProcess, 0
start endp

    end start
