
;--- This is the 16bit version of a mixed-language sample.
;--- the main program is written in C (see Mixed1c.c), and assembly 
;--- supplies just 2 function - AsmFunc1 and AsmFunc2 - to be called.
;--- assemble: JWasm Mixed116.asm

    .286
    .model small

    .data?

tmpvar REAL8 ?

    .code

;--- AsmFunc1 returns a long.
;--- The return value is stored in register DX:AX.

AsmFunc1 proc c public p1:sword, p2:sword
    mov ax,p1
    mul p2
    ret
AsmFunc1 endp

;--- AsmFunc2 returns a double.
;--- In 16bit, there's no "standard" where to return a double value.
;--- One common method is to return a pointer to a static variable in AX
;--- (or DX:AX for "far" models).
;--- There's no guarantee that a true FPU is available. However, with 
;--- option -FPi one can make JWasm generate FP fixups. These allow to
;--- replace FPU instructions by emulation code if no FPU is installed.

AsmFunc2 proc c public p1:sword
    fild p1
    fsqrt
    fstp tmpvar
;   mov dx,seg tmpvar
    mov ax,offset tmpvar
    ret
AsmFunc2 endp

    end
