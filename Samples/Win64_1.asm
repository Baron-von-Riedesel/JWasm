
;--- Win64 "hello world" GUI application.
;--- assemble: JWasm -win64 Win64_1.asm
;--- to link, use MS link, Polink or JWlink:
;--- MS link: link /subsystem:windows /entry:main Win64_1.obj
;--- Polink:  polink /subsystem:windows /entry:main Win64_1.obj
;--- JWlink:  jwlink format win pe ru win file Win64_1.obj op start=main

    option casemap:none

    includelib kernel32.lib
    includelib user32.lib

externdef MessageBoxA : near
externdef ExitProcess : near

    .data

text    db 'Hello world!', 0
caption db 'Hello x86-64', 0

    .code

main proc
    sub rsp, 28h        ; space for 4 arguments + 16byte aligned stack
    xor r9d, r9d        ; 4. argument: r9d = uType = 0
    lea r8, [caption]   ; 3. argument: r8  = caption
    lea rdx, [text]     ; 2. argument: edx = window text
    xor rcx, rcx        ; 1. argument: rcx = hWnd = NULL
    call MessageBoxA
    xor ecx, ecx        ; ecx = exit code
    call ExitProcess
main endp

    end
