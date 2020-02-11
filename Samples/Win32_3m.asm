
;--- a simple Windows GUI program, using Masm32.
;---
;--- to create the binary by using OW Wlink enter:
;---   JWasm Win32_3m.asm
;---   Wlink format win pe ru windows file Win32_3m.obj
;--- 
;--- alternatively, using MS link:
;---   JWasm -coff Win32_3m.asm
;---   Link Win32_3m.obj /subsystem:windows

    .486
    .model flat,stdcall
    option casemap:none

;--- use Masm32 include files

    pushcontext listing ;suppress listing of includes
    .nolist
    .nocref
    include \masm32\include\windows.inc
    include \masm32\include\kernel32.inc
    include \masm32\include\user32.inc
    includelib \masm32\lib\kernel32.lib
    includelib \masm32\lib\user32.lib
    popcontext listing

WinMain proto :HINSTANCE,:HINSTANCE,:LPSTR,:DWORD

    .data

ClassName db "SimpleWinClass",0
AppName  db "Our First Window",0
hellomsg db "Hello world"

    .data?

hInstance HINSTANCE ?
CommandLine LPSTR ?

    .code

start:
    invoke GetModuleHandle, NULL
    mov    hInstance, eax
    invoke GetCommandLine
    mov    CommandLine, eax
    invoke WinMain, hInstance, NULL, CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess, eax

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL hwnd:HWND

    mov   wc.cbSize, SIZEOF WNDCLASSEX
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
    mov   wc.lpfnWndProc, OFFSET WndProc
    mov   wc.cbClsExtra, 0
    mov   wc.cbWndExtra, 0
    push  hInstance
    pop   wc.hInstance
    mov   wc.hbrBackground, COLOR_WINDOW+1
    mov   wc.lpszMenuName, NULL
    mov   wc.lpszClassName, OFFSET ClassName
    invoke LoadIcon, NULL, IDI_APPLICATION
    mov   wc.hIcon, eax
    mov   wc.hIconSm, eax
    invoke LoadCursor, NULL, IDC_ARROW
    mov   wc.hCursor, eax
    invoke RegisterClassEx, addr wc
    invoke CreateWindowEx, NULL, ADDR ClassName, ADDR AppName,
           WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
           CW_USEDEFAULT, NULL, NULL, hInst, NULL
    mov   hwnd, eax
    invoke ShowWindow, hwnd, SW_SHOWNORMAL
    invoke UpdateWindow, hwnd
    .while (1)
        invoke GetMessage, ADDR msg, NULL, 0, 0
        .break .if (!eax)
        invoke TranslateMessage, ADDR msg
        invoke DispatchMessage, ADDR msg
    .endw
    mov   eax, msg.wParam
    ret
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

local ps:PAINTSTRUCT
local rect:RECT

    mov eax, uMsg
    .if (eax == WM_DESTROY)
        invoke PostQuitMessage, NULL
        xor eax,eax
    .elseif (eax == WM_PAINT)
        invoke BeginPaint, hWnd, addr ps
        invoke GetClientRect, hWnd, addr rect
        invoke DrawText, ps.hdc, addr hellomsg, sizeof hellomsg, addr rect, DT_CENTER or DT_VCENTER or DT_SINGLELINE
        invoke EndPaint, hWnd, addr ps
        xor eax,eax
    .else
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    .endif
    ret
WndProc endp

end start
