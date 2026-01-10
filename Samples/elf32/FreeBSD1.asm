;------------------------------------------------------------------------------
;
;   Hello, world !! for FreeBSD with JWasm's BIN format.
;   Written by Ito Toshimitsu.
;
; > jwasm -q -bin -Fo=FreeBSD1. FreeBSD1.asm
; > chmod 755 FreeBSD1
;
;   How to:
;   1. file elf32.inc must be included.
;   2. Macro 'elf32_header' is to be put before start label '_start'.
;   3. Macro 'elf32_footer' is to be put before last 'end _start'.
;
;   Restrictions:
;   -  It is only one section.
;   -  Start label is '_start'.
;------------------------------------------------------------------------------

    .386
    .model flat

    include elf32.inc

    .code

    elf32_header ELF_FreeBSD
_start:
    push   sizeof msg
    push   offset msg
    push   1               ; stdout
    mov    eax, 4          ; sys_write
    push   0               ; dummy argument
    int    080h

    xor    eax, eax        ; sys_exit
    int    080h

msg db 'Hello World !!', 0ah

    elf32_footer
    end _start

