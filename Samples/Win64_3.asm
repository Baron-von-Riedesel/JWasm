
;--- A simple Windows GUI program that creates an empty window;
;--- similar to Win64_2, but with SEH support and without using hll
;--- directives. Thus this source can be assembled by both JWasm 
;--- and Masm64 - Masm64 v8 might have problems, though.
;---
;--- to assemble enter:
;---   JWasm -win64 Win64_3.asm
;--- or:
;---   ml64 -c Win64_3.asm
;---
;--- to link the binary use:
;---   MS Link: link Win64_3.obj
;---   JWlink:  jwlink format win pe ru win file Win64_3.obj op start=WinMainCRTStartup

    option casemap:none

    includelib kernel32.lib
    includelib user32.lib

HINSTANCE typedef ptr
HWND      typedef ptr
HMENU     typedef ptr
HICON     typedef ptr
HBRUSH    typedef ptr
HCURSOR   typedef ptr
WPARAM    typedef QWORD
LPARAM    typedef QWORD
LPSTR     typedef ptr BYTE
LPVOID    typedef ptr
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

;WinMain proto :HINSTANCE, :HINSTANCE, :LPSTR, :UINT

    .data

ClassName db "SimpleWinClass",0
AppName  db "Our First Window",0

    .data?

hInstance HINSTANCE ?
CommandLine LPSTR ?

    .code

WinMainCRTStartup proc FRAME

    sub    rsp,5*8
    .allocstack 5*8
    .endprolog

    mov    ecx,NULL
    call   GetModuleHandleA
    mov    hInstance, rax
    call   GetCommandLineA
    mov    CommandLine, rax
    mov    rcx, hInstance
    mov    rdx, NULL
    mov    r8, CommandLine
    mov    r9d, SW_SHOWDEFAULT
    call   WinMain
    mov    ecx, eax
    call   ExitProcess
    align 4
WinMainCRTStartup endp

WinMain proc FRAME hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:UINT

local wc:WNDCLASSEXA
local msg:MSG
local hwnd:HWND

    push  rbp
    .pushreg rbp
    mov   rbp,rsp
    .setframe rbp, 0
    sub   rsp, sizeof WNDCLASSEXA + sizeof MSG + sizeof HWND + 13*8  ;make sure rsp is 16-byte aligned
    .allocstack sizeof WNDCLASSEXA + sizeof MSG + sizeof HWND + 13*8
    .endprolog

;--- store params in shadow space
    mov   hInst, rcx
    mov   hPrevInst, rdx
    mov   CmdLine, r8
    mov   CmdShow, r9d

    mov   wc.cbSize, SIZEOF WNDCLASSEXA
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
;   mov   rax, OFFSET WndProc  ;using LEA is preferable
    lea   rax, [WndProc]
    mov   wc.lpfnWndProc, rax
    mov   wc.cbClsExtra, 0
    mov   wc.cbWndExtra, 0
    mov   wc.hInstance, rcx
    mov   wc.hbrBackground, COLOR_WINDOW+1
    mov   wc.lpszMenuName, NULL
;    mov   rax, OFFSET ClassName  ;using LEA is preferable
    lea   rax, [ClassName]
    mov   wc.lpszClassName, rax
    mov   ecx, NULL
    mov   edx, IDI_APPLICATION
    call  LoadIconA
    mov   wc.hIcon, rax
    mov   wc.hIconSm, rax
    mov   ecx, NULL
    mov   edx, IDC_ARROW
    call  LoadCursorA
    mov   wc.hCursor,rax
    lea   rcx, wc
    call  RegisterClassExA
    mov   ecx, NULL
    lea   rdx, [ClassName]
    lea   r8, [AppName]
    mov   r9d, WS_OVERLAPPEDWINDOW
    mov   dword ptr [rsp+4*8], CW_USEDEFAULT
    mov   dword ptr [rsp+5*8], CW_USEDEFAULT
    mov   dword ptr [rsp+6*8], CW_USEDEFAULT
    mov   dword ptr [rsp+7*8], CW_USEDEFAULT
    mov   qword ptr [rsp+8*8], NULL
    mov   qword ptr [rsp+9*8], NULL
    mov   rax, hInst
    mov   [rsp+10*8], rax
    mov   qword ptr [rsp+11*8], NULL
    call  CreateWindowExA
    mov   hwnd,rax
    mov   rcx, hwnd
    mov   edx, SW_SHOWNORMAL
    call  ShowWindow
    mov   rcx, hwnd
    call  UpdateWindow
;--- message loop
@@:
        lea rcx, msg
        mov rdx, NULL
        mov r8, 0
        mov r9, 0
        call GetMessageA
        and rax, rax
        jz @F
        lea rcx, msg
        call TranslateMessage
        lea rcx, msg
        call DispatchMessageA
        jmp @B
@@:
    mov   rax, msg.wParam
    add   rsp, sizeof WNDCLASSEXA + sizeof MSG + sizeof HWND + 13*8
    pop   rbp
;--- RET 0 is used, because ML64 seems to have problems with a simple RET
    ret 0
    align 4
WinMain endp

WndProc proc FRAME hwnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

    sub   rsp, 5*8
    .allocstack 5*8
    .endprolog

    cmp edx, WM_DESTROY
    jnz @F
    mov ecx, NULL
    call PostQuitMessage
    xor rax,rax
    jmp exit
@@:
    call DefWindowProcA
exit:
    add rsp, 5*8
    ret 0
    align 4
WndProc endp

end
