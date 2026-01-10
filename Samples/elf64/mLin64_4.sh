#!/bin/sh
jwasm -nologo -elf64 -Zd -zcw Lin64_4.asm
jwasm -nologo -elf64 -Zd -zcw Lin64_4d.asm
gcc -g -shared Lin64_4d.o -o Lin64_4d.so
gcc -g Lin64_4.o Lin64_4d.so -o Lin64_4 -Wl,-rpath=.
