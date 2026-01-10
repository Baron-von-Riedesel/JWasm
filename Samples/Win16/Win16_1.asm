
;--- a simple 16-bit Windows "hello world". Public Domain.
;--- assemble: JWasm Win16_1.asm
;--- link:     wlink format windows file Win16_1.obj op st=5120,heapsize=1024
;---
;--- alternatively the MS OMF linker can be used as well:
;---           link16 /A:16 Win16_1.obj,,,,Win16_1.def;
;---
;--- libw.lib is the name of the import library for Win16 API calls.
;--- if libw.lib isn't available, create one with Open Watcom WLIB:
;---   wlib -ino -p=16 libw.lib + krnl386.exe + user.exe + gdi.exe
;--- (files krnl386.exe, user.exe and gdi.exe can be found in the Windows
;--- system directory).

    .286
    .model small
    .386
    option casemap:none

    includelib <libw.lib>

;--- menu commands
IDM_EXIT  EQU 100

;--- Windows API definitions
WINAPI    equ <FAR PASCAL>

UINT      typedef WORD
HINSTANCE typedef WORD
HWND      typedef WORD
HMENU     typedef WORD
HDC       typedef WORD
WPARAM    typedef WORD
LPARAM    typedef DWORD
LPSTR     typedef FAR PTR BYTE

NULL            EQU 0

WS_OVERLAPPED   EQU 000000000h
WS_MAXIMIZEBOX  EQU 000010000h
WS_MINIMIZEBOX  EQU 000020000h
WS_THICKFRAME   EQU 000040000h
WS_SYSMENU      EQU 000080000h
WS_CAPTION      EQU 000C00000h
WS_OVERLAPPEDWINDOW EQU WS_OVERLAPPED + WS_CAPTION + WS_SYSMENU + WS_THICKFRAME + WS_MINIMIZEBOX + WS_MAXIMIZEBOX

CS_VREDRAW      EQU 0001h
CS_HREDRAW      EQU 0002h

WM_DESTROY      EQU 0002h
WM_PAINT        EQU 000Fh
WM_COMMAND      EQU 0111h

CW_USEDEFAULT   EQU 8000h
SW_SHOWNORMAL   EQU 1
COLOR_WINDOW    EQU 5
IDC_ARROW       EQU 32512

DT_CENTER       EQU 01h
DT_VCENTER      EQU 04h
DT_SINGLELINE   EQU 20h

MF_ENABLED      EQU 0
MF_STRING       EQU 0
MF_POPUP        EQU 10h

MSG       struct
hwnd      HWND ?
message   UINT ?
wParam    WPARAM ?
lParam    LPARAM ?
time      dd ?
pt        dd ?
MSG       ends

WNDCLASS struct
style        dw  ?
lpfnWndProc  dd  ?
cbClsExtra   dw  ?
cbWndExtra   dw  ?
hInstance    HINSTANCE ?
hIcon        dw  ?
hCursor      dw  ?
hbrBackground dw ?
lpszMenuName  LPSTR ?
lpszClassName LPSTR ?
WNDCLASS ends

RECT        struct
left        dw ?
top         dw ?
right       dw ?
bottom      dw ?
RECT        ends

PAINTSTRUCT struct
hdc         HDC ?
fErase      dw ?
rcPaint     RECT <>
fRestore    dw ?
fIncUpdate  dw ?
rgbReserved db 16 dup(?)
PAINTSTRUCT ends

AppendMenu        proto WINAPI :HMENU, :WORD, :WORD, :LPSTR
BeginPaint        proto WINAPI :HWND, :far ptr PAINTSTRUCT
CreateMenu        proto WINAPI
CreatePopupMenu   proto WINAPI
CreateWindow      proto WINAPI lpszClass:LPSTR, lpszName:LPSTR, style:DWORD,
                     x:WORD, y:WORD, cx_:WORD, cy:WORD,
                     parent:HWND, menu:HMENU, hInst:HINSTANCE, lParam:LPARAM
DefWindowProc     proto WINAPI :HWND, msg:UINT, wParam:WPARAM, lParam:LPARAM
DestroyMenu       proto WINAPI :HMENU
DestroyWindow     proto WINAPI :HWND
DispatchMessage   proto WINAPI :far ptr MSG
DrawText          proto WINAPI :HDC, :LPSTR, :WORD, :far ptr RECT, :WORD
EndPaint          proto WINAPI :HWND, :far ptr PAINTSTRUCT
GetClientRect     proto WINAPI :HWND, :far ptr RECT
GetMessage        proto WINAPI :far ptr MSG, hWnd:HWND, msgfrom:WORD, msgto:WORD
InitApp           proto WINAPI :HINSTANCE
InitTask          proto WINAPI
LoadCursor        proto WINAPI :HINSTANCE, :LPSTR
PostQuitMessage   proto WINAPI :WORD
RegisterClass     proto WINAPI :far ptr WNDCLASS
ShowWindow        proto WINAPI :HWND, :WORD
TranslateMessage  proto WINAPI :far ptr MSG
WaitEvent         proto WINAPI :WORD

    .data

    dw 0,0,5,0,0,0,0,0  ;DGROUP first 16 bytes used by Windows

    .const

szClass db "WndClassName",0
szWnd   db "Windows 16-bit sample in ASM",0
szHello db "Hello, world",0

szMFile db "&File",0
szMExit db "E&xit",0

    .code

;*** WM_COMMAND handler

OnCommand proc stdcall hWnd:HWND,wParam:WPARAM,lParam:LPARAM

    .if wParam == IDM_EXIT
        invoke DestroyWindow, hWnd
    .endif
    xor ax, ax
    cwd
    ret
OnCommand endp

;*** window procedure - must be FAR PASCAL

WndProc proc WINAPI <LOADDS> hWnd:HWND,message:UINT,wParam:WPARAM,lParam:LPARAM

local   ps:PAINTSTRUCT

    mov ax,message
    .if (ax == WM_COMMAND)
        invoke OnCommand,hWnd,wParam,lParam
    .elseif (ax == WM_PAINT)
        invoke BeginPaint, hWnd, addr ps
        invoke GetClientRect, hWnd, addr ps.rcPaint
        invoke DrawText, ps.hdc, addr szHello, -1, addr ps.rcPaint, DT_CENTER or DT_VCENTER or DT_SINGLELINE
        invoke EndPaint, hWnd, addr ps
        xor ax, ax
        cwd
    .elseif (ax == WM_DESTROY)
        invoke PostQuitMessage, 0
        xor ax,ax
        cwd
    .else
        invoke DefWindowProc, hWnd,message,wParam,lParam
    .endif
    ret
WndProc endp

;*** InitApplication: register window class

InitApplication proc stdcall hInstance:HINSTANCE

local   wc:WNDCLASS

    mov wc.style, CS_HREDRAW or CS_VREDRAW

    mov word ptr wc.lpfnWndProc+0, offset WndProc
    mov word ptr wc.lpfnWndProc+2, cs

    xor ax,ax
    mov wc.cbClsExtra,ax
    mov wc.cbWndExtra,ax

    mov ax,hInstance
    mov wc.hInstance,ax

    mov wc.hIcon, NULL

    invoke LoadCursor, 0, IDC_ARROW
    mov wc.hCursor,ax

    mov ax,COLOR_WINDOW + 1
    mov wc.hbrBackground,ax

    xor eax,eax
    mov wc.lpszMenuName,eax

    mov word ptr wc.lpszClassName+0, offset szClass
    mov word ptr wc.lpszClassName+2, ds

    invoke RegisterClass, addr wc
exit:
    ret
InitApplication endp

;*** InitInstance: create application window and show it

InitInstance proc stdcall hInstance:HINSTANCE

local hMenu:HMENU

;--- "usually" a menu is loaded as a resource via LoadMenu().
;--- here a menu is created on the fly.
;--- it will be "destroyed" automatically when the window is "destroyed".
    invoke CreateMenu
    mov hMenu, ax
    invoke CreatePopupMenu
    push ax
    invoke AppendMenu, ax, MF_ENABLED or MF_STRING, IDM_EXIT, addr szMExit
    pop ax
    invoke AppendMenu, hMenu, MF_ENABLED or MF_POPUP, ax, addr szMFile

;--- create the main window
    invoke CreateWindow, addr szClass, addr szWnd,
        WS_OVERLAPPEDWINDOW, 
        CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
        NULL, hMenu, hInstance, 0
    .if (ax)
        push ax
        invoke ShowWindow, ax, SW_SHOWNORMAL
        pop ax
    .endif
    ret

InitInstance  endp

;--- WinMain: create application window, enter message loop

WinMain proc pascal hInstance:HINSTANCE,hPrevInstance:HINSTANCE,lpszCmdline:LPSTR,cmdshow:UINT

local   msg:MSG

    .if hPrevInstance == 0              ;1. Instance?
        invoke InitApplication, hInstance
        and  ax,ax
        jz   exit
    .endif

    invoke InitInstance, hInstance
    and  ax,ax
    jz   exit
    .while 1
        invoke GetMessage, addr msg, 0, 0, 0
        .break .if (ax == 0)
        invoke TranslateMessage, addr msg
        invoke DispatchMessage, addr msg
    .endw
exit:
    ret

WinMain endp

;--- program entry: SS=DS=DGROUP

start:
    invoke InitTask
    and ax,ax
    jz error
    push es          ;es:bx -> cmdline
    pusha
    invoke WaitEvent, 0
    invoke InitApp, di
    popa
    pop es
    invoke WinMain, di, si, es::bx, dx
    mov ah,4ch
    int 21h
error:
    mov ax,4c01h
    int 21h

    end start
