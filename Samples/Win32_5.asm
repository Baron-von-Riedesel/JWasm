
;--- Win32 "hello world" console application.
;--- Uses JWasm's bin output format, so no linker needed.
;--- assemble: JWasm -bin -Fo Win32_5.exe Win32_5.ASM

    .386
    option casemap:none

    .nolist
    include winnt.inc   ;include PE image definitions
    .list

STD_OUTPUT_HANDLE equ -11

IMAGEBASE equ 400000h

PEHDR segment dword FLAT

;--- define the DOS "MZ" header

    ORG IMAGEBASE

    IMAGE_DOS_HEADER <"ZM", 80h, 1, 0,4,0,-1,0,200h,0,0,0,0,0,<0>,0,0,<0>,IMAGEREL PEHdr>

    db 0Eh         ;push cs
    db 1Fh         ;pop ds
    db 0BAh,0Eh,0  ;mov dx,text
    db 0B4h,09h    ;mov ah,9
    db 0CDh,21h    ;int 21h
    db 0B8h,01h,4Ch;mov ax,4c01h
    db 0CDh,21h    ;int 21h
    db "This program cannot be run in DOS mode",13,10,'$'

    ORG IMAGEBASE+80h

;--- define the Win32 "PE" header

PEHdr label byte
    db "PE",0,0
    IMAGE_FILE_HEADER <IMAGE_FILE_MACHINE_I386, num_sections, 0, 0, 0, sizeof IMAGE_OPTIONAL_HEADER32,\
        IMAGE_FILE_RELOCS_STRIPPED or IMAGE_FILE_EXECUTABLE_IMAGE or IMAGE_FILE_32BIT_MACHINE or IMAGE_FILE_LOCAL_SYMS_STRIPPED>

    IMAGE_OPTIONAL_HEADER32 { 10Bh, ;magic
        6,0,                        ;linker major, minor
        1000h,1000h,0,              ;sizeof code, initialized data, uninitialized data
        IMAGEREL mainCRTStartup,    ;entry point
        IMAGEREL start_text, IMAGEREL start_rdata,  ;baseof code, data
        IMAGEBASE,    ;imagebase
        1000h,200h,   ;section alignment, file alignment
        4,0,          ;OS major, minor
        0,0,          ;Image major, minor
        4,0,          ;Subsys major, minor
        0,            ;win32 version
        3000h,        ;sizeof image
        1000h,        ;sizeof header
        0,            ;checksum
        IMAGE_SUBSYSTEM_WINDOWS_CUI,
        0,            ;dll characteristics
        100000h,1000h,;stack res,com
        100000h,1000h,;heap res, com
        0,            ;loader flags
        16,           ;number of directories
        < <0,0>,\        ;0 exports
        < IMAGEREL start_idata, SECTIONREL endof_idata >,\ ;1 imports
        <0,0>,<0,0>,\    ;2 resource, 3 exception
        <>,<>,<>,<>,\    ;4 security, 5 baserelocs, 6 debug, 7 architecture
        <>,<>,<>,<>,\    ;8 globalptr, 9 tls, 10 load_config, 11 bound_import
        <>,<>,<>,<> >}   ;12 iat, 13 delay_import, 14 com descriptor, 15 reserved

;--- define the section table

sectiontable label byte
    IMAGE_SECTION_HEADER <".text", <sizeof_text>, IMAGEREL start_text, sizeof_text,\
        200h, 0, 0, 0, 0, 060000020h >
    IMAGE_SECTION_HEADER <".rdata", <SECTIONREL endof_idata + sizeof_const>, IMAGEREL start_rdata, SECTIONREL endof_idata + sizeof_const,\
        400h, 0, 0, 0, 0, 040000040h >
num_sections equ ( $ -  sectiontable ) / sizeof IMAGE_SECTION_HEADER

    ORG IMAGEBASE+200h   ;forces physical size of header to 200h and sets VA to 400200h

PEHDR ends

;--- the ALIGNx segments are needed because
;--- section alignment and file alignment are different

ALIGN1 segment dword public FLAT 'DATA'
    ORG 0E00h   ; change pc to RVA 1000h
ALIGN1 ends

_TEXT segment dword public FLAT 'CODE'
_TEXT ends

ALIGN2 segment dword public FLAT 'DATA'
    ORG 0E00h   ; change pc to RVA 2000h
ALIGN2 ends

_IDATA segment dword public FLAT 'DATA'
start_rdata label byte
start_idata label byte
;--- import descriptors go here
_IDATA ends
_IDATA$1 segment dword public FLAT 'DATA'
    IMAGE_IMPORT_DESCRIPTOR <<0>,0,0,0,0>
;--- ILT entries go here
_IDATA$1 ends
_IDATA$2 segment dword public FLAT 'DATA'
    dd 0    ;--- end of last ILT
;--- IAT entries go here
_IDATA$2 ends
_IDATA$3 segment dword public FLAT 'DATA'
    dd 0    ;--- end of last IAT
;--- import name strings go here
_IDATA$3 ends
_IDATA$4 segment dword public FLAT 'DATA'
endof_idata equ $
_IDATA$4 ends

CONST segment dword public FLAT 'DATA'
start_const label byte
CONST ends

DefineImpDll macro name
_IDATA segment
    IMAGE_IMPORT_DESCRIPTOR <<IMAGEREL name&ILT>,0,0,IMAGEREL name, IMAGEREL name&IAT>
_IDATA ends
_IDATA$1 segment
ifdef ImportDefined
    dd 0  ;terminate previous ILT
endif
name&ILT label dword
_IDATA$1 ends
_IDATA$2 segment
ifdef ImportDefined
    dd 0  ;terminate previous IAT
endif
name&IAT label dword
_IDATA$2 ends
_IDATA$3 segment
name db @CatStr(!",name, !"),0
    align 4
_IDATA$3 ends
ImportDefined equ 1
    endm

DefineImport macro name
_IDATA$1 segment
    dd IMAGEREL n&name
_IDATA$1 ends
_IDATA$2 segment
lp&name typedef ptr pr&name
name    lp&name IMAGEREL n&name
_IDATA$2 ends
_IDATA$3 segment
n&name dw 0
    db @CatStr(!",name, !"),0
    align 4
_IDATA$3 ends
    endm

prWriteConsoleA typedef proto stdcall :dword, :dword, :dword, :dword, :dword
prGetStdHandle  typedef proto stdcall :dword
prExitProcess   typedef proto stdcall :dword

    DefineImpDll kernel32
    DefineImport ExitProcess
    DefineImport WriteConsoleA
    DefineImport GetStdHandle

if 0 ;if further dlls are to be imported
prMessageBoxA   typedef proto stdcall :dword, :dword, :dword, :dword

    DefineImpDll user32
    DefineImport MessageBoxA
endif

CONST segment

string  db 13,10,"hello, world.",13,10

sizeof_const equ $ - start_const

CONST ends

_TEXT segment

    assume ds:FLAT,es:FLAT

start_text label near

;--- start of program

main proc

local dwWritten:dword
local hConsole:dword

    invoke  GetStdHandle, STD_OUTPUT_HANDLE
    mov     hConsole,eax

    invoke  WriteConsoleA, hConsole, addr string, sizeof string, addr dwWritten, 0

    xor     eax,eax
    ret
main endp

;--- entry

mainCRTStartup proc c

    invoke  main
    invoke  ExitProcess, eax

mainCRTStartup endp

sizeof_text equ $ - start_text

    ORG 200h    ;align size of _TEXT to next 512 byte boundary

_TEXT ends

    END
