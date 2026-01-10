
;--- Win32 sample that shows how to use JWasm.dll. Public Domain.
;--- assemble+link with MS link:
;---  JWasm -coff JWasmDyn.asm
;---  link /subsystem:console JWasmDyn.obj
;--- assemble+link with jwlink:
;---  JWasm JWasmDyn.asm
;---  JWLink format win pe file JWasmDyn.obj

    .386
    .MODEL FLAT, stdcall
    option casemap:none

?VERBOSE equ 0

STD_OUTPUT_HANDLE equ -11

GetCommandLineA proto
WriteFile      proto :ptr, :ptr, :dword, :ptr, :ptr
GetStdHandle   proto :dword
ExitProcess    proto :dword
LoadLibraryA   proto :ptr
FreeLibrary    proto :ptr
GetProcAddress proto :ptr, :ptr
wvsprintfA     proto :ptr, :ptr, :ptr

    includelib kernel32.lib
    includelib user32.lib

CStr macro text:vararg
local x
    .const
x   db text,0
    .code
    exitm <offset x>
    endm

protoParseCmdline   typedef proto :ptr ptr BYTE, :ptr DWORD
LPFNPARSECMDLINE    typedef ptr protoParseCmdline
protoAssembleModule typedef proto :ptr BYTE
LPFNASSEMBLEMODULE  typedef ptr protoAssembleModule

    .DATA

hConsole dd 0
cmdline  dd 2 dup (0)   ;argument for ParseCmdline is an array of strings!

    .CODE

;--- simple printf()

printf proc c fmt:ptr byte, args:VARARG

local dwWritten:dword
local szText[128]:byte

    invoke wvsprintfA, addr szText, fmt, addr args
    lea ecx, dwWritten
    invoke WriteFile, hConsole, addr szText, eax, ecx, 0
    ret

printf endp

main proc

local cnt:dword
local AssembleModule:LPFNASSEMBLEMODULE
local ParseCmdline:LPFNPARSECMDLINE

    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov hConsole,eax

;--- prepare assembly step: load JWasm.dll and its function addresses

    mov esi, CStr("jwasm")
    invoke LoadLibraryA, esi
    .if ( !eax )
        invoke printf, CStr("LoadLibrary('%s') failed",13,10), esi
        jmp @exit
    .endif
    mov ebx, eax
    mov esi, CStr("ParseCmdline")
    invoke GetProcAddress, ebx, esi
    .if ( !eax )
        invoke printf, CStr("GetProcAddress('%s') failed",13,10), esi
        jmp @exit
    .endif
    mov ParseCmdline, eax
    mov esi, CStr("AssembleModule")
    invoke GetProcAddress, ebx, esi
    .if ( !eax )
        invoke printf, CStr("GetProcAddress('%s') failed",13,10), esi
        jmp @exit
    .endif
    mov AssembleModule, eax

;--- get cmdline string (skip first name)
    invoke GetCommandLineA
    mov esi, eax
    .while (byte ptr [esi] != ' ' && byte ptr [esi] != 0 )
        inc esi
    .endw
    mov cmdline, esi

;--- do 2 steps in a loop:
;--- 1. scan commandline, read options and filename
;--- 2. assemble the file

    mov cnt, 0
    .while (1)
        invoke ParseCmdline, offset cmdline, addr cnt
        .break .if (!eax)
        mov esi, eax
if ?VERBOSE
        invoke printf, CStr("ParseCmdline() returned '%s'",13,10), esi
endif
        invoke AssembleModule, esi
if ?VERBOSE
        invoke printf, CStr("AssembleModule('%s') returned %u",13,10), esi, eax
endif
    .endw
if ?VERBOSE
    invoke printf, CStr("ParseCmdline() returned NULL",13,10)
endif

;--- done. release JWasm.dll

    invoke FreeLibrary, ebx
@exit:
    xor eax,eax
    ret
main endp

;--- entry

mainCRTStartup proc c

    invoke main
    invoke ExitProcess, eax

mainCRTStartup endp

    end mainCRTStartup
