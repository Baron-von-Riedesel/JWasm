
;--- DOS program which switches to long-mode and back.
;--- Note: requires at least JWasm v2.
;--- Also: needs a 64bit cpu in real-mode to run.
;--- Parts of the source are based on samples supplied by
;--- sinsi and Tomasz Grysztar in the FASM forum.
;--- To create the binary enter:
;---  JWasm -mz DOS64.asm

    .model small
    .stack 4096
    .dosseg         ;arrange segments in "DOS" order

DGROUP group _TEXT  ;make a tiny model

    .x64p

?MPIC equ 78h       ;reprogram master PIC to base 78h

;--- 16bit start/exit code

    .code

    assume ds:DGROUP
    assume es:DGROUP

GDT dq 0                    ; null descriptor
    dw 0FFFFh,0,9A00h,0AFh  ; 64-bit code descriptor
    dw 0FFFFh,0,9A00h,000h  ; compatibility mode code descriptor
    dw 0FFFFh,0,9200h,000h  ; compatibility mode data descriptor

SEL_CODE64 equ 1*8
SEL_CODE16 equ 2*8
SEL_DATA16 equ 3*8

GDTR label fword        ; Global Descriptors Table Register
    dw 4*8-1            ; limit of GDT (size minus one)
    dd offset GDT       ; linear address of GDT
IDTR label fword        ; Interrupt Descriptor Table Register
    dw 256*16-1         ; limit of IDT (size minus one)
    dd 0                ; linear address of IDT
nullidt label fword
    dw 3FFh
    dd 0
  
wPICMask dw 0   ; variable to save/restore PIC masks
wStack   dw 0   ; real-mode SP
;bKey     db 0   ; 1-byte keyboard "buffer"

start16:
    push cs
    pop ds
    mov ax,cs
    movzx eax,ax
    shl eax,4
    add dword ptr [GDTR+2], eax ; convert offset to linear address
    mov word ptr [GDT + SEL_CODE16 + 2], ax	;set base in code and data descriptor
    mov word ptr [GDT + SEL_DATA16 + 2], ax
    shr eax,16
    mov byte ptr [GDT + SEL_CODE16 + 4], al
    mov byte ptr [GDT + SEL_DATA16 + 4], al

    mov ax,ss
    mov dx,es
    sub ax,dx
    mov bx,sp
    shr bx,4
    add bx,ax
    mov ah,4Ah
    int 21h         ; free unused memory
    push cs
    pop es
    mov ax,ss
    mov dx,cs
    sub ax,dx
    shl ax,4
    add ax,sp
    push ds
    pop ss
    mov sp,ax       ; make a TINY model, CS=SS=DS=ES
    mov wStack,ax

    smsw ax
    test al,1
    jz @F
    mov dx,offset err1
    mov ah,9
    int 21h
    mov ah,4Ch
    int 21h
err1 db "Mode is V86. Need REAL mode to switch to LONG mode!",13,10,'$'
@@:
    xor edx,edx
    mov eax,80000001h   ; test if long-mode is supported
    cpuid
    test edx,20000000h
    jnz @F
    mov dx,offset err2
    mov ah,9
    int 21h
    mov ah,4Ch
    int 21h
err2 db "No 64bit cpu detected.",13,10,'$'
@@:
    mov bx,600h    ; allocate 24 kB (needed are 4 pages for paging, 1 for IDT)
    mov ah,48h
    int 21h
    jnc @F
    mov dx,offset err3
    mov ah,9
    int 21h
    mov ah,4Ch
    int 21h
err3 db "Out of memory",13,10,'$'
@@:
    add ax,100h-1   ; align to page boundary
    mov al,0
    mov es,ax

;--- setup page directories and tables

    sub di,di
    mov cx,4096
    sub eax,eax
    rep stosd       ; clear 4 pages

    sub di,di
    mov ax,es
    movzx eax,ax
    shl eax,4
    mov cr3,eax             ; load page-map level-4 base

    lea edx, [eax+4000h]
    mov dword ptr [IDTR+2], edx

    or eax,111b
    add eax, 1000h
    mov es:[di+0000h],eax   ; first PDP table
    add eax, 1000h
    mov es:[di+1000h],eax   ; first page directory
    add eax, 1000h
    mov es:[di+2000h],eax   ; first page table
    mov di,3000h            ; address of first page table
    mov eax,0 + 111b
    mov cx,256              ; number of pages to map (1 MB)
@@:
    stosd
    add di,4
    add eax,1000h
    loop @B

;--- setup ebx/rbx with linear address of _TEXT64

    mov ebx,_TEXT64
    shl ebx,4
    add [llg], ebx

;--- create IDT

    mov di,4000h
    mov cx,32
    mov edx, offset exception
    add edx, ebx
make_exc_gates:
    mov eax,edx
    stosw
    mov ax,8
    stosw
    mov ax,8E00h
    stosd
    xor eax, eax
    stosd
    stosd
    add edx,4
    loop make_exc_gates
    mov cx,256-32
make_int_gates:
    mov eax,offset interrupt
    add eax, ebx
    stosw
    mov ax,8
    stosw
    mov ax,8E00h
    stosd
    xor eax, eax
    stosd
    stosd
    loop make_int_gates

    mov di,4000h
    mov eax, ebx
    add eax, offset clock
    mov es:[di+?MPIC*16+0],ax ; set IRQ 0 handler
    shr eax,16
    mov es:[di+?MPIC*16+6],ax

    mov eax, ebx
    add eax, offset keyboard
    mov es:[di+(?MPIC+1)*16+0],ax ; set IRQ 1 handler
    shr eax,16
    mov es:[di+(?MPIC+1)*16+6],ax

;--- reprogram PIC: change IRQ 0-7 to INT 78h-7Fh

    cli
    in al,0A1h
    mov ah,al
    in al,21h
    mov [wPICMask],ax

    mov al,10001b       ; ICW1: begin PIC 1 initialization
    out 20h,al
    mov al,?MPIC        ; ICW2: IRQ 0-7: interrupts 78h-7Fh
    out 21h,al
    mov al,100b         ; ICW3: slave connected to IRQ2
    out 21h,al
    mov al,1            ; ICW4: Intel environment, manual EOI
    out 21h,al

    mov al,11111100b    ; enable clock and keyboard IRQ only
    out 21h,al
    mov al,11111111b
    out 0A1h,al

    mov eax,cr4
    or eax,1 shl 5
    mov cr4,eax         ; enable physical-address extensions (PAE)

    mov ecx,0C0000080h  ; EFER MSR
    rdmsr
    or eax,1 shl 8      ; enable long mode
    wrmsr

    lgdt [GDTR]
    lidt [IDTR]

    mov eax,cr0
    or eax,80000001h
    mov cr0,eax         ; enable paging & protected-mode

    db 66h, 0EAh        ; jmp 0008:oooooooo
llg dd offset long_start
    dw SEL_CODE64

;--- switch back to real-mode and exit

backtoreal:
    cli
    mov eax,cr0
    and eax,7FFFFFFEh   ; disable paging & protected-mode
    mov cr0,eax

    jmp far16 ptr @F    ; clear instruction cache, CS=real-mode seg
@@:
    mov ax,cs
    mov ds,ax           ; DS=DGROUP
    mov ss,ax           ; SS=DGROUP
    mov sp,wStack

    lidt [nullidt]      ; IDTR=real-mode compatible values

    mov ecx,0C0000080h  ; EFER MSR
    rdmsr
    and ah,not 1h       ; disable long mode (EFER.LME=0)
    wrmsr

    mov eax,cr4
    and al,not 20h      ; disable physical-address extensions (PAE)
    mov cr4,eax

;--- reprogram PIC: change IRQ 0-7 to INT 08h-0Fh

    mov al,10001b       ; ICW1: begin PIC 1 initialization
    out 20h,al
    mov al,08h          ; ICW2: IRQ 0-7: back to ints 8h-Fh
    out 21h,al
    mov al,100b         ; ICW3: slave connected to IRQ2
    out 21h,al
    mov al,1            ; ICW4: Intel environment, manual EOI
    out 21h,al

    mov ax,[wPICMask]   ; restore PIC masks
    out 21h,al
    mov al,ah
    out 0A1h,al

    sti
    mov ax,4c00h
    int 21h

_TEXT ends

;--- here's the 64bit code segment.
;--- ebx=flat address of module start.

_TEXT64 segment para use64 public 'CODE'

    assume ds:FLAT, es:FLAT

bKey db 0           ; 1-byte keyboard "buffer"

long_start:

    mov ax,SEL_DATA16
    mov ss,eax
    add esp,ebx
    sti            ; now interrupts can be used
    call WriteStrX
    db "Hello 64bit",10,0
nextcmd:
    call WriteStrX
    db "press 'r' or ESC to exit: ",0
    call set_cursor
    mov bKey,0     ; clear keyboard buffer
@@:
    mov al,bKey
    cmp al,0
    jnz @F
    hlt            ; wait 
    jmp @B
@@:
    cmp al,1       ; ESC?
    jz esc_pressed
    cmp al,13h     ; 'r'?
    jz r_pressed
    push rax
    call WriteStrX
    db "unknown key ",0
    pop rax
    call WriteB
    call WriteStrX
    db 10,0
    jmp nextcmd

;--- 'r' key: display some register contents

r_pressed:
    call WriteStrX
    db 10,"cr0=",0
    mov rax,cr0
    call WriteQW
    call WriteStrX
    db 10,"cr2=",0
    mov rax,cr2
    call WriteQW
    call WriteStrX
    db 10,"cr3=",0
    mov rax,cr3
    call WriteQW
    call WriteStrX
    db 10,"cr4=",0
    mov rax,cr4
    call WriteQW
    call WriteStrX
    db 10,"cr8=",0
    mov rax,cr8
    call WriteQW
    call WriteStrX
    db 10,0
    jmp nextcmd

;--- ESC: back to real-mode

bv  label ptr far16
    dw offset backtoreal
    dw SEL_CODE16
esc_pressed:
    jmp [bv]

;--- screen output helpers

;--- set text mode cursor
set_cursor proc
    push rsi
    push rcx
    push rdx
    MOVZX esi, BYTE PTR flat:[462h]       ;page
    MOVZX ecx, BYTE PTR [esi*2+450h+1]    ;get cursor pos ROW
    MOVZX eax, WORD PTR flat:[44Ah]       ;cols
    MUL ecx
    MOVZX edx, BYTE PTR [esi*2+450h]      ;get cursor pos COL
    ADD eax, edx
    movzx ecx,word ptr flat:[44eh]
    shr ecx,1
    add ecx, eax
    mov dx,flat:[463h]
    mov ah,ch
    mov al,0Eh
    out dx,ax
    inc al
    mov ah,cl
    out dx,ax
    pop rdx
    pop rcx
    pop rsi
    ret
set_cursor endp

;--- scroll screen up one line
;--- rsi = linear address start of last line
scroll_screen:
    CLD
    mov edi,esi
    movzx eax,word ptr flat:[44Ah]
    push rax
    lea rsi, [rsi+2*rax]
    MOV CL, flat:[484h]
    mul cl
    mov ecx,eax
    rep movsw
    pop rcx
    mov ax,0720h
    rep stosw
    ret

WriteChr:
    push rdi
    push rsi
    push rbx
    push rcx
    push rdx
    push rax
    MOV edi,0B8000h
    CMP BYTE ptr flat:[463h],0B4h
    JNZ @F
    XOR DI,DI
@@:
    movzx ebx, WORD PTR flat:[44Eh]
    ADD edi, ebx
    MOVZX ebx, BYTE PTR flat:[462h]
    mov esi, edi
    MOVZX ecx, BYTE PTR [rbx*2+450h+1] ;ROW
    MOVZX eax, WORD PTR flat:[44Ah]
    MUL ecx
    MOVZX edx, BYTE PTR [rbx*2+450h]  ;COL
    ADD eax, edx
    MOV DH,CL
    LEA edi, [rdi+rax*2]
    MOV AL, [rsp]
    CMP AL, 10
    JZ newline
    MOV [rdi], AL
    MOV byte ptr [rdi+1], 07
    INC DL
    CMP DL, BYTE PTR flat:[44Ah]
    JB @F
newline:
    MOV DL, 00
    INC DH
    CMP DH, BYTE PTR flat:[484h]
    JBE @F
    DEC DH
    CALL scroll_screen
@@:
    MOV [rbx*2+450h],DX
    pop rax
    pop rdx
    pop rcx
    pop rbx
    pop rsi
    pop rdi
    RET

WriteStr:   ;write string in rdx
    push rsi
    mov rsi, rdx
    cld
@@:
    lodsb
    and al,al
    jz @F
    call WriteChr
    jmp @B
@@:
    pop rsi
    ret

WriteStrX:  ;write string at rip
    push rsi
    mov rsi, [rsp+8]
    cld
@@:
    lodsb
    and al,al
    jz @F
    call WriteChr
    jmp @B
@@:
    mov [rsp+8],rsi
    pop rsi
    ret

WriteQW:        ;write QWord in rax
    push rax
    shr rax,32
    call WriteDW
    pop rax
WriteDW:
    push rax
    shr rax,16
    call WriteW
    pop rax
WriteW:
    push rax
    shr rax,8
    call WriteB
    pop rax
WriteB:     ;write Byte in al
    push rax
    shr rax,4
    call WriteNb
    pop rax
WriteNb:
    and al,0Fh
    add al,'0'
    cmp al,'9'
    jbe @F
    add al,7
@@:
    jmp WriteChr

;--- exception handler

exception:
excno = 0
    repeat 32
    push excno
    jmp @F
    excno = excno+1
    endm
@@:
    call WriteStrX
    db 10,"Exception ",0
    pop rax
    call WriteB
    call WriteStrX
    db " errcode=",0
    mov rax,[rsp+0]
    call WriteQW
    call WriteStrX
    db " rip=",0
    mov rax,[rsp+8]
    call WriteQW
    call WriteStrX
    db 10,0
    jmp [bv] ;exit

;--- clock and keyboard interrupts

clock:
    inc dword ptr flat:[46Ch]
interrupt:              ; handler for all other interrupts
    push rax
    mov al,20h
    out 20h,al
    pop rax
    iretq

keyboard:
    push rax
    in al,60h
    test al,80h
    jnz @F
    mov [bKey], al      ; store key in 1-byte keyb buffer
@@:
    in al,61h           ; give finishing information
    out 61h,al          ; to keyboard...
    mov al,20h
    out 20h,al          ; ...and interrupt controller
    pop rax
    iretq

_TEXT64 ends

    end start16
