
;--- Bin2Inc.asm.
;--- convert binary file to assembly include file.
;--- this program uses C runtime functions

;--- Win32 binary:
;---  assemble: jwasm -c -coff bin2inc.asm crtexe.asm
;---  link:     link bin2inc.obj crtexe.obj msvcrt.lib

;--- Linux binary:
;---  assemble: jwasm -zcw -elf -D?MSC=0 -Fo bin2inc.o bin2inc.asm
;---  link:     gcc -o bin2inc bin2inc.o

    .386
    .MODEL FLAT, stdcall
    option casemap:none
    option proc:private

?USEDYN  equ 1  ;0=use static CRT, 1=use dynamic CRT
ifndef ?MSC
?MSC    equ 1  ;0=use gcc, 1=use ms CRT
endif

SEEK_SET equ 0
SEEK_END equ 2

fopen   proto c :ptr BYTE, :ptr BYTE
fclose  proto c :ptr
fseek   proto c :ptr, :DWORD, :DWORD
ftell   proto c :ptr
fread   proto c :ptr BYTE, :DWORD, :DWORD, :ptr
fwrite  proto c :ptr BYTE, :DWORD, :DWORD, :ptr
printf  proto c :ptr byte, :vararg
sprintf proto c :ptr byte, :ptr byte, :vararg

malloc  proto c :DWORD
free    proto c :ptr

lf  equ 0Ah
cr  equ 0Dh

PSTR typedef PTR BYTE

CStr macro text:VARARG
local x
    .const
x   db text,0
    .code
    exitm <offset x>
    endm

;--- errno access
ife ?USEDYN
externdef c errno:dword   ;errno is global var
else
__errno macro
;--- if errno is to be defined as a function call
 if ?MSC
_errno proto c            ;ms crt
    call _errno
 else
__errno_location proto c  ;gcc
    call __errno_location
 endif
    mov eax,[eax]
    exitm <eax>
    endm
errno textequ <__errno()>
endif

    .DATA

pszFileInp  PSTR 0
pszFileOut  PSTR 0

fVerbose    BYTE 0      ;display maximum msgs
fQuiet      BYTE 0

    .CONST

szLF    db lf,0

    .CODE

;--- scan command line for options

getoption proc uses esi pszArgument:ptr byte

    mov esi, pszArgument
    mov eax,[esi]
    cmp al,'/'
    jz @F
    cmp al,'-'
    jnz getoption_1
@@:
    shr eax,8
    or al,20h
    cmp ax,"v"
    jnz @F
    mov fVerbose, 1
    jmp done
@@:
    cmp ax,"q"
    jnz @F
    mov fQuiet, 1
    jmp done
@@:
    jmp error
getoption_1:
    .if (!pszFileInp)
        mov pszFileInp, esi
    .elseif (!pszFileOut)
        mov pszFileOut, esi
    .else
        jmp error
    .endif
done:
    clc
    ret
error:
    stc
    ret

getoption endp

;--- convert content of buffer to include lines

WriteContent proc uses ebx esi edi pMem:ptr, dwSize:dword, hFile:dword

local   szLine[80]:byte

    mov esi,pMem
    mov ecx,dwSize
    mov ebx,0

;--- write 16 bytes / line

    .while (ecx >= 16)
        push ecx
        mov ecx, 16
        sub esp, 16*4
        mov edi, esp
        xor eax, eax
@@:
        lodsb
        stosd
        loop @B
        invoke sprintf, addr szLine, CStr("db %3u,%3u,%3u,%3u,%3u,%3u,%3u,%3u,%3u,%3u,%3u,%3u,%3u,%3u,%3u,%3u",lf )
        add esp, 16*4
        invoke fwrite, addr szLine, 1, eax, hFile
        pop ecx
        sub ecx,16
    .endw

;--- write remainder

    .if (ecx)
        push ecx
        lea ebx, szLine
        invoke sprintf, ebx, CStr("db ")
        add ebx, eax
        pop ecx
        .repeat
            push ecx
            xor eax, eax
            lodsb
            invoke sprintf, ebx, CStr("%3u"), eax
            pop ecx
            add ebx, eax
            mov byte ptr [ebx],','
            inc ebx
            dec ecx
        .until (ecx == 0)
        mov word ptr [ebx-1],lf
        lea eax, szLine
        sub ebx, eax
        invoke fwrite, eax, 1, ebx, hFile
    .endif
    ret

WriteContent endp

;*** main proc ***

main proc c public argc:dword, argv:ptr

local   dwWritten:DWORD
local   dwSize:DWORD
local   bError:DWORD

    mov bError, 1
    cmp argc,2
    jb displayusage
    mov ecx, 1
    mov ebx,argv
    .while (ecx < argc)
        push ecx
        invoke getoption, dword ptr [ebx+ecx*4]
        pop ecx
        jc displayusage
        inc ecx
    .endw
    cmp pszFileOut, 0
    jz displayusage

;--- open and read input file

    invoke fopen, pszFileInp, CStr("rb")
    .if ( !eax )
        invoke printf, CStr("fopen('%s') failed [%X]",lf), pszFileInp, errno
        jmp main_ex
    .endif
    mov ebx, eax

    invoke fseek, ebx, 0, SEEK_END
    invoke ftell, ebx
    mov dwSize, eax
    invoke fseek, ebx, 0, SEEK_SET

    .if fVerbose
        invoke printf, CStr("Bin2Inc: file '%s', size %u bytes",lf), pszFileInp, dwSize
    .endif

    invoke malloc, dwSize
    .if (!eax)
        invoke fclose, ebx
        invoke printf, CStr("out of memory",lf)
        jmp main_ex
    .endif
    mov esi, eax

    invoke fread, esi, 1, dwSize, ebx
    push eax
    invoke fclose, ebx
    pop eax
    .if ( eax != dwSize )
        invoke printf, CStr("fread() failed [%X]",lf), errno
        jmp main_ex
    .endif

;--- open output file

    invoke fopen, pszFileOut, CStr("wb")
    .if ( !eax )
        invoke printf, CStr("fopen('%s') failed [%X]",lf), pszFileOut, errno
        jmp main_ex
    .endif
    mov ebx, eax

;--- process data and write output file

    invoke WriteContent, esi, dwSize, ebx

;--- cleanup

    invoke fclose, ebx

    invoke free, esi

    .if (!fQuiet)
        invoke printf, CStr("Bin2Inc: file '%s' done",lf), pszFileInp
    .endif

    mov bError, 0
main_ex:
    mov eax, bError
    ret
displayusage:
    invoke printf, CStr("Bin2Inc: convert binary file to assembly include file",lf)
    invoke printf, CStr("usage: Bin2Inc [options] src_file dst_file",lf)
    invoke printf, CStr("  options:",lf)
    invoke printf, CStr("    -v: verbose",lf)
    invoke printf, CStr("    -q: quiet",lf)
    jmp main_ex

main endp

    END
