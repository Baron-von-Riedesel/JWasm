
;--- Win64 Dll sample.
;---
;--- Assemble with JWasm:
;---   JWasm -win64 Win64_9d.asm
;---
;--- 1. link with MS link:
;---   Link /DLL Win64_9d.OBJ
;--- 2. link with JWlink:
;---   JWlink format win pe dll file Win64_9d.OBJ op implib
;--- 3. link with Polink:
;---   PoLink /DLL Win64_9d.OBJ

    option casemap:none
    option frame:auto
    option win64:1

    .CODE

Export1 proc export

    mov eax,12345678h
    ret

Export1 endp

;--- Export2 uses frame, because it may fail
;--- if an invalid argument is given.

Export2 proc export frame pParm:ptr DWORD

    mov rcx, pParm
    mov dword ptr [rcx], 87654321h
    mov eax,1
    ret

Export2 endp

DLL_PROCESS_DETACH equ 0
DLL_PROCESS_ATTACH equ 1

LibMain proc frame hModule:ptr, dwReason:dword, dwReserved:dword

    cmp dwReason, DLL_PROCESS_ATTACH
    jnz @F
    mov eax,1
@@:
    ret

LibMain endp

    END LibMain
