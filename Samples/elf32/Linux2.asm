
;--- "hello world" for Linux which uses Libc.
;--- assemble: jwasm -elf -zcw -Fo=Linux2.o Linux2.asm
;--- link:     gcc -s -nostartfiles -o Linux2 Linux2.o

    .386
    .model flat

puts proto c :dword
exit proto c :dword

    .data

string  db 10,"Hello, world!",10

    .code

_start:
    invoke puts, offset string
    invoke exit, 0

    end _start
