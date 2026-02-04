
;--- source for (non-pic) shared object Linux4dl.so;
;--- assemble: jwasm -elf -zcw -pic0 Linux4dl.asm
;--- link(gcc): gcc -m32 -shared Linux4dl.o -o Linux4dl.so
;--- link(ld): ld -s -m elf_i386 -shared -o Linux4dl.so Linux4dl.o

    .386
    .model flat

`.note.GNU-stack` segment info
`.note.GNU-stack` ends

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

;--- return address of strings, position-dependent

getstring proc c uses ebx a1:dword

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

