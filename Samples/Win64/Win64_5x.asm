
;--- Win64 console application with exception handler, uses WinInc v2+
;--- similiar to Win64_5.asm, but uses msvcrt functions for output.
;--- assemble: jwasm -c -win64 -Zp8 Win64_5x.asm
;--- link: link /subsystem:console /Libpath:\WinInc\Lib64 Win64_5x.obj

    option casemap:none
    option frame:auto

    .nolist
    .nocref
WIN32_LEAN_AND_MEAN equ 1
    include \WinInc\Include\windows.inc
    include \WinInc\Include\stdio.inc
    include \WinInc\Include\stdlib.inc
    .list
    .cref

    includelib <msvcrt.lib>

;--- CStr(): macro function to simplify defining a string

CStr macro Text:VARARG
local szText
    .const
szText  db Text,0
    .code
    exitm <offset szText>
endm

    .CODE

exchdl proc FRAME pRecord:ptr EXCEPTION_RECORD64, ulframe:qword, pContext:ptr, x4:ptr

    add qword ptr [r8].CONTEXT.Rip_, 1  ;1=size of "in EAX, DX" opcode
    invoke printf, CStr("exception code: %X",10), [rcx].EXCEPTION_RECORD64.ExceptionCode
    mov eax, 0  ;0=continue execution?
    ret

exchdl endp

VMwareInstalled proc FRAME:exchdl uses rbx 

    mov eax, 0564D5868h
    mov ebx, 08685D465h
    mov ecx, 10
    mov dx, 05658h
    in eax, dx
    cmp ebx, 564D5868h
    setz al
    movzx eax,al
    ret

VMwareInstalled endp

main proc FRAME

    invoke VMwareInstalled
    .if ( eax )
        lea rax, CStr("running in VMware")
    .else
        lea rax, CStr("NOT running in VMware")
    .endif
    invoke printf, CStr("%s",10), rax
    ret

main endp

mainCRTStartup proc FRAME
    invoke main
    invoke exit, eax
mainCRTStartup endp

    END mainCRTStartup
