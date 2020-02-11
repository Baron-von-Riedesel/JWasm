
;--- Html2Txt.asm
;--- very simple html to (ascii) text converter. Public Domain.
;--- it's a sample for a mixed-language application (uses CRT)

;--- Win32 binary:
;--- assemble: jwasm -coff html2txt.asm crtexe.asm
;--- link:     link html2txt.obj crtexe.obj msvcrt.lib

;--- Linux binary:
;--- assemble: jwasm -zcw -elf -D?MSC=0 -Fo html2txt.o html2txt.asm
;--- link:     gcc -o html2txt html2txt.o

    .386
    .MODEL FLAT, c
    option casemap:none

?USEDYN  equ 1  ;0=use static CRT, 1=use dynamic CRT
ifndef ?MSC
?MSC     equ 1  ;0=use gcc, 1=use ms CRT
endif

printf  proto c :ptr BYTE, :VARARG
fopen   proto c :ptr BYTE, :ptr BYTE
fclose  proto c :ptr
fseek   proto c :ptr, :DWORD, :DWORD
ftell   proto c :ptr
fread   proto c :ptr BYTE, :DWORD, :DWORD, :ptr
fwrite  proto c :ptr BYTE, :DWORD, :DWORD, :ptr
strcat  proto c :ptr BYTE, :ptr BYTE
strcpy  proto c :ptr BYTE, :ptr BYTE
strlen  proto c :ptr BYTE
malloc  proto c :DWORD
free    proto c :ptr

SEEK_SET equ 0
SEEK_END equ 2
NULL     equ 0

lf  equ 10
cr  equ 13

CStr macro text
local xxx
    .const
xxx db text,0
    .code
    exitm <offset xxx>
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

    .CODE
;--- convert html text found in buffer
;--- 1. skip anything between angle brackets (<>)
;--- 2. translate &lt; and &gt; to '<' and '>'
;--- if a line contains tags only, it's skipped as a whole, including EOL
convertbuffer proc uses ebx esi edi buffer:ptr BYTE, size_:DWORD, psize:ptr DWORD

local outb:dword
local intag:byte
local taginline:byte
local tagoccured:byte
local cnt:word
local startline:dword

    invoke malloc, size_
    .if ( eax )
        mov ebx, eax
        mov edi, eax
        mov startline, edi
        mov esi, buffer
        mov cnt, 0
        mov tagoccured,0
        lodsb
        .while (al)
            .if ( al == '<' )
                mov intag,1
                mov taginline,1
            .endif
            .if ( intag == 0 )
                .if ( al == '&' )
                    .if ( word ptr [esi] == 'tl' && byte ptr [esi+2] == ';' )
                        add esi,3
                        mov al,'<'
                    .elseif ( word ptr [esi] == 'tg' && byte ptr [esi+2] == ';' )
                        add esi,3
                        mov al,'>'
                    .elseif ( word ptr [esi] == 'ma' && word ptr [esi+2] == ';p' )
                        add esi,4
                        mov al,'&'
                    .endif
                .endif
                ;.if ( tagoccured && al != lf && al != cr )
                ;    push eax
                ;    mov al,' '
                ;    stosb
                ;    pop eax
                ;    mov tagoccured, 0
                ;.endif
                stosb
                .if ( al == lf )
                    ; skip line if it contains just a tag
                    .if ( cnt == 0 && taginline )
                        mov edi, startline
                    .endif
                    mov cnt, 0
                    mov taginline, 0
                    mov tagoccured, 0
                    mov startline, edi
                .elseif ( al != cr )
                    inc cnt
                .endif
            .elseif ( al == '>')
                mov intag,0
                .if ( cnt )
                    mov tagoccured,1
                .endif
            .endif
            lodsb
        .endw
        mov eax, ebx
        sub edi, eax
        mov ecx, psize
        mov [ecx], edi
    .endif
    ret
    align 4
convertbuffer endp

main proc c argc:dword, argv:ptr ptr

local filesize:dword
local buffer:dword
local outbuf:dword
local outbsize:dword
local fname[260]:byte

    .if ( argc < 2 )
        invoke printf, CStr(<"html2txt v1.1, Public Domain.",lf>)
        invoke printf, CStr(<"html2txt is a html to text converter.",lf>)
        invoke printf, CStr(<"usage: html2txt input_file [output_file]",lf>)
        mov eax,1
        ret
    .endif
    mov ebx,argv
    mov ebx,[ebx+1*4]
    invoke fopen, ebx, CStr("rb")
    .if ( eax )
        mov ebx, eax
        invoke fseek, ebx, 0, SEEK_END
        invoke ftell, ebx
        mov filesize, eax
        invoke fseek, ebx, 0, SEEK_SET
        mov eax, filesize
        inc eax
        invoke malloc, eax
        .if ( eax == 0 ) 
            invoke printf, CStr(<"out of memory",lf>)
            invoke fclose, ebx
            mov eax,1
            ret
        .endif
        mov buffer, eax
        invoke fread, buffer, 1, filesize, ebx
        push eax
        invoke fclose, ebx
        pop eax
        .if ( eax != filesize )
            invoke printf, CStr(<"read error [%u]",lf>), errno
            mov eax,1
            ret
        .endif
        mov edx, buffer
        mov byte ptr [edx+eax],0
        invoke convertbuffer, buffer, filesize, addr outbsize
        push eax
        invoke free, buffer
        pop eax
        .if ( eax )
            mov outbuf, eax
            mov edx, argv
            mov ebx, [edx+1*4]
            .if ( argc == 2 )
                invoke strlen, ebx
                add eax, ebx
                .while (eax != ebx && \
                        byte ptr [eax-1] != ':' && \
                        byte ptr [eax-1] != '\' && \
                        byte ptr [eax-1] != '/')
                    dec eax
                .endw
                lea ebx, fname
                invoke strcpy, ebx, eax
                invoke strcat, ebx, CStr(".txt")
            .else
                mov ebx, argv
                mov ebx, [ebx+2*4]
            .endif
            invoke fopen, ebx, CStr("wb")
            .if ( eax )
                mov ebx, eax
                invoke fwrite, outbuf, 1, outbsize, ebx
                .if ( eax != outbsize )
                    invoke printf, CStr(<"write error [%u]",lf>), errno
                .endif
                invoke fclose, ebx
                invoke printf, CStr(<"Done. %u bytes written",lf>), outbsize
            .else
                invoke printf, CStr(<"open('%s') failed [%u]",lf>), ebx, errno
            .endif
            invoke free, outbuf
        .endif
    .else
        invoke printf, CStr(<"open('%s') failed [%u]",lf>), ebx, errno
    .endif
    xor eax,eax
    ret
    align 4

main endp

    END
