
;--- sample how to use FPU and CRT math functions.
;--- Win32 binary:
;---   assemble: jwasm -coff Math1.asm crtexe.asm
;---   link:     link Math1.obj crtexe.obj msvcrt.lib
;--- Linux binary:
;---   assemble: jwasm -elf -D?CRT=0 -zcw Math1.asm
;---   link:     gcc -o Math1 Math1.o -lm

    .386
    .MODEL FLAT, stdcall
    option casemap:none

pow    proto c :REAL8, :REAL8
sqrt   proto c :REAL8
atof   proto c :ptr BYTE
printf proto c :ptr BYTE, :VARARG

;--- CStr(): macro to define a text constant

CStr macro text:VARARG
local x
    .const
x   db text,0
    .code
    exitm <offset x>
    endm

;--- CDbl(): macro to define a double constant

CDbl macro value
local x
    .const
x   real8 value
    .code
    exitm <x>
    endm

    .CODE

main proc c

local   result:REAL8

    fld CDbl(1.25)
    fadd CDbl(3.75)
    fstp result
    invoke printf, CStr("1.25 + 3.75 = %f",10), result

    fld CDbl(3.1)
    fsub CDbl(3.2)
    fstp result
    invoke printf, CStr("3.1 - 3.2 = %f",10), result

    fld CDbl(4.5)
    fmul CDbl(3.0)
    fstp result
    invoke printf, CStr("4.5 * 3 = %f",10), result

    fld CDbl(4.2)
    fdiv CDbl(3.0)
    fstp result
    invoke printf, CStr("4.2 / 3 = %f",10), result

;--- for CRT math functions, the result is returned in ST(0)
  
    invoke pow, CDbl(2.0), CDbl(3.0)
    fstp result
    invoke printf, CStr("2 ^ 3 = %f",10), result

    invoke sqrt, CDbl(2.0)
    fstp result
    invoke printf, CStr("sqrt(2) = %f",10), result

    invoke atof, CStr("3.567") ; convert a string into a double
    fstp result
    invoke printf, CStr('atof("3.567")=%f',10), result

    xor eax,eax
    ret

main endp

    END
