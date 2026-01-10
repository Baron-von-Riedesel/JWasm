
;--- "hello world" for 64-bit Linux, using SYSCALL.
;--- assemble: JWasm -elf64 -zcw -Fo=Lin64_1.o Lin64_1.asm
;--- link with either gcc (USELD equ 0) or ld (USELD equ 1)
;--- link gcc: gcc Lin64_1.o -o Lin64_1
;--- link ld:  ld -pie --dynamic-linker /lib64/ld-linux-x86-64.so.2 Lin64_1.o -o Lin64_1

USELD equ 0

stdout    equ 1
SYS_WRITE equ 1
SYS_EXIT  equ 60

`.note.GNU-stack` segment info ; define this segment to suppress ld linker warning
`.note.GNU-stack` ends

    .data

string  db "Hello, world!",10

    .code

if USELD
_start:
else
_start equ <>
endif

main proc 
    mov edx, sizeof string
    lea rsi, string
    mov edi, stdout
    mov eax, SYS_WRITE
    syscall
    mov eax, SYS_EXIT
    syscall
main endp

    end _start
