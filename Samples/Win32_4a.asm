
;--- this is a test app which calls functions Export1 and Export2 in
;--- Win32_4d.dll. The link step needs import library Win32_4d.lib to find
;--- the externals used in the source. Some linkers (MS link, PoLink)
;--- will always generate such an import lib when the dll is written.
;--- To get one with JWlink, OPTION IMPLIB must be set; it will make JWlink
;--- launch JWlib internally.

;--- To assembly, use JWasm:
;---   JWasm -coff Win32_4a.asm
;
;--- 1. To link with MS link:
;---   Link /subsystem:console Win32_4a.obj Win32_4d.lib
;--- 2. To link with JWlink
;---   JWlink format win pe file Win32_4a.obj lib Win32_4d.lib
;--- 3. To link with PoLink:
;---   PoLink /subsystem:console Win32_4a.obj Win32_4d.lib

    .386
    .model flat, stdcall

    includelib kernel32.lib
    includelib user32.lib

;--- prototypes for functions exported by Window4d.

Export1 proto stdcall
Export2 proto stdcall :ptr DWORD

;--- standard Win32 prototypes

STD_OUTPUT_HANDLE equ -11

WriteConsoleA proto :dword, :dword, :dword, :dword, :dword
GetStdHandle  proto :dword
ExitProcess   proto :dword
wvsprintfA    proto :ptr, :ptr, :ptr

    .data

value2 dd 0

szFormat1 db "Export1() returned %X",13,10,0
szFormat2 db "Export2() returned %X",13,10,0

    .code

;--- simple printf() emulation

printf proc c uses ebx pszFormat:dword, args:VARARG

local dwWritten:DWORD
local buffer[256]:byte

    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov ebx, eax
    invoke wvsprintfA, addr buffer, pszFormat, addr args
    lea ecx, dwWritten
    invoke WriteConsoleA, ebx, addr buffer, eax, ecx, 0
    ret

printf endp

start:
    invoke Export1
    invoke printf, addr szFormat1, eax
    invoke Export2, addr value2
    invoke printf, addr szFormat2, value2
    invoke ExitProcess, 0

    end start

