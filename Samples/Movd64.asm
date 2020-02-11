
;--- sample demonstrates usage of movd64 macro.
;--- assemble:
;---   jwasm -win64 Movd64.asm               or
;---   ml64  -c     Movd64.asm
;--- link:
;---   link /subsystem:console Movd64.obj msvcrt.lib

    option casemap:none

    include movd64.inc

printf proto :vararg

    .data

vq  dq 1
vd  dd 2
vw  dw 4
vb  db 8

    .code

szFmt1 db "byte moved",10,0
szFmt2 db "word moved",10,0
szFmt3 db "dword moved",10,0
szFmt4 db "qword moved",10,0

mainCRTStartup proc frame

    sub rsp,5*8
    .allocstack 5*8
    .endprolog
    movd64 al,vb
    movd64 vb,al
    mov ecx, offset szFmt1
    call printf
    movd64 ax,vw
    movd64 vw,ax
    mov ecx, offset szFmt2
    call printf
    movd64 eax,vd
    movd64 vd,eax
    mov ecx, offset szFmt3
    call printf
    movd64 rax,vq
    movd64 vq,rax
    mov ecx, offset szFmt4
    call printf
    add esp,5*8
    ret

mainCRTStartup endp

end
