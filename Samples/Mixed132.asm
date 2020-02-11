
;--- This is the 32bit version of a mixed-language sample.
;--- the main program is written in C (see Mixed1c.c), and assembly 
;--- supplies just 2 function - AsmFunc1 and AsmFunc2 - to be called.
;--- assemble: jwasm -coff Mixed132.asm

    .386
    .model flat

    .code

;--- AsmFunc1 returns a long.
;--- The return value is stored in register EAX.

AsmFunc1 proc c public p1:sdword, p2:sdword
    mov eax,p1
    mul p2
    ret
AsmFunc1 endp

;--- AsmFunc2 returns a double.
;--- The return value is stored in register ST0.
;--- On a 80386, which has no built-in FPU, the CRT will install
;--- an FP emulator if no physical FPU is available.

AsmFunc2 proc c public p1:sdword
    fild p1
    fsqrt
    ret
AsmFunc2 endp

    end
