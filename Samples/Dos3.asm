
;--- this is a 32bit DPMI application.
;--- assemble+link: JWasm -mz Dos3.asm

    .386
    .model small

    .dosseg    ;ensures that segments are ordered: code, data, bss, stack

    .stack 1024

LF  equ 10
CR  equ 13

    .data

szWelcome db "welcome in protected-mode",CR,LF,0

    .code

start:
    mov esi, offset szWelcome
    call printstring
    mov ax, 4C00h   ;normal client exit
    int 21h

;--- print a string in protected-mode with simple
;--- DOS commands not using pointers.

printstring:
    lodsb
    and al,al
    jz stringdone
    mov dl,al
    mov ah,2
    int 21h
    jmp printstring
stringdone:
    ret

;--- now comes the 16bit initialization part

_TEXT16 segment use16 word public 'CODE'

start16:
    mov ax, @data
    mov ds, ax      ;DS=DGROUP

    mov bx, ss
    sub bx, ax
    shl bx, 4
    add bx, sp
    mov ss, ax      ;SS=DGROUP
    mov sp, bx

    mov ax, ss
    mov cx, es
    sub ax, cx
    mov bx, sp
    shr bx, 4
    inc bx
    add bx, ax
    mov ah, 4Ah     ;free unused memory
    int 21h

    mov ax, 1687h   ;DPMI host installed?
    int 2Fh
    and ax, ax
    jnz nohost
    push es         ;save DPMI entry address
    push di
    and si, si      ;requires host client-specific DOS memory?
    jz nomemneeded
    mov bx, si
    mov ah, 48h     ;alloc DOS memory
    int 21h
    jc nomem
    mov es, ax
nomemneeded:
    mov bp, sp
    mov ax, 0001        ;start a 32-bit client
    call far ptr [bp]   ;initial switch to protected-mode
    jc initfailed

;--- now in protected-mode

;--- create a 32bit code selector and jump to 32bit code

    mov cx,1
    mov ax,0
    int 31h
    mov bx,ax
    mov cx,@code
    mov dx,cx
    shl dx,4
    shr cx,12
    mov ax,7
    int 31h     ;set base address
    mov dx,-1
    mov cx,0
    mov ax,8
    int 31h     ;set descriptor limit to 64 kB
    mov cx,cs
    lar cx,cx
    shr cx,8
    or ch,40h   ;set D bit (means "default is 32bit")
    mov ax,9
    int 31h     ;set descriptor attributes
    push ebx
    push offset start
    retd        ; jump to 32-bit code

nohost:
    mov dx, offset dErr1
    jmp error
nomem:
    mov dx, offset dErr2
    jmp error
initfailed:
    mov dx, offset dErr3
error:
    push cs
    pop ds
    mov ah, 9
    int 21h
    mov ax, 4C00h
    int 21h

dErr1 db "no DPMI host installed",CR,LF,'$'
dErr2 db "not enough DOS memory for initialisation",CR,LF,'$'
dErr3 db "DPMI initialisation failed",CR,LF,'$'

_TEXT16 ends

    end start16
