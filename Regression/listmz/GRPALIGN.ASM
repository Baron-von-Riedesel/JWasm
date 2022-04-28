
    .286
    .MODEL small
    option casemap:none
    .dosseg
    .stack 2048
    .386

    .data

var1 dd 0

;--- alignment "para" places this segment at offset 10h within DGROUP
;--- in the binary map up to 2.15 the RVA is displayed as 8, though.
;--- this is because the group itself "contains" an offset ( because
;--- segment _TEXT is just 8 bytes, hence DGROUP "starts" at offset
;--- 8 ). It's confusing...

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

