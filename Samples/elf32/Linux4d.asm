
;--- this is the source for shared lib Linux4d.so
;--- assemble: jwasm -elf -Fo=Linux4d.o Linux4d.asm
;--- link:     ld -s -shared -o Linux4d.so Linux4d.o
;--- link:     ld -s -shared -soname libLinux4d.so.1 -o libLinux4d.so.1.0 Linux4d.o

    .386
    .model flat

    .data

string0 db "string 0",0
string1 db "string 1",0

    .code

@start label near

;--- get image load address into EBX

getpos:
    call @F
@@:
    pop ebx
    sub ebx,5
    ret

;--- return address of strings, position-independant

getstring proc syscall public uses ebx a1:dword

    call getpos
    .if (a1 == 0)
       mov eax, offset string0
    .else
       mov eax, offset string1
    .endif
    sub eax, offset @start
    add eax, ebx
    ret

getstring endp

start proc c public
    ret
start endp

    end start
