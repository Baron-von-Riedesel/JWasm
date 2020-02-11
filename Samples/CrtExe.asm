
;--- this is a simple startup procedure, for 32- and 64-bit,
;--- if a console application is to use msvcrt.dll
;--- instead of a static CRT.

if ( type near ) ne 0ff08h
    .386
    .MODEL FLAT
_cdecl textequ <c>
WINAPI textequ <stdcall>
pattr  textequ <>
else
_cdecl textequ <>
WINAPI textequ <>
pattr textequ <frame>
    option frame:auto
    option win64:3
endif
    option casemap:none

LPVOID typedef ptr

STARTUPINFOA struct 8
cb              DWORD   ?
lpReserved      LPVOID  ?
lpDesktop       LPVOID  ?
lpTitle         LPVOID  ?
dwX             DWORD   ?
dwY             DWORD   ?
dwXSize         DWORD   ?
dwYSize         DWORD   ?
dwXCountChars   DWORD   ?
dwYCountChars   DWORD   ?
dwFillAttribute DWORD   ?
dwFlags         DWORD   ?
wShowWindow     WORD    ?
cbReserved2     WORD    ?
lpReserved2     LPVOID  ?
hStdInput       LPVOID  ?
hStdOutput      LPVOID  ?
hStdError       LPVOID  ?
STARTUPINFOA ends

__getmainargs proto _cdecl :ptr, :ptr, :ptr, :dword, :ptr
exit          proto _cdecl :dword
main          proto _cdecl :dword, :ptr, :ptr

    .CODE

mainCRTStartup proc _cdecl pattr

    local argc:dword
    local argv:LPVOID
    local environ:LPVOID
    local _si:STARTUPINFOA

    mov _si.cb, sizeof STARTUPINFOA
if 1
GetStartupInfoA proto WINAPI :ptr STARTUPINFOA
    invoke GetStartupInfoA, addr _si
endif
    invoke __getmainargs, addr argc, addr argv, addr environ, 0, addr _si
    invoke main, argc, argv, environ
    invoke exit, eax

mainCRTStartup endp

    end mainCRTStartup
