
;--- "hello world" for Linux; uses int 80h.
;--- assemble: jwasm -elf -Fo=Linux1.o Linux1.asm
;--- link(wlink): wlink format ELF runtime linux file Linux1.o name Linux1.
;--- link(gcc):   gcc -nostartfiles -m32 -no-pie Linux1.o -o Linux1

    .386
    .model flat

stdout    equ 1
SYS_EXIT  equ 1
SYS_WRITE equ 4

    .data

string  db 10,"Hello, world!",10

    .code

;--- note that _start is the "usual" entry point for ELF;
;--- it's also the argument of the END directive here, but that was just
;--- added to make the label public.

_start:

    mov ecx, offset string
    mov edx, sizeof string
    mov ebx, stdout
    mov eax, SYS_WRITE
    int 80h
    mov eax, SYS_EXIT
    int 80h

    end _start
