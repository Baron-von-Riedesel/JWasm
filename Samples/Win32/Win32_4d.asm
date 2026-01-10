
;--- Win32 Dll sample.
;--- To create the binary, there are several possibilities:
;--- 1. using MS link:
;---   assemble: JWasm -coff Win32_4d.ASM
;---   link:     Link /DLL Win32_4d.OBJ
;--- 2. using JWlink (to be found at the JWasm site):
;---   assemble: JWasm -coff Win32_4d.ASM
;---   link:     JWlink format win pe dll file Win32_4d.OBJ op implib
;--- 3. using Polink (to be found in Pelles C):
;---   assemble: JWasm -coff Win32_4d.ASM
;---   link:     PoLink /DLL Win32_4d.OBJ
;--- 4. using Alink:
;---   assemble: JWasm -zt0 Win32_4d.ASM
;---   link:     ALink -oPE -dll -c Win32_4d.OBJ

    .386
    .MODEL FLAT, stdcall
    option casemap:none

    .CODE

Export1 proc export

    mov eax,12345678h
    ret

Export1 endp

Export2 proc export pParm:ptr DWORD

    mov ecx, pParm
    mov dword ptr [ecx], 87654321h
    mov eax,1
    ret

Export2 endp

DLL_PROCESS_DETACH equ 0
DLL_PROCESS_ATTACH equ 1

LibMain proc hModule:dword, dwReason:dword, dwReserved:dword

    cmp dwReason, DLL_PROCESS_ATTACH
    jnz @F
    mov eax,1
@@:
    ret

LibMain endp

    END LibMain

