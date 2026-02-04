
;--- this program calls function getstring in Linux4dl.so;
;--- assemble: jwasm -elf -zcw Linux4.asm
;--- link:     gcc -s -nostartfiles Linux4.o Linux4dl.so -o Linux4

    .386
    .model flat

getstring proto c :dword
puts proto c :dword
exit proto c :dword

    .code

_start:
    invoke getstring, 0  ;get first string
    invoke puts, eax     ;display it
    invoke getstring, 1  ;get second string
    invoke puts, eax
    invoke exit, 0

    end _start
