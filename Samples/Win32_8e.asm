
;--- this is a sample quite similar to Win32_8.asm.
;--- The difference is that the resources are not defined
;--- "manually" in the program source, but instead are supposed
;--- to be translated by a resource compiler and then converted
;--- to an assembly include file by tool res2inc.
;---
;--- to create the binary do:
;---   rc -r Win32_8e.rc
;---   res2inc -g Win32_8e.res Win32_8e.inc
;---   JWasm -pe Win32_8e.asm

    .486
    .model flat,stdcall
    option casemap:none

NULL       EQU 0
LPSTR      typedef ptr SBYTE
UINT_PTR   typedef ptr
LONG_PTR   typedef ptr
BOOL       typedef SDWORD
UINT       typedef DWORD

;--- resource IDs
IDR_MENU1   EQU 100
IDR_BITMAP1 EQU 101
IDM_EXIT    EQU 1000

;--- winbase definitions
HINSTANCE  typedef ptr

;--- winuser definitions
SW_SHOWNORMAL   EQU 1
SW_SHOWDEFAULT  EQU 10
CS_VREDRAW      EQU 0001h
CS_HREDRAW      EQU 0002h
CW_USEDEFAULT   EQU 80000000h
COLOR_WINDOW    EQU 5
IDI_APPLICATION EQU 32512
IDC_ARROW       EQU 32512
WS_OVERLAPPED   EQU 00000000h
WS_CAPTION      EQU 00C00000h
WS_SYSMENU      EQU 00080000h
WS_THICKFRAME   EQU 00040000h
WS_MINIMIZEBOX  EQU 00020000h
WS_MAXIMIZEBOX  EQU 00010000h
WS_OVERLAPPEDWINDOW EQU WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_THICKFRAME or WS_MINIMIZEBOX or WS_MAXIMIZEBOX
DT_CENTER       EQU 00000001h
DT_VCENTER      EQU 00000004h
DT_SINGLELINE   EQU 00000020h

WM_DESTROY      EQU 0002h
WM_PAINT        EQU 000Fh
WM_COMMAND      EQU 0111h

HWND       typedef ptr
HMENU      typedef ptr
HBRUSH     typedef ptr
HICON      typedef ptr
HCURSOR    typedef ptr
HBITMAP    typedef ptr
HDC        typedef ptr
WPARAM     typedef UINT_PTR
LPARAM     typedef LONG_PTR

proto_WNDPROC typedef proto stdcall :HWND,:DWORD,:WPARAM,:LPARAM
WNDPROC typedef ptr proto_WNDPROC

WNDCLASSEXA struct
cbSize        DWORD ?
style         DWORD ?
lpfnWndProc   WNDPROC ?
cbClsExtra    DWORD ?
cbWndExtra    DWORD ?
hInstance     HINSTANCE ?
hIcon         HICON ?
hCursor       HCURSOR ?
hbrBackground HBRUSH ?
lpszMenuName  LPSTR ?
lpszClassName LPSTR ?
hIconSm       HICON ?
WNDCLASSEXA ends

POINT struct
x   SDWORD ?
y   SDWORD ?
POINT ends

MSG struct 8
hwnd    HWND    ?
message DWORD   ?
wParam  WPARAM  ?
lParam  LPARAM  ?
time    DWORD   ?
pt      POINT   <>
MSG ends

RECT struct
left    SDWORD  ?
top     SDWORD  ?
right   SDWORD  ?
bottom  SDWORD  ?
RECT ends

PAINTSTRUCT struct
hdc         HDC  ?
fErase      BOOL ?
rcPaint     RECT <>
fRestore    BOOL ?
fIncUpdate  BOOL ?
rgbReserved BYTE 32 dup (?)
PAINTSTRUCT ends

;--- wingdi definitions

DIB_RGB_COLORS  EQU 0
SRCCOPY         EQU 00CC0020h

HGDIOBJ  typedef ptr

BITMAPINFOHEADER struct
biSize          DWORD   ?
biWidth         SDWORD  ?
biHeight        SDWORD  ?
biPlanes        WORD    ?
biBitCount      WORD    ?
biCompression   DWORD   ?
biSizeImage     DWORD   ?
biXPelsPerMeter SDWORD  ?
biYPelsPerMeter SDWORD  ?
biClrUsed       DWORD   ?
biClrImportant  DWORD   ?
BITMAPINFOHEADER ends

WinMain proto :HINSTANCE,:HINSTANCE,:LPSTR,:DWORD

    option DLLIMPORT:<kernel32.dll>
GetModuleHandleA proto :LPSTR
GetCommandLineA  proto
ExitProcess      proto :DWORD

    option DLLIMPORT:<user32.dll>
BeginPaint       proto :HWND, :ptr PAINTSTRUCT
CreateWindowExA  proto :DWORD, :LPSTR, :LPSTR, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :HWND, :HMENU, :HINSTANCE, :ptr
DefWindowProcA   proto :HWND, :DWORD, :WPARAM, :LPARAM
DestroyWindow    proto :HWND
DispatchMessageA proto :ptr MSG
DrawTextA        proto :HDC, :LPSTR, :DWORD, :ptr RECT, :DWORD
EndPaint         proto :HWND, :ptr PAINTSTRUCT
GetClientRect    proto :HWND, :ptr RECT
GetMessageA      proto :ptr MSG, :HWND, :DWORD, :DWORD
LoadBitmapA      proto :HINSTANCE, :LPSTR
LoadCursorA      proto :HINSTANCE, :LPSTR
LoadIconA        proto :HINSTANCE, :LPSTR
LoadMenuA        proto :HINSTANCE, :LPSTR
PostQuitMessage  proto :DWORD
RegisterClassExA proto :ptr WNDCLASSEXA
ShowWindow       proto :HWND, :DWORD
TranslateMessage proto :ptr MSG
UpdateWindow     proto :HWND

    option DLLIMPORT:<gdi32.dll>
BitBlt             proto :HDC, :DWORD, :DWORD, :DWORD, :DWORD, :HDC, :DWORD, :DWORD, :DWORD
CreateCompatibleDC proto :HDC
DeleteDC           proto :HDC
GetDIBits          proto :HDC, :HBITMAP, :DWORD, :DWORD, :ptr, :ptr BITMAPINFO, :DWORD
SelectObject       proto :HDC, :HGDIOBJ
    option DLLIMPORT:NONE

    .data

ClassName db "SimpleWinClass",0
AppName  db "Bitmap rendering",0

    .data?

hInstance HINSTANCE ?
hBitmap   HBITMAP ?
CommandLine LPSTR ?

    .code

start:
    invoke GetModuleHandleA, NULL
    mov    hInstance, eax
    invoke GetCommandLineA
    mov    CommandLine, eax
    invoke WinMain, hInstance, NULL, CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess, eax

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
    LOCAL wc:WNDCLASSEXA
    LOCAL msg:MSG
    LOCAL hwnd:HWND

    invoke LoadBitmapA, hInst, IDR_BITMAP1
    mov   hBitmap, eax

    mov   wc.cbSize, SIZEOF WNDCLASSEXA
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
    mov   wc.lpfnWndProc, OFFSET WndProc
    mov   wc.cbClsExtra, NULL
    mov   wc.cbWndExtra, NULL
    push  hInst
    pop   wc.hInstance
    mov   wc.hbrBackground, COLOR_WINDOW+1
    mov   wc.lpszMenuName, IDR_MENU1
    mov   wc.lpszClassName, OFFSET ClassName
    invoke LoadIconA, NULL, IDI_APPLICATION
    mov   wc.hIcon, eax
    mov   wc.hIconSm, eax
    invoke LoadCursorA, NULL, IDC_ARROW
    mov   wc.hCursor, eax
    invoke RegisterClassExA, addr wc

    invoke CreateWindowExA, NULL, ADDR ClassName, ADDR AppName,
           WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
           CW_USEDEFAULT, NULL, NULL, hInst, NULL
    mov   hwnd, eax
    invoke ShowWindow, hwnd, SW_SHOWNORMAL
    invoke UpdateWindow, hwnd
    .while (1)
        invoke GetMessageA, ADDR msg, NULL, 0, 0
        .break .if (!eax)
        invoke TranslateMessage, ADDR msg
        invoke DispatchMessageA, ADDR msg
    .endw
    mov   eax, msg.wParam
    ret
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

local hdc2:HDC
local ps:PAINTSTRUCT
local rect:RECT
local bmi:BITMAPINFOHEADER

    mov eax, uMsg
    .if eax == WM_DESTROY
        invoke PostQuitMessage, NULL
        xor eax,eax
    .elseif eax == WM_COMMAND
        .if wParam == IDM_EXIT
            invoke DestroyWindow, hWnd
        .endif
        xor eax, eax
    .elseif eax == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        invoke CreateCompatibleDC, ps.hdc
        mov hdc2, eax
        invoke SelectObject, hdc2, hBitmap
        mov bmi.biSize, sizeof BITMAPINFOHEADER
        mov bmi.biBitCount, 0
        invoke GetDIBits, hdc2, hBitmap, 0, 0, 0, addr bmi, DIB_RGB_COLORS
        invoke GetClientRect, hWnd, addr rect
        mov ecx, rect.right
        sub ecx, bmi.biWidth
        jnc @F
        xor ecx, ecx
@@:
        shr ecx, 1
        mov edx, rect.bottom
        sub edx, bmi.biHeight
        jnc @F
        xor edx, edx
@@:
        shr edx, 1
        invoke BitBlt, ps.hdc, ecx, edx, bmi.biWidth, bmi.biHeight, hdc2, 0, 0, SRCCOPY
        invoke DeleteDC, hdc2
        invoke EndPaint, hWnd, addr ps

        xor eax,eax
    .else
        invoke DefWindowProcA, hWnd, uMsg, wParam, lParam
    .endif
    ret
WndProc endp

    option dotname
.rsrc segment dword read FLAT public 'RSRC'
    include win32_8e.inc
.rsrc ends

;--- set /subsystem:windows
;--- the PE header is stored in section .hdr$2
    option dotname
.hdr$2 segment DWORD FLAT public 'HDR'
    org 5Ch ;position to IMAGE_NT_HEADER32.OptionalHeader.Subsystem
    dw 2    ;2=subsystem windows
.hdr$2 ends

end start
