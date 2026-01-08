
;--- "hello world" for 64-bit Linux, using SYSCALL.
;--- assemble: JWasm -elf64 -Fo=Lin64_1.o Lin64_1.asm
;--- link:     gcc Lin64_1.o -o Lin64_1

stdout    equ 1
SYS_WRITE equ 1
SYS_EXIT  equ 60

`.note.GNU-stack` segment info ; define this segment to suppress ld linker warning
`.note.GNU-stack` ends

    .data

string  db "Hello, world!",10

    .code

_start:
    mov edx, sizeof string
    lea rsi, string
    mov edi, stdout
    mov eax, SYS_WRITE
    syscall
    mov eax, SYS_EXIT
    syscall

    end _start
