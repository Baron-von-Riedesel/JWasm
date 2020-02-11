
;--- "hello world" for Linux which uses int 80h.
;--- assemble: jwasm -Fo=Linux1.o Linux1.asm
;--- link:     wlink format ELF runtime linux file Linux1.o name Linux1.

    .386
    .model flat

stdout    equ 1
SYS_EXIT  equ 1
SYS_WRITE equ 4

    .data

string  db 10,"Hello, world!",10

    .code

_start:

    mov ecx, offset string
    mov edx, sizeof string
    mov ebx, stdout
    mov eax, SYS_WRITE
    int 80h
    mov eax, SYS_EXIT
    int 80h

    end _start
