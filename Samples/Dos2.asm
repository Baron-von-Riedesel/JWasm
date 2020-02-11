
;--- this is a 16bit sample for DOS. To create a simple DOS 16bit
;--- real-mode binary enter:
;---   JWasm -mz Dos2.asm
;--- or, if a linker is to be used:
;---   JWasm Dos2.asm
;---   wlink format dos file Dos2.obj

;--- To debug the sample with MS CodeView enter
;---   JWasm -Zi Dos2.asm
;---   link /CO Dos2.obj;
;---   cv Dos2.exe

;--- Optionally, the module can be linked as a DPMI 16bit protected-mode
;--- application. There are 2 ways to achieve this:
;--- 1. use Borland DOS extender:
;---   JWasm Dos2.asm
;---   tlink /Tx Dos2.obj;
;--- The resulting binary will need Borland's RTM.EXE and DPMI16BI.OVL.
;--- [To debug the application with TD run "JWasm /Zd Dos2.asm" and
;--- then run "tlink /Tx /v Dos2.obj".]
;--- 2. use HX DOS extender:
;---   JWasm Dos2.asm
;---   wlink format windows file Dos2.obj op stub=hdld16.bin
;---   patchne Dos2.exe
;--- The result is a 16bit DPMI application which includes a DPMI host.
;--- [To get files HDLD16.BIN and PATCHNE.EXE download HXDEV16.ZIP].

    .model small
    .stack 1024

    .data

text db 13,10,"Hello, world!",13,10,'$'

    .code

start:
    mov ax, @data
    mov ds, ax
    mov ah, 09h
    mov dx, offset text
    int 21h
    mov ax, 4c00h
    int 21h

    end start
