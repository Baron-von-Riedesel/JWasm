
;--- Res2Inc.asm.
;--- convert .RES file to assembly include file.
;--- this program uses C runtime functions

;--- Win32 binary:
;---  assemble: jwasm -c -coff res2inc.asm crtexe.asm
;---  link:     link res2inc.obj crtexe.obj msvcrt.lib

;--- Linux binary:
;---  assemble: jwasm -zcw -elf -D?MSC=0 -Fo res2inc.o res2inc.asm
;---  link:     gcc -o res2inc res2inc.o

    .386
    .MODEL FLAT, stdcall
    option casemap:none
    option proc:private

?USEDYN  equ 1  ;0=use static CRT, 1=use dynamic CRT
ifndef ?MSC
?MSC     equ 1  ;0=use gcc, 1=use ms CRT
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
qsort   proto c :ptr, :DWORD, :DWORD, :ptr

lf  equ 0Ah

LPSTR typedef ptr byte

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
_errno proto c            ;ms CRT
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

;--- .RES header
;---  MS 32-bit .RSRC file format if type + name ordinal

reshdr struct
size_    dd ?   ;size of resource data
hdrsize  dd ?   ;size of header (20h if both type and id are "by ordinal")
typef    dw ?   ;if -1, ordinal in restype
restype  dw ?   ;resource type
idf      dw ?   ;if -1. ordinal in id
id       dw ?   ;resource ID
dversion dd ?   ;data version
memflags dw ?   ;memory flags
langId   dw ?   ;language ID
version  dd ?   ;version
flags    dd ?   ;flags
reshdr ends

    .DATA

pszFileInp  LPSTR 0
pszFileOut  LPSTR 0

fVerbose    BYTE 0  ;display maximum msgs
fQuiet      BYTE 0  ;display no msgs
fGeneric    BYTE 0  ;generic syntax, no Masm struct initializer

    .CONST

szUsage label byte
    db "res2inc: convert compiled resource (.RES) file to assembly include file",lf
    db "usage: res2inc [options] src_file dst_file",lf
    db "  options:",lf
    db "    -v: verbose",lf
    db "    -q: quiet",lf
    db "    -g: generic (don't use Masm struct initializer)",lf
    db 0

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
    cmp ax,"g"
    jnz @F
    mov fGeneric, 1
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

;--- compare proc for qsort()

cmpproc proc c uses ebx item1:ptr, item2:ptr
    mov ebx, item1
    mov ebx, [ebx]
    mov edx, item2
    mov edx, [edx]
    movzx eax, [ebx].reshdr.restype
    movzx ecx, [edx].reshdr.restype
    sub eax, ecx
    jnz exit
    movzx eax, [ebx].reshdr.id
    movzx ecx, [edx].reshdr.id
    sub eax, ecx
    jnz exit
    movzx eax, [ebx].reshdr.langId
    movzx ecx, [edx].reshdr.langId
    sub eax, ecx
exit:
    ret
cmpproc endp

;--- convert content of buffer to include lines

WriteContent proc uses ebx esi edi pMem:ptr, dwSize:dword, hFile:dword

local cnt:dword
local hdrarray:dword
local dwTypes:dword
local dwIDs:dword
local dwLangs:dword
local currtype:dword
local currid:dword
local currlang:dword
local szLine[256]:byte

;--- first, scan the file buffer and create an array of resource headers
;--- onto the stack. EDI will hold the resource counter.

    mov esi,pMem
    mov ebx, esi
    add ebx, dwSize
    add esi, sizeof reshdr  ;skip NULL header
    mov cnt, 0
    .while (esi < ebx)

        push esi    ;store entry onto the stack

        ;--- currently, both type and id must be ordinal
        mov al,fVerbose
        lea edi, [esi].reshdr.typef
        .if ( word ptr [edi] != -1 )
            lea ecx, szLine
            .repeat
                mov ax,[edi]
                mov [ecx],al
                add edi,2
                inc ecx
            .until ( ax == 0 )
            mov ecx, esi
            sub ecx, pMem
            invoke printf, CStr("hdr at %4X: error! resource type %s not ordinal",lf), ecx, addr szLine
            mov al,0
        .else
            lea edi, [esi].reshdr.idf
        .endif
        .if ( word ptr [edi] != -1 )
            lea ecx, szLine
            .repeat
                mov ax,[edi]
                mov [ecx],al
                add edi,2
                inc ecx
            .until ( ax == 0 )
            mov ecx, esi
            sub ecx, pMem
            invoke printf, CStr("hdr at %4X: error! resource id %s not ordinal",lf), ecx, addr szLine
            mov al,0
        .endif
        .if ( al )
            mov eax, esi
            sub eax, pMem
            invoke printf, CStr("hdr at %4X: type=%2u, ID=%4u, lang=%X [ hdrsize=%X size=%4X memflags=%4X flags=%X ]",lf), eax,
                [esi].reshdr.restype, [esi].reshdr.id, [esi].reshdr.langId, [esi].reshdr.hdrsize, [esi].reshdr.size_, [esi].reshdr.memflags, [esi].reshdr.flags
        .endif
        mov ecx,[esi].reshdr.hdrsize
        add ecx, 4-1    ;align _size to dword
        and ecx, not (4-1)
        mov edx,[esi].reshdr.size_
        add edx, 4-1    ;align _size to dword
        and edx, not (4-1)
        add edx, ecx
        lea esi,[esi+edx]
        inc cnt
    .endw

;--- check if the current pointer is exactly at the file's end.

    mov eax, esi
    sub eax, pMem
    mov edx, ebx
    sub edx, pMem
    .if ( eax != edx )
        invoke printf, CStr("end reached: expected=%X, real=%X",lf), eax, edx
    .endif

    mov edi, cnt
    and edi, edi
    jz @exit

    mov hdrarray, esp

;--- sort the resource header array

    mov edx, esp
    invoke qsort, edx, edi, DWORD, offset cmpproc
    .if ( fVerbose )
        invoke printf, CStr("sort done",lf)
    .endif

if 0
;--- for debugging: print the sorted array
    mov esi, esp
    mov ebx, edi
    .while ebx
        lodsd
        mov ecx, eax
        sub ecx, pMem
        invoke printf, CStr("hdr at %8X: type=%2X, ID=%3X, lang=%4X",lf), ecx,
            [eax].reshdr.restype, [eax].reshdr.id, [eax].reshdr.langId
        dec ebx
    .endw
endif

    ;--- count resource types
    mov esi, hdrarray
    mov ebx, edi
    mov currtype, -1
    mov dwTypes, 0
    .while ebx
        lodsd
        movzx ecx, [eax].reshdr.restype 
        .if ( ecx != currtype )
            mov currtype, ecx
            inc dwTypes
        .endif
        dec ebx
    .endw

    ;--- first level, write resource directory and enum resource type entries

    .if ( fGeneric )
        invoke sprintf, addr szLine, CStr("@rsrc_start dw 0,0,0,0,0,0,0,%u",lf), dwTypes
    .else
        invoke sprintf, addr szLine, CStr("IMAGE_RESOURCE_DIRECTORY <0,0,0,0,0,%u>",lf), dwTypes
    .endif
    invoke fwrite, addr szLine, 1, eax, hFile
    mov esi, hdrarray
    mov ebx, edi
    mov currtype, -1
    .while ebx
        lodsd
        movzx ecx, [eax].reshdr.restype 
        .if ( ecx != currtype )
            mov currtype, ecx
            .if ( fGeneric )
                invoke sprintf, addr szLine, CStr("dd %u, @resource_type_%u + 80000000h - @rsrc_start",lf), ecx, ecx
            .else
                invoke sprintf, addr szLine, CStr("IMAGE_RESOURCE_DIRECTORY_ENTRY < <%u>, <SECTIONREL @resource_type_%u + 80000000h> >",lf), ecx, ecx
            .endif
            invoke fwrite, addr szLine, 1, eax, hFile
        .endif
        dec ebx
    .endw

    ;--- second level, write resource type directories and ID entries

    mov esi, hdrarray
    mov ebx, edi
    mov currtype, -1
    .while ebx
        lodsd
        movzx ecx, [eax].reshdr.restype 
        .if ( ecx != currtype )
            mov currtype, ecx
            push esi
            push ebx
            push eax
            mov dwIDs, 1
            movzx ecx, [eax].reshdr.id
            mov currid,ecx
            dec ebx
            .while ebx
                lodsd
                movzx ecx, [eax].reshdr.restype
                .break .if ecx != currtype
                movzx ecx, [eax].reshdr.id
                .if ( ecx != currid )
                    mov currid, ecx
                    inc dwIDs
                .endif
                dec ebx
            .endw
            .if ( fGeneric )
                invoke sprintf, addr szLine, CStr("@resource_type_%u dw 0,0,0,0,0,0,0,%u",lf), currtype, dwIDs
            .else
                invoke sprintf, addr szLine, CStr("@resource_type_%u IMAGE_RESOURCE_DIRECTORY <0,0,0,0,0,%u>",lf), currtype, dwIDs
            .endif
            invoke fwrite, addr szLine, 1, eax, hFile
            pop eax
            pop ebx
            pop esi
            push esi
            push ebx
            .while dwIDs
                dec dwIDs
                movzx ecx, [eax].reshdr.id
                mov currid, ecx
                .if ( fGeneric )
                    invoke sprintf, addr szLine, CStr("dd %u, @resource_id_%u + 80000000h - @rsrc_start",lf), ecx, ecx
                .else
                    invoke sprintf, addr szLine, CStr("IMAGE_RESOURCE_DIRECTORY_ENTRY < <%u>, <SECTIONREL @resource_id_%u + 80000000h> >",lf), ecx, ecx
                .endif
                invoke fwrite, addr szLine, 1, eax, hFile
                .break .if dwIDs == 0
                .repeat
                    lodsd
                    movzx edx, [eax].reshdr.id
                .until edx != currid
            .endw
            pop ebx
            pop esi
        .endif
        dec ebx
    .endw

    ;--- third level, write resource ID directories and language entries

    mov esi, hdrarray
    mov ebx, edi
    mov currid, -1
    .while ebx
        lodsd
        movzx ecx, [eax].reshdr.id
        .if ( ecx != currid )
            mov currid, ecx
            push esi
            push ebx
            push eax
            mov dwLangs, 1
            movzx ecx, [eax].reshdr.langId
            mov currlang,ecx
            dec ebx
            .while ebx
                lodsd
                movzx ecx, [eax].reshdr.id
                .break .if ecx != currid
                movzx ecx, [eax].reshdr.langId
                .if ( ecx != currlang )
                    mov currlang, ecx
                    inc dwLangs
                .endif
                dec ebx
            .endw
            .if ( fGeneric )
                invoke sprintf, addr szLine, CStr("@resource_id_%u dw 0,0,0,0,0,0,0,%u",lf), currid, dwLangs
            .else
                invoke sprintf, addr szLine, CStr("@resource_id_%u IMAGE_RESOURCE_DIRECTORY <0,0,0,0,0,%u>",lf), currid, dwLangs
            .endif
            invoke fwrite, addr szLine, 1, eax, hFile
            pop eax
            pop ebx
            pop esi
            push esi
            push ebx
            .while dwLangs
                dec dwLangs
                movzx ecx, [eax].reshdr.langId
                mov currlang, ecx
                .if ( fGeneric )
                    invoke sprintf, addr szLine, CStr("dd 0%Xh, @resource_id_%u_lang_%X - @rsrc_start",lf), currlang, currid, currlang
                .else
                    invoke sprintf, addr szLine, CStr("IMAGE_RESOURCE_DIRECTORY_ENTRY < <0%Xh>, <SECTIONREL @resource_id_%u_lang_%X> >",lf), currlang, currid, currlang
                .endif
                invoke fwrite, addr szLine, 1, eax, hFile
                .break .if dwLangs == 0
                .repeat
                    lodsd
                    movzx edx, [eax].reshdr.langId
                .until edx != currlang
            .endw
            pop ebx
            pop esi
        .endif
        dec ebx
    .endw

    ;--- last level, write resource data

    mov esi, hdrarray
    mov ebx, edi
    .while ebx
        lodsd
        push eax
        movzx ecx, [eax].reshdr.id
        movzx edx, [eax].reshdr.langId
        mov currid, ecx
        mov currlang, edx
        .if ( fGeneric )
            invoke sprintf, addr szLine, CStr("@resource_id_%u_lang_%X dd IMAGEREL @resource_id_%u_lang_%X_data, @size_resource_id_%u_lang_%X, 0, 0",lf), ecx, edx, ecx, edx, ecx, edx
        .else
            invoke sprintf, addr szLine, CStr("@resource_id_%u_lang_%X IMAGE_RESOURCE_DATA_ENTRY <IMAGEREL @resource_id_%u_lang_%X_data, @size_resource_id_%u_lang_%X, 0, 0>",lf), ecx, edx, ecx, edx, ecx, edx
        .endif
        invoke fwrite, addr szLine, 1, eax, hFile
        pop eax
        pushad
        mov ebx, [eax].reshdr.size_
        mov esi, [eax].reshdr.hdrsize
        add esi, eax
        lea edi, szLine
        invoke sprintf, addr szLine, CStr("@resource_id_%u_lang_%X_data "), currid, currlang
        add edi, eax
        .while ebx
            invoke sprintf, edi, CStr("db ")
            add edi, eax
            .if ( ebx > 16 )
                mov ecx, 16
            .else
                mov ecx, ebx
            .endif
            sub ebx, ecx
            .while ecx
                lodsb
                movzx eax, al
                push ecx
                invoke sprintf, edi, CStr("%u"), eax
                add edi, eax
                pop ecx
                dec ecx
                .if ( ecx )
                    mov al,','
                    stosb
                .endif
            .endw
            mov al,lf
            stosb
            lea eax, szLine
            sub edi, eax
            invoke fwrite, addr szLine, 1, edi, hFile
            lea edi, szLine
        .endw
        popad
        invoke sprintf, addr szLine, CStr("@size_resource_id_%u_lang_%X equ $ - @resource_id_%u_lang_%X_data",lf), currid, currlang, currid, currlang
        invoke fwrite, addr szLine, 1, eax, hFile
        invoke sprintf, addr szLine, CStr("align 4",lf)
        invoke fwrite, addr szLine, 1, eax, hFile
        dec ebx
    .endw

    lea esp, [esp+edi*4]

@exit:
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
        invoke printf, CStr("fopen('%s') failed [%u]",lf), pszFileInp, errno
        jmp main_ex
    .endif
    mov ebx, eax

    invoke fseek, ebx, 0, SEEK_END
    invoke ftell, ebx
    mov dwSize, eax
    invoke fseek, ebx, 0, SEEK_SET

    .if fVerbose
        invoke printf, CStr("res2inc: file '%s', size %u bytes",lf), pszFileInp, dwSize
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
        invoke printf, CStr("fread() failed [%u]",lf), errno
        jmp main_ex
    .endif

;--- open output file

    invoke fopen, pszFileOut, CStr("wb")
    .if ( !eax )
        invoke printf, CStr("fopen('%s') failed [%u]",lf), pszFileOut, errno
        jmp main_ex
    .endif
    mov ebx, eax

;--- process data and write output file

    invoke WriteContent, esi, dwSize, ebx

;--- cleanup

    invoke fclose, ebx

    invoke free, esi

    .if (!fQuiet)
        invoke printf, CStr("res2inc: file '%s' done",lf), pszFileInp
    .endif

    mov bError, 0
main_ex:
    mov eax, bError
    ret
displayusage:
    invoke printf, CStr("%s"), addr szUsage
    jmp main_ex

main endp

    END
