
;--- demonstration of COMDAT sections.
;--- all procedures are put in separate COMDAT sections.
;--- this allows the linker to remove unreferenced items.
;--- assemble:
;---   jwasm -coff comdat.asm
;--- link:
;---   link comdat.obj /libpath:\wininc\lib

    .486
    .model flat, stdcall

STD_OUTPUT_HANDLE equ -11

WriteConsoleA proto :dword, :dword, :dword, :dword, :dword
GetStdHandle  proto :dword
ExitProcess   proto :dword

    includelib <kernel32.lib>

;--- for better readability the usage of COMDAT will
;--- be hidden in macros PROC_ and ENDP_

PROC_ macro name:label, args:vararg
_TEXT_&name& segment flat alias(".text") comdat(1) 'CODE'
name proc args
endm

ENDP_ macro name:label
name endp
_TEXT_&name& ends
endm

    .CONST

string  db 13,10,"hello, world.",13,10

    .code

;--- the following procedure won't make it to the final binary.

unused PROC_ c w1:dword, w2:dword

    mov eax, w1
    mov ecx, w2
    add eax, ecx
    ret

unused ENDP_


main PROC_ c

local   dwWritten:dword
local   hConsole:dword

    invoke  GetStdHandle, STD_OUTPUT_HANDLE
    mov     hConsole,eax

    invoke  WriteConsoleA, hConsole, addr string, sizeof string, addr dwWritten, 0

    xor     eax,eax
    ret
main ENDP_


mainCRTStartup PROC_ c
    call main
    invoke ExitProcess, 0
    ret
mainCRTStartup ENDP_

end mainCRTStartup
