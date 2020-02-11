;------------------------------------------------------------------------------
;
;   Hello, world !! for Linux with JWasm's BIN format.
;   Written by Ito Toshimitsu.
;
; > jwasm -q -bin -Fo=Linux5. Linux5.asm
; > chmod 755 Linux5
;
;   How to:
;   1. file elf32.inc must be included.
;   2. Macro 'elf32_header' is to be put before start label '_start'.
;   3. Macro 'elf32_footer' is to be put before last 'end _start'.
;
;   Restrictions:
;   -  It is only one section.
;------------------------------------------------------------------------------

    .386
    .model flat

    include elf32.inc

    .code

    elf32_header ELF_Linux, _start
_start:
    mov    ecx,offset msg
    mov    edx,sizeof msg
    mov    eax,4
    mov    ebx,1
    int    080h
    mov    eax,1
    xor    ebx,ebx
    int    080h

msg db 'Hello World !!', 0ah

    elf32_footer
    end _start
