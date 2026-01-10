
;--- Win64 console application with exception handler.
;--- this variant can be assembled by both JWasm and ML64.
;--- assemble: jwasm -c Win64_5m.asm
;---           ml64 -c Win64_5m.asm
;--- link: link /subsystem:console /Libpath:\WinInc\Lib64 Win64_5m.obj

    option casemap:none

    includelib <msvcrt.lib>

exit   proto
printf proto

;--- CStr(): macro function to simplify defining a string

CStr macro Text:VARARG
local szText
    .const
szText  db Text,0
    .code
    exitm <offset szText>
endm

EXCEPTION_MAXIMUM_PARAMETERS EQU 15
DWORD64 typedef QWORD

EXCEPTION_RECORD64  struct
ExceptionCode       DWORD ?
ExceptionFlags      DWORD ?
ExceptionRecord     DWORD64 ?
ExceptionAddress    DWORD64 ?
NumberParameters    DWORD ?
__unusedAlignment   DWORD ?
ExceptionInformation DWORD64 EXCEPTION_MAXIMUM_PARAMETERS dup (?)
EXCEPTION_RECORD64  ends

M128 struct
Low_     QWORD ?
High_    QWORD ?
M128 ends

LEGACY_SAVE_AREA struct
ControlWord WORD ?
Reserved0   WORD ?
StatusWord  WORD ?
Reserved1   WORD ?
TagWord     WORD ?
Reserved2   WORD ?
ErrorOffset DWORD ?
ErrorSelector WORD ?
ErrorOpcode WORD ?
DataOffset  DWORD ?
DataSelector WORD ?
Reserved3   WORD ?
FloatRegisters BYTE 8*10 dup (?)
LEGACY_SAVE_AREA ends

CONTEXT struct
P1Home  DWORD64 ?
P2Home  DWORD64 ?
P3Home  DWORD64 ?
P4Home  DWORD64 ?
P5Home  DWORD64 ?
P6Home  DWORD64 ?
ContextFlags    DWORD   ?
MxCsr   DWORD   ?
SegCs   WORD    ?
SegDs   WORD    ?
SegEs   WORD    ?
SegFs   WORD    ?
SegGs   WORD    ?
SegSs   WORD    ?
EFlags  DWORD   ?
Dr0_    DWORD64 ?
Dr1_    DWORD64 ?
Dr2_    DWORD64 ?
Dr3_    DWORD64 ?
Dr6_    DWORD64 ?
Dr7_    DWORD64 ?
Rax_    DWORD64 ?
Rcx_    DWORD64 ?
Rdx_    DWORD64 ?
Rbx_    DWORD64 ?
Rsp_    DWORD64 ?
Rbp_    DWORD64 ?
Rsi_    DWORD64 ?
Rdi_    DWORD64 ?
R8_ DWORD64 ?
R9_ DWORD64 ?
R10_    DWORD64 ?
R11_    DWORD64 ?
R12_    DWORD64 ?
R13_    DWORD64 ?
R14_    DWORD64 ?
R15_    DWORD64 ?
Rip_    DWORD64 ?
Xmm0_   M128 <>
Xmm1_   M128 <>
Xmm2_   M128 <>
Xmm3_   M128 <>
Xmm4_   M128 <>
Xmm5_   M128 <>
Xmm6_   M128 <>
Xmm7_   M128 <>
Xmm8_   M128 <>
Xmm9_   M128 <>
Xmm10_  M128 <>
Xmm11_  M128 <>
Xmm12_  M128 <>
Xmm13_  M128 <>
Xmm14_  M128 <>
Xmm15_  M128 <>
FltSave LEGACY_SAVE_AREA    <>
Fill    DWORD   ?
DebugControl    DWORD64 ?
LastBranchToRip DWORD64 ?
LastBranchFromRip   DWORD64 ?
LastExceptionToRip  DWORD64 ?
LastExceptionFromRip    DWORD64 ?
Fill1   DWORD64 ?
CONTEXT ends

    .CODE

exchdl proc pRecord:ptr, ulframe:qword, pContext:ptr, x4:ptr

    sub rsp,28h
    add qword ptr [r8].CONTEXT.Rip_, 1  ;1=size of "in EAX, DX" opcode
    mov edx, [rcx].EXCEPTION_RECORD64.ExceptionCode
    mov rcx, CStr("exception code: %X",10)
    call printf
    mov eax, 0  ;0=continue execution?
    add rsp,28h
    ret

exchdl endp

VMwareInstalled proc FRAME:exchdl

    push rbx
    .pushreg rbx
    .endprolog

    mov eax, 0564D5868h
    mov ebx, 08685D465h
    mov ecx, 10
    mov dx, 05658h
    in eax, dx
    cmp ebx, 564D5868h
    setz al
    movzx eax,al

    add rsp,0
    pop rbx
    ret

VMwareInstalled endp

main proc FRAME

    sub rsp,28h
    .allocstack 28h
    .endprolog

    mov rcx, CStr("Testing VMware presence",10)
    call printf

    call VMwareInstalled

    lea rcx, CStr("running in VMware",10)
    and eax, eax
    jnz @F
    lea rcx, CStr("NOT running in VMware",10)
@@:
    call printf

    add rsp,28h
    ret

main endp

mainCRTStartup proc
    sub rsp,28h
    call main
    mov ecx,eax
    call exit
mainCRTStartup endp

    END
