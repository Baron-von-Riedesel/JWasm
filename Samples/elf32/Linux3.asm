
; rudimentary "hello world" for Xwindows
; translated from a nasm sample supplied by Frank Kotler.
; LD is used as linker, since WLINK doesn't know how to use shared objects.
;
; 1. assemble:       jwasm -elf -Fo=Linux3.o Linux3.asm
; 2. link with LD:   ld -s -o Linux3 Linux3.o -I/lib/ld-linux.so.2 -L/usr/X11R6/lib -lX11

    .386
    .model flat

    public _start

;--- The X functions don't have a underscore prefix.
;--- Therefore SYSCALL is used in the prototypes.
;--- If C is to be used instead, the -zcw cmdline parameter is needed.

XOpenDisplay        proto syscall :DWORD
XDefaultRootWindow  proto syscall :DWORD
XCreateSimpleWindow proto syscall :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
XSelectInput        proto syscall :DWORD, :DWORD, :DWORD
XStoreName          proto syscall :DWORD, :DWORD, :DWORD
XMapRaised          proto syscall :DWORD, :DWORD
XCreateGC           proto syscall :DWORD, :DWORD, :DWORD, :DWORD
XSetForeground      proto syscall :DWORD, :DWORD, :DWORD
XSetBackground      proto syscall :DWORD, :DWORD, :DWORD
XNextEvent          proto syscall :DWORD, :DWORD
XFreeGC             proto syscall :DWORD, :DWORD
XDestroyWindow      proto syscall :DWORD, :DWORD
XCloseDisplay       proto syscall :DWORD
XDrawImageString    proto syscall :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD

KeyPressMask equ 1     ; mask for XSelectInput
KeyPress     equ 2     ; the "type" of event (offset 0 in "glob of bytes")

ExposeMask   equ 1 shl 15
ExposeEvent  equ 12

event_size equ 20h    ; ??? max size of several different structs

;------------------------------------------
    .data
    StringOpenFailed db "Can't Open X display!", 10
    caption db 'A Window', 0
    string db ' Greetings from X, Earthling! '

;-----------------------------------------
    .data?

Display dd ?
Window  dd ?
GC      dd ?

event   dd event_size dup (?)

;-------------------------------------

    .code

_start:    ; let the ritual begin.
; open a connection to the server.
; param 0 uses the "DISPLAY" environment variable
; or defaults to local machine.
    invoke XOpenDisplay, 0
    .if (eax == 0)
        mov eax, 4                      ; __NR_write
        mov ebx, 2                      ; stderr
        mov ecx, offset StringOpenFailed; buffer
        mov edx, sizeof StringOpenFailed; count
        int 80h
        jmp Terminate
    .endif
    mov [Display], eax

    invoke XDefaultRootWindow, [Display]
    ; error?
;--- params: display handle, defaultrootwindow, left, top, width, height
;---         border width, border colour, background colour
    invoke XCreateSimpleWindow, [Display], eax, 50, 50, 400, 300, 0, 0, 0
    .if (eax == 0)
        invoke XCloseDisplay, [Display]
        jmp Terminate
    .endif
    mov [Window], eax
; this is one Windows doesn't do. if we don't specify
; what events (messages) we want to receive, we don't get any.
; "or" this with other events to recv!
; don't forget to handle 'em!
    invoke XSelectInput, [Display], [Window], KeyPressMask or ExposeMask
    ; error?
    ; give the baby a name
    invoke XStoreName, [Display], [Window], offset caption
    ; error?
    invoke XMapRaised, [Display], [Window]  ; make our window visible.
    ; error?
    invoke XCreateGC, [Display], [Window], 0, 0
    ; error?
    mov [GC], eax
; Mmmm, looks like 16-bit color, 5-6-5, on my machine.
; Bet we can't count on it!
; 1111100000000000b = red
    invoke XSetForeground, [Display], [GC], 1111100000000000b
    ; error?
; 0000011111100000b = green
    invoke XSetBackground, [Display], [GC], 0000011111100000b
    ; error?

    .while (1)
        invoke XNextEvent, [Display], offset event
        ; error?
        .if (dword ptr [event+0] == ExposeEvent)
            invoke XDrawImageString, [Display], [Window], [GC], 155, 140, offset string, sizeof string
        .elseif (dword ptr [event+0] == KeyPress)
            .break  ; exit gracefully if key pressed
        .endif
    .endw

    invoke XFreeGC, [Display], [GC]
    invoke XDestroyWindow, [Display], [Window]
    invoke XCloseDisplay, [Display]

Terminate:
    mov eax, 1     ; function (sys_exit)
    xor ebx, ebx   ; exit code
    int 80h        ; make Linux system call

    end _start
