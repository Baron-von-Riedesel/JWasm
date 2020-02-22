
;--- jfc.asm.
;--- Very simple file compare. Public Domain.
;--- Mixed-language application (uses CRT)

;--- Win32 binary:
;--- assemble: jwasm -coff jfc.asm crtexe.asm
;--- link:     link jfc.obj crtexe.obj msvcrt.lib

;--- Linux binary:
;--- assemble: jwasm -zcw -elf -D?MSC=0 -Fo jfc.o jfc.asm
;--- link:     gcc -o jfc jfc.o

;--- v1.3: timestamp in export directory equalized
;--- v1.4: option -t added to compare text files

    .386
    .MODEL FLAT, c
    option casemap:none

    include winnt.inc

?USEDYN  equ 1  ;0=use static CRT, 1=use dynamic CRT
ifndef ?MSC
?MSC    equ 1  ;0=use gcc, 1=use ms CRT
endif

printf  proto c :ptr BYTE, :VARARG
fopen   proto c :ptr BYTE, :ptr BYTE
fclose  proto c :ptr
fseek   proto c :ptr, :DWORD, :DWORD
ftell   proto c :ptr
fread   proto c :ptr BYTE, :DWORD, :DWORD, :ptr
malloc  proto c :DWORD
free    proto c :ptr
atoi    proto c :ptr BYTE

SEEK_SET equ 0
SEEK_END equ 2

lf  equ 10

CStr macro text:VARARG
local xxx
    .const
xxx db text,0
    .code
    exitm <offset xxx>
    endm

;--- errno access
ife ?USEDYN
externdef c errno:dword   ; errno is global var
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

main proc c argc:dword, argv:ptr

local file1:dword
local filesize1:dword
local buffer1:dword
local header1:dword
local file2:dword
local filesize2:dword
local buffer2:dword
local header2:dword
local cnt:dword
local dwLine:dword
local fPE:byte
local fCoff:byte
local fText:byte

    xor eax, eax
    mov fPE, 0
    mov fCoff, 0
    mov fText, 0
    mov file1, eax
    mov file2, eax
;--- scan cmdline
    mov ebx,argv
    mov ecx, argc
    add ebx, 4
    dec ecx
    .while ( ecx )
        mov edx, [ebx]
        mov al,[edx]
        .if ( al == '-' || al == '/' )
            mov eax, [edx+1]
            movzx eax,ax
            or ax,2020h
            .if ( ax == "ep" )
                mov fPE, 1
            .elseif ( ax == "oc" )
                mov fCoff, 1
            .elseif ( ax == " t" )
                mov fText, 1
            .else
                invoke printf, CStr("unknown option",lf)
                mov eax,1
                ret
            .endif
        .elseif ( fText == 1 )
            push ecx
            invoke atoi, edx
            pop ecx
            mov dwLine, eax
            inc fText
        .elseif ( file1 == 0 )
            mov file1, edx
        .elseif ( file2 == 0 )
            mov file2, edx
        .else
            invoke printf, CStr("too many arguments",lf)
            mov eax,1
            ret
        .endif
        add ebx, 4
        dec ecx
    .endw

    .if ( file1 == 0 || file2 == 0 )
        invoke printf, CStr("jfc v1.4, Public Domain.",lf)
        invoke printf, CStr("jfc compares two (binary) files.",lf)
        invoke printf, CStr("usage: jfc [-co|-pe|-t <n>] file1 file2",lf)
        invoke printf, CStr("   -co: files in coff format, ignore timestamps",lf)
        invoke printf, CStr("   -pe: files in PE format, ignore timestamps",lf)
        invoke printf, CStr("   -t: files are plain text, ignore first <n> lines",lf)
        mov eax,1
        ret
    .endif

    mov cnt, 0
    mov ebx, file1
    invoke fopen, ebx, CStr("rb")
    .if ( !eax )
        invoke printf, CStr("open error file '%s' [%u]",lf), ebx, errno
        mov eax,1
        ret
    .endif
    mov ebx, eax
    invoke fseek, ebx, 0, SEEK_END
    invoke ftell, ebx
    mov filesize1, eax
    invoke fseek, ebx, 0, SEEK_SET
    mov eax, filesize1
    invoke malloc, eax
    .if ( eax == 0 ) 
        invoke printf, CStr("out of memory",lf)
        invoke fclose, ebx
        mov eax,1
        ret
    .endif
    mov buffer1, eax
    invoke fread, buffer1, 1, filesize1, ebx
    push eax
    invoke fclose, ebx
    pop eax
    .if ( eax != filesize1 )
        invoke printf, CStr("read error file '%s' [%u]",lf), file1, errno
        mov eax,1
        ret
    .endif

    mov ebx, file2
    invoke fopen, ebx, CStr("rb")
    .if ( !eax )
        invoke printf, CStr("open error file '%s' [%u]",lf), ebx, errno
        mov eax,1
        ret
    .endif
    mov ebx, eax
    invoke fseek, ebx, 0, SEEK_END
    invoke ftell, ebx
    mov filesize2, eax
    invoke fseek, ebx, 0, SEEK_SET
    mov eax, filesize2
    invoke malloc, eax
    .if ( eax == 0 ) 
        invoke printf, CStr("out of memory",lf)
        invoke fclose, ebx
        mov eax,1
        ret
    .endif
    mov buffer2, eax
    invoke fread, buffer2, 1, filesize2, ebx
    push eax
    invoke fclose, ebx
    pop eax
    .if ( eax != filesize2 )
        invoke printf, CStr("read error file '%s' [%u]",lf), file2, errno
        mov eax,1
        ret
    .endif

    mov esi, buffer1
    mov edi, buffer2

;--- when comparing PE binaries,
;--- 1. skip the MZ header
;--- 2. compare the PE header separately (without time stamp)
;--- 3. compare the rest

    .if ( fPE )
        mov ecx, file1
        mov eax, [esi].IMAGE_DOS_HEADER.e_lfanew
        add esi, eax
        cmp filesize1, eax
        jc faterr1
        cmp dword ptr [esi], "EP"
        jnz faterr1
        mov ecx, file2
        mov eax, [edi].IMAGE_DOS_HEADER.e_lfanew
        add edi, eax
        cmp filesize2, eax
        jc faterr1
        cmp dword ptr [edi], "EP"
        jnz faterr1

        mov eax, [esi].IMAGE_NT_HEADERS.OptionalHeader.SizeOfHeaders
        mov header1, eax
        mov eax, [edi].IMAGE_NT_HEADERS.OptionalHeader.SizeOfHeaders
        mov header2, eax

        movzx eax, [esi].IMAGE_NT_HEADERS.FileHeader.NumberOfSections
        mov ecx, sizeof IMAGE_SECTION_HEADER
        mul ecx
        add eax, sizeof IMAGE_OPTIONAL_HEADER32  ;32bit only!
        add eax, 20+4                   ;sizeof file header + 4
        mov ecx, eax

        mov eax, [esi].IMAGE_NT_HEADERS.FileHeader.TimeDateStamp
        mov [edi].IMAGE_NT_HEADERS.FileHeader.TimeDateStamp, eax

        push esi
        push edi
        call compare
        pop edi
        pop esi

;--- v1.3: dont compare timestamp in export directory
        mov eax, [esi].IMAGE_NT_HEADERS.OptionalHeader.DataDirectory[0].VirtualAddress   ;export directory
        and eax, eax
        jz noexp
        mov edx, [edi].IMAGE_NT_HEADERS.OptionalHeader.DataDirectory[0].VirtualAddress
        cmp edx, eax
        jnz noexp
        movzx ecx, [esi].IMAGE_NT_HEADERS.FileHeader.NumberOfSections
        lea edx, [esi+sizeof IMAGE_NT_HEADERS]
        .while ecx
            mov ebx,[edx].IMAGE_SECTION_HEADER.Misc.VirtualSize
            add ebx,[edx].IMAGE_SECTION_HEADER.VirtualAddress
            cmp eax,[edx].IMAGE_SECTION_HEADER.VirtualAddress
            jb @F
            cmp eax,ebx
            jae @F
            sub eax,[edx].IMAGE_SECTION_HEADER.VirtualAddress
            add eax,[edx].IMAGE_SECTION_HEADER.PointerToRawData
            mov esi,buffer1
            mov edi,buffer2
            mov edx, [esi+eax+4]        ;offset 4 is expdir timestamp
            mov [edi+eax+4],edx
            .break
@@:
            add edx,sizeof IMAGE_SECTION_HEADER
            dec ecx
        .endw
noexp:

        mov esi, buffer1
        mov edi, buffer2

        ;--- now prepare to compare the section contents
        mov ecx, file1
        mov eax, header1
        add esi, eax
        sub filesize1, eax
        jc faterr1
        mov ecx, file2
        mov eax, header2
        add edi, eax
        sub filesize2, eax
        jc faterr1
    .elseif ( fCoff )
        mov eax,[esi+4]     ;make timestamps equal
        mov [edi+4],eax
        ;--- todo: if codeview info is contained,
        ;--- don't compare the compiler info

;--- v1.4: compare text files, optionally starting with line x
    .elseif ( fText )
        mov ecx,filesize1
        mov edx,filesize2
        .while dwLine
            xchg esi,edi
            mov al,10
            repnz scasb
            jnz faterr2
            xchg esi,edi
            xchg ecx,edx
            mov al,10
            repnz scasb
            jnz faterr2
            xchg ecx,edx
            dec dwLine
        .endw
        mov filesize1,ecx
        mov filesize2,edx
    .endif

    mov eax, filesize1
    .if ( eax != filesize2 ) 
        invoke printf, CStr("%s, %s: file sizes differ",lf), file1, file2
        mov eax,1
        ret
    .endif

    mov ecx, eax
    call compare

    invoke free, buffer1
    invoke free, buffer2

    mov eax, cnt
    and eax, eax
    setnz al
    movzx eax,al
    ret

compare:
    ;--- compare a block ( esi, edi, ecx )
    .while ( ecx )

        repz cmpsb

        setnz al
        movzx eax, al
        add cnt, eax

        .if ( eax )
            push ecx
            mov edx, esi
            dec edx
            sub edx, buffer1
            movzx eax,byte ptr [esi-1]
            movzx ecx,byte ptr [edi-1]
            invoke printf, CStr("%08Xh: %02X %02X (%s %s)",lf), edx, eax, ecx, file1, file2
            pop ecx
        .endif
    .endw
    retn

faterr2:
    invoke printf, CStr("files don't have that many lines",lf)
    mov eax, 1
    ret
faterr1:
    invoke printf, CStr("invalid PE binary: %s",lf), ecx
    mov eax, 1
    ret
    align 4

main endp

    END
