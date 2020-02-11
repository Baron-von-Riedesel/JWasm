
;--- this is a test app which calls function getstring in Linux4d.so
;--- assemble: jwasm -elf -Fo=Linux4a.o Linux4a.asm
;--- link:     gcc -s -nostartfiles -o Linux4a Linux4a.o Linux4d.so

    .386
    .model flat

getstring proto syscall :dword

puts proto syscall :dword
exit proto syscall :dword

    .code

_start:
    invoke getstring, 0  ;get first string
    invoke puts, eax     ;display it
    invoke getstring, 1  ;get second string
    invoke puts, eax
    invoke exit, 0

    end _start
