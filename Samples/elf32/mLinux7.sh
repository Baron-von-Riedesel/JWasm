#!/bin/sh
jwasm -nologo -elf -pic2 -Zd -zcw Linux7.asm
jwasm -nologo -elf -pic2 -Zd -zcw Linux7dl.asm
gcc -g -m32 -shared Linux7dl.o -o Linux7dl.so
gcc -g -m32 Linux7.o Linux7dl.so -o Linux7 -Wl,-rpath=.
