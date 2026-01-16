#!/bin/sh
jwasm -nologo -elf -Zd -zcw Linux4.asm
jwasm -nologo -elf -Zd -zcw Linux4dl.asm
gcc -g -m32 -shared Linux4dl.o -o Linux4dl.so
gcc -g -m32 -nostartfiles -no-pie Linux4.o Linux4dl.so -o Linux4 -Wl,-rpath=.
