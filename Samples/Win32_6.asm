
;--- sample how to use Unicode in assembly
;--- assemble the ANSI version:    jwasm -coff Win32_6.ASM
;--- assemble the UNICODE version: jwasm -coff -DUNICODE Win32_6.ASM
;--- link:
;---  MS Link: link /subsystem:console Win32_6.OBJ kernel32.lib
;---  JWLink: jwlink format win pe file Win32_6.OBJ lib kernel32.lib

    .386
    .MODEL FLAT, stdcall
    option casemap:none

STD_OUTPUT_HANDLE equ -11

WriteConsoleA proto :dword, :dword, :dword, :dword, :dword
WriteConsoleW proto :dword, :dword, :dword, :dword, :dword
ifdef UNICODE
WriteConsole  equ <WriteConsoleW>
else
WriteConsole  equ <WriteConsoleA>
endif
GetStdHandle  proto :dword
ExitProcess   proto :dword

;--- macro function to define wide strings

ifdef UNICODE
L macro parms:VARARG
local wstr
    wstr textequ <>
    for parm,<parms>
      ifidn <">,@SubStr(parm,1,1)
%       forc chr$, <@SubStr(parm,2,@SizeStr(parm)-2)>
          ifnb wstr
             wstr CatStr wstr,<,>
          endif
          wstr CatStr wstr,<'&chr$'>
        endm
      else
        ifnb wstr
           wstr CatStr wstr,<,>
        endif
        wstr CatStr wstr,<parm>
      endif
    endm
    exitm <wstr>
endm
_T macro text:vararg
    exitm <L(text)>
endm
TCHAR typedef WORD
else
_T macro text:vararg
    exitm <text>
endm
TCHAR typedef BYTE
endif

    .CONST

string  TCHAR _T(13,10,"Hello, world.",13,10)

    .CODE

main proc

local   dwWritten:dword
local   hConsole:dword

    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov hConsole,eax
    invoke WriteConsole, hConsole, addr string, lengthof string, addr dwWritten, 0
    xor eax,eax
    ret
main endp

;--- entry

mainCRTStartup proc c

    invoke main
    invoke ExitProcess, eax

mainCRTStartup endp

    END mainCRTStartup
