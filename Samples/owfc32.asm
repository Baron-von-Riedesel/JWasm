
;--- 32-bit sample: using Open Watcom's register calling convention
;--- assemble:   jwasm -zf1 owfc32.asm
;--- link Win32: wlink sys nt file owfc32.obj
;--- link Linux: wlink format elf runtime linux file owfc32.obj

    .386
    .model flat, fastcall

    includelib clib3r.lib
    includelib math387r.lib

    extern _cstart:near
    extern _fltused:near;to make wlink include floating-point support

UINT typedef DWORD

CStr macro text:VARARG
local x
    .const
x   db text,0
    .code
    exitm <offset x>
    endm

printf proto :ptr, :VARARG
strcpy proto :ptr, :ptr
memcpy proto :ptr, :ptr, len:UINT

    .data?

buffer  db 32 dup (?)

    .code

szText  db "abc",0
fl64    real8 2.5

testproc proc a1:UINT, a2:ptr, a3:UINT
    invoke printf, CStr("testproc arguments: 1=%u 2=%p 3=%u",10), a1, a2, a3
    ret
testproc endp

testdbl proc a1:REAL8
    invoke printf, CStr("double argument: %f",10), a1
    ret
testdbl endp

main proc argc:UINT,argv:ptr,argenv:ptr

LOCAL dst[32]:byte,src[32]:byte

    mov src, 0
    invoke strcpy, addr dst, addr src
    invoke memcpy, addr buffer, addr szText, sizeof szText
    invoke printf, CStr("string argument: '%s'",10, "integer argument: '%d'",10 ),
        addr buffer, 12345
    invoke testproc, 1, 2, 3
    invoke testdbl, fl64
    ret

main endp

end
