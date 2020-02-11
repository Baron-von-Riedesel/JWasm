
;--- a simple Windows GUI program which creates an
;--- "empty" window, then enters a "message loop".
;--- Does not contain directives for Win64 SEH.
;---
;--- to create the binary enter:
;---   JWasm -win64 Win64_2.asm
;--- to link, use either:
;---   MS Link: link Win64_2.obj kernel32.lib user32.lib
;---   JWlink:  jwlink format win pe ru win file Win64_2.obj lib kernel32.lib, user32.lib

    option casemap:none

HINSTANCE typedef QWORD
HWND      typedef QWORD
HMENU     typedef QWORD
HICON     typedef QWORD
HBRUSH    typedef QWORD
HCURSOR   typedef QWORD
WPARAM    typedef QWORD
LPARAM    typedef QWORD
LPSTR     typedef QWORD
LPVOID    typedef QWORD
UINT      typedef DWORD

NULL           equ 0
WS_OVERLAPPEDWINDOW equ 0CF0000h
CW_USEDEFAULT  equ 80000000h
SW_SHOWDEFAULT equ 10
SW_SHOWNORMAL  equ 1
IDC_ARROW      equ 32512
IDI_APPLICATION equ 32512
WM_DESTROY     equ 2
CS_VREDRAW     equ 1
CS_HREDRAW     equ 2
COLOR_WINDOW   equ 5

proto_WNDPROC typedef proto :HWND,:UINT,:WPARAM,:LPARAM
WNDPROC typedef ptr proto_WNDPROC

WNDCLASSEXA struct 8
cbSize          DWORD   ?
style           DWORD   ?
lpfnWndProc     WNDPROC ?
cbClsExtra      DWORD   ?
cbWndExtra      DWORD   ?
hInstance       HINSTANCE ?
hIcon           HICON   ?
hCursor         HCURSOR ?
hbrBackground   HBRUSH  ?
lpszMenuName    LPSTR   ?
lpszClassName   LPSTR   ?
hIconSm         HICON   ?
WNDCLASSEXA ends

POINT   struct
x   SDWORD  ?
y   SDWORD  ?
POINT   ends

MSG struct 8
hwnd    HWND    ?
message DWORD   ?
wParam  WPARAM  ?
lParam  LPARAM  ?
time    DWORD   ?
pt      POINT   <>
MSG ends

GetModuleHandleA proto :LPSTR
GetCommandLineA  proto
ExitProcess      proto :UINT
LoadIconA        proto :HINSTANCE, :LPSTR
LoadCursorA      proto :HINSTANCE, :LPSTR
RegisterClassExA proto :ptr WNDCLASSEXA
CreateWindowExA  proto :DWORD, :LPSTR, :LPSTR, :DWORD, :SDWORD, :SDWORD, :SDWORD, :SDWORD, :HWND, :HMENU, :HINSTANCE, :LPVOID
ShowWindow       proto :HWND, :SDWORD
UpdateWindow     proto :HWND
GetMessageA      proto :ptr MSG, :HWND, :SDWORD, :SDWORD
TranslateMessage proto :ptr MSG
DispatchMessageA proto :ptr MSG
PostQuitMessage  proto :SDWORD
DefWindowProcA   proto :HWND, :UINT, :WPARAM, :LPARAM

WinMain proto :HINSTANCE, :HINSTANCE, :LPSTR, :UINT

    .data

ClassName db "SimpleWinClass",0
AppName  db "Our First Window",0

    .data?

hInstance HINSTANCE ?
CommandLine LPSTR ?

    .code

start:
    and    rsp, -16
    invoke GetModuleHandleA, NULL
    mov    hInstance, rax
    invoke GetCommandLineA
    mov    CommandLine, rax
    invoke WinMain, hInstance, NULL, CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess, eax

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:UINT

    LOCAL wc:WNDCLASSEXA
    LOCAL msg:MSG
    LOCAL hwnd:HWND

    and   rsp, -16        ;to make the stack 16byte aligned

    mov   hInst, rcx      ;hInst is the name of the shadow space variable!

    mov   wc.cbSize, SIZEOF WNDCLASSEXA
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
;   mov   rax, OFFSET WndProc  ;using LEA is preferable
    lea   rax, [WndProc]
    mov   wc.lpfnWndProc, rax
    mov   wc.cbClsExtra, NULL
    mov   wc.cbWndExtra, NULL
    mov   wc.hInstance, rcx
    mov   wc.hbrBackground, COLOR_WINDOW+1
    mov   wc.lpszMenuName, NULL
;    mov   rax, OFFSET ClassName  ;using LEA is preferable
    lea   rax, [ClassName]
    mov   wc.lpszClassName, rax
    invoke LoadIconA, NULL, IDI_APPLICATION
    mov   wc.hIcon, rax
    mov   wc.hIconSm, rax
    invoke LoadCursorA, NULL, IDC_ARROW
    mov   wc.hCursor,rax
    invoke RegisterClassExA, addr wc
    invoke CreateWindowExA, NULL, ADDR ClassName, ADDR AppName,\
           WS_OVERLAPPEDWINDOW, CW_USEDEFAULT,\
           CW_USEDEFAULT, CW_USEDEFAULT,CW_USEDEFAULT, NULL, NULL,\
           hInst, NULL
    mov   hwnd,rax
    invoke ShowWindow, hwnd, SW_SHOWNORMAL
    invoke UpdateWindow, hwnd
    .while (1)
        invoke GetMessageA, ADDR msg, NULL, 0, 0
        .break .if (!rax)
        invoke TranslateMessage, ADDR msg
        invoke DispatchMessageA, ADDR msg
    .endw
    mov   rax, msg.wParam
    ret
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

    and rsp,-16
    .if ( edx == WM_DESTROY )
        invoke PostQuitMessage, NULL
    .else
        invoke DefWindowProcA, rcx, edx, r8, r9
        ret
    .endif
    xor rax,rax
    ret
WndProc endp

end start
