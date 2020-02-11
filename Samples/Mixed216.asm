
;--- 16-bit mixed-language sample.
;--- Main program is assembly, and CRT functions can be used.
;--- 1. Using MSVC v1.52
;---   assemble: jwasm Mixed216.asm
;---   link:     \msvc\bin\link Mixed216.obj,,,\msvc\lib\slibce;
;--- 2. Using Digital Mars C++
;---   assemble: jwasm Mixed216.asm
;---   link:     \dm\bin\link Mixed216.obj,,,\dm\lib\sds;
;--- 3. Using Open Watcom
;---   assemble: jwasm -zf1 -DOW Mixed216.asm
;---   link:     wlink sys dos file Mixed216.obj lib clibs

ifdef OW
    .model small, fastcall
    extern _cstart:near
else
    .model small, c
endif

printf proto :ptr BYTE, :VARARG

    .data

szHello db 10,"Hello, world!",10,0

    .code

main proc argc:word, argv:ptr

    invoke printf, addr szHello
    ret
main endp

    end
