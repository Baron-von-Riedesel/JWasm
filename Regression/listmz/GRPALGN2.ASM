
    .286
    .MODEL small
    option casemap:none
    .dosseg
    .stack 2048
    .386

;--- this is derived from GRPALIGN.ASM, but this time
;--- there's a second group, where the code segments
;--- are packed. The binary map should be:
;                    size   RVA
;-------------------------------
;--- header:          20h
;--- CGROUP._TEXT      8h     0h
;--- CGROUP._TEXT2    10h     8h
;--- DGROUP._DATA      4h     8h
;--- DGROUP._BSS     200h    10h
;--- DGROUP.STACK    800h   210h
;--- that is, _DATA starts at RVA 8, because the
;--- groups are packed and DGROUP addresses the last
;--- 8 bytes of CGROUP at offset 0-7.


_TEXT2 segment word public 'CODE'
    db 10h dup (90h)
_TEXT2 ends

    .data

var1 dd 0

_BSS segment para public 'BSS'

DGROUP group _BSS

buffer  db 200h dup (?)

_BSS ends

    .code

start proc c public
    mov dx, offset buffer
    mov ax, 4C00h
    int 21h
start endp

    END start

