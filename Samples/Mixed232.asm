
;--- 32-bit mixed-language sample.
;--- Main program is assembly, and CRT functions can be used.
;--- 1. Using MS VC
;---   assemble: jwasm -coff Mixed232.asm
;---   link:     link Mixed232.obj \msvc\lib\libc.lib /out:Mixed2.exe
;--- 2. Using Digital Mars C++
;---   assemble: jwasm -DDMC Mixed232.asm
;---   link:     \dm\bin\link Mixed232.obj,Mixed2.exe,,kernel32.lib user32.lib snn.lib;
;--- 3. Using Open Watcom ("stack-based" RTL)
;---   assemble: jwasm -zcw Mixed232.asm
;---   link:     wlink format windows nt runtime console 
;---                file mixed232.obj
;---                libpath \watcom\lib386\nt
;---                lib clib3s.lib, kernel32.lib, user32.lib 
;---                op start=mainCRTStartup, stack=0x10000, heap=0x10000
;--- 4. Using Open Watcom ("register-based" RTL)
;---   assemble: jwasm -zf1 -DOW Mixed232.asm
;---   link:     wlink format windows nt runtime console 
;---                file mixed232.obj
;---                libpath \watcom\lib386\nt
;---                lib clib3r.lib, kernel32.lib, user32.lib 
;---                op start=mainCRTStartup, stack=0x10000, heap=0x10000

    .386
ifdef OW
    .MODEL FLAT, fastcall
else
    .MODEL FLAT, c
endif
    option casemap:none

ifdef DMC
extern _acrtused_con:abs    ;tell Digital Mars OPTLINK what we want
endif

printf proto :ptr BYTE, :VARARG

    .CONST

szHello  db 10,"hello, world.",10,0

    .CODE

main proc

    invoke  printf, addr szHello
    xor     eax,eax
    ret
main endp

    END
