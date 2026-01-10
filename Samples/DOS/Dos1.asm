
;--- this is a very simple 16bit "hello world" for DOS.
;--- assemble: JWasm -bin -Fo Dos1.com Dos1.asm

    .model tiny

    .data

str1    db 13,10,"Hello, world!",13,10,'$'

    .code

    org 100h

start:
    mov ah, 09h
    mov dx, offset str1
    int 21h
    mov ax, 4c00h
    int 21h

    end start
