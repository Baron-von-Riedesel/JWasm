
;--- Win64 console application with exception handler, uses WinInc v2+
;--- assemble: jwasm -c -win64 -Zp8 Win64_5.asm
;--- link: link /subsystem:console /Libpath:\WinInc\Lib64 Win64_5.obj

    option casemap:none
    option frame:auto

    .nolist
    .nocref
WIN32_LEAN_AND_MEAN equ 1
    include \WinInc\Include\windows.inc
    .list
    .cref

    includelib <kernel32.lib>

;--- CStr(): macro function to simplify defining a string

CStr macro Text:VARARG
local szText
    .const
szText  db Text,0
    .code
    exitm <offset szText>
endm

    .CODE

exchdl proc pRecord:ptr, ulframe:qword, pContext:ptr, x4:ptr

    add qword ptr [r8].CONTEXT.Rip_, 1  ;1=size of "in EAX, DX" opcode
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

main proc FRAME uses rbx rsi rdi

local dwWritten:DWORD

    invoke GetStdHandle,STD_OUTPUT_HANDLE
    mov rbx,rax
    invoke VMwareInstalled
    .if ( eax )
        lea rsi, CStr("running in VMware",13,10)
    .else
        lea rsi, CStr("NOT running in VMware",13,10)
    .endif
    invoke lstrlen, rsi
    mov edi, eax
    invoke WriteConsoleA, rbx, rsi, edi, addr dwWritten, 0
    ret

main endp

mainCRTStartup proc FRAME
    invoke main
    invoke ExitProcess, eax
mainCRTStartup endp

    END mainCRTStartup
