
;--- create a 64-bit binary with -pe cmdline option
;---
;---   JWasm -pe Win64_8.asm

    .x64                ; -pe requires to set cpu, model & language
    .model flat, fastcall

    option casemap:none
    option frame:auto   ; generate SEH-compatible prologues and epilogues
    option win64:3      ; init shadow space, reserve stack at PROC level

;--- resource IDs
IDR_MENU1   EQU 100
IDR_BITMAP1 EQU 101
IDM_EXIT    EQU 1000

NULL      equ 0
LPSTR     typedef ptr
LPVOID    typedef ptr
UINT      typedef DWORD
BOOL      typedef DWORD

;--- winbase definitions
HINSTANCE typedef ptr

;--- winuser definitions
HWND      typedef ptr
HMENU     typedef ptr
HICON     typedef ptr
HBRUSH    typedef ptr
HCURSOR   typedef ptr
HDC       typedef ptr
HBITMAP   typedef ptr
WPARAM    typedef ptr
LPARAM    typedef QWORD

WS_OVERLAPPEDWINDOW equ 0CF0000h
CW_USEDEFAULT  equ 80000000h
SW_SHOWDEFAULT equ 10
SW_SHOWNORMAL  equ 1
IDC_ARROW      equ 32512
IDI_APPLICATION equ 32512
CS_VREDRAW     equ 1
CS_HREDRAW     equ 2
COLOR_WINDOW   equ 5

WM_DESTROY     equ 2
WM_PAINT       equ 000Fh
WM_COMMAND     equ 0111h

proto_WNDPROC typedef proto :HWND,:QWORD,:WPARAM,:LPARAM
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

RECT struct
left    SDWORD  ?
top     SDWORD  ?
right   SDWORD  ?
bottom  SDWORD  ?
RECT ends

PAINTSTRUCT struct 8
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

    option dllimport:<kernel32.dll>
GetModuleHandleA proto :LPSTR
GetCommandLineA  proto
ExitProcess      proto :UINT

    option dllimport:<user32.dll>
BeginPaint       proto :HWND, :ptr PAINTSTRUCT
CreateWindowExA  proto :DWORD, :LPSTR, :LPSTR, :DWORD, :SDWORD, :SDWORD, :SDWORD, :SDWORD, :HWND, :HMENU, :HINSTANCE, :LPVOID
DefWindowProcA   proto :HWND, :UINT, :WPARAM, :LPARAM
DestroyWindow    proto :HWND
DispatchMessageA proto :ptr MSG
EndPaint         proto :HWND, :ptr PAINTSTRUCT
GetClientRect    proto :HWND, :ptr RECT
GetMessageA      proto :ptr MSG, :HWND, :SDWORD, :SDWORD
LoadBitmapA      proto :HINSTANCE, :LPSTR
LoadCursorA      proto :HINSTANCE, :LPSTR
LoadIconA        proto :HINSTANCE, :LPSTR
PostQuitMessage  proto :SDWORD
RegisterClassExA proto :ptr WNDCLASSEXA
ShowWindow       proto :HWND, :SDWORD
TranslateMessage proto :ptr MSG
UpdateWindow     proto :HWND

    option DLLIMPORT:<gdi32.dll>
BitBlt             proto :HDC, :DWORD, :DWORD, :DWORD, :DWORD, :HDC, :DWORD, :DWORD, :DWORD
CreateCompatibleDC proto :HDC
DeleteDC           proto :HDC
GetDIBits          proto :HDC, :HBITMAP, :DWORD, :DWORD, :ptr, :ptr BITMAPINFO, :DWORD
SelectObject       proto :HDC, :HGDIOBJ
    option dllimport:none

WinMain proto :HINSTANCE, :HINSTANCE, :LPSTR, :UINT

    .data

ClassName db "SimpleWinClass",0
AppName  db "Bitmap rendering",0

    .data?

hInstance HINSTANCE ?
hBitmap   HBITMAP ?
CommandLine LPSTR ?

    .code

WinMainCRTStartup proc FRAME

    invoke GetModuleHandleA, NULL
    mov    hInstance, rax
    invoke GetCommandLineA
    mov    CommandLine, rax
    invoke WinMain, hInstance, NULL, CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess, eax

WinMainCRTStartup endp

WinMain proc FRAME hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:UINT

    LOCAL wc:WNDCLASSEXA
    LOCAL msg:MSG
    LOCAL hwnd:HWND

    invoke LoadBitmapA, hInst, IDR_BITMAP1
    mov   hBitmap, rax

    mov   wc.cbSize, SIZEOF WNDCLASSEXA
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
    lea   rax, [WndProc]
    mov   wc.lpfnWndProc, rax
    mov   wc.cbClsExtra, 0
    mov   wc.cbWndExtra, 0
    mov   rcx, hInst
    mov   wc.hInstance, rcx
    mov   wc.hbrBackground, COLOR_WINDOW+1
    mov   wc.lpszMenuName, IDR_MENU1
    lea   rax, [ClassName]
    mov   wc.lpszClassName, rax
    invoke LoadIconA, NULL, IDI_APPLICATION
    mov   wc.hIcon, rax
    mov   wc.hIconSm, rax
    invoke LoadCursorA, NULL, IDC_ARROW
    mov   wc.hCursor,rax
    invoke RegisterClassExA, addr wc
    invoke CreateWindowExA, NULL, ADDR ClassName, ADDR AppName,
           WS_OVERLAPPEDWINDOW, CW_USEDEFAULT,
           CW_USEDEFAULT, CW_USEDEFAULT,CW_USEDEFAULT, NULL, NULL,
           hInst, NULL
    mov   hwnd,rax
    invoke ShowWindow, hwnd, SW_SHOWNORMAL
    invoke UpdateWindow, hwnd
    .while (1)
        invoke GetMessageA, ADDR msg, NULL, 0, 0
        .break .if (!eax)
        invoke TranslateMessage, ADDR msg
        invoke DispatchMessageA, ADDR msg
    .endw
    mov   rax, msg.wParam
    ret
WinMain endp

WndProc proc FRAME hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

local hdc2:HDC
local ps:PAINTSTRUCT
local rect:RECT
local bmi:BITMAPINFOHEADER

    .if edx == WM_DESTROY
        invoke PostQuitMessage, NULL
        xor rax,rax
    .elseif edx == WM_COMMAND
        .if wParam == IDM_EXIT
            invoke DestroyWindow, hWnd
        .endif
        xor eax, eax
    .elseif edx == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        invoke CreateCompatibleDC, ps.hdc
        mov hdc2, rax
        invoke SelectObject, hdc2, hBitmap
        mov bmi.biSize, sizeof BITMAPINFOHEADER
        mov bmi.biBitCount, 0
        invoke GetDIBits, hdc2, hBitmap, 0, 0, 0, addr bmi, DIB_RGB_COLORS
        invoke GetClientRect, hWnd, addr rect
        mov r8d, rect.right
        sub r8d, bmi.biWidth
        jnc @F
        xor r8d, r8d
@@:
        shr r8d, 1
        mov r9d, rect.bottom
        sub r9d, bmi.biHeight
        jnc @F
        xor r9d, r9d
@@:
        shr r9d, 1
        invoke BitBlt, ps.hdc, r8d, r9d, bmi.biWidth, bmi.biHeight, hdc2, 0, 0, SRCCOPY
        invoke DeleteDC, hdc2
        invoke EndPaint, hWnd, addr ps

        xor eax,eax
    .else
        invoke DefWindowProcA, rcx, edx, r8, r9
    .endif
    ret
WndProc endp

if 1 ;for -pe

RT_BITMAP EQU 2
RT_MENU   EQU 4

;--- menu resource flags
MF_POPUP   EQU 10h
MF_END     EQU 80h

IMAGE_RESOURCE_DIRECTORY struct
Characteristics      DWORD ?
TimeDateStamp        DWORD ?
MajorVersion         WORD  ?
MinorVersion         WORD  ?
NumberOfNamedEntries WORD  ?
NumberOfIdEntries    WORD  ?
IMAGE_RESOURCE_DIRECTORY ends

IMAGE_RESOURCE_DIRECTORY_ENTRY struct
union
r0      RECORD NameIsString:1, NameOffset:31
Name_   DWORD   ?
Id      WORD    ?
ends
union
OffsetToData DWORD   ?
r1           RECORD	DataIsDirectory:1, OffsetToDirectory:31
ends
IMAGE_RESOURCE_DIRECTORY_ENTRY ends

IMAGE_RESOURCE_DATA_ENTRY struct
OffsetToData DWORD ?
Size_        DWORD ?
CodePage     DWORD ?
Reserved     DWORD ?
IMAGE_RESOURCE_DATA_ENTRY ends

    option dotname

.rsrc segment dword read FLAT public 'RSRC'

;--- define menu IDR_MENU1 and bitmap IDR_BITMAP1

;--- root level: enum the resource types
      IMAGE_RESOURCE_DIRECTORY <0,0,0,0,0,2>
      IMAGE_RESOURCE_DIRECTORY_ENTRY < <RT_BITMAP>, <SECTIONREL bms   + 80000000h> >
      IMAGE_RESOURCE_DIRECTORY_ENTRY < <RT_MENU>,   <SECTIONREL menus + 80000000h> >

;--- second level: enum the IDs of resource type X
bms   IMAGE_RESOURCE_DIRECTORY <0,0,0,0,0,1>
      IMAGE_RESOURCE_DIRECTORY_ENTRY < <IDR_BITMAP1>, <SECTIONREL bm1   + 80000000h> >
menus IMAGE_RESOURCE_DIRECTORY <0,0,0,0,0,1>
      IMAGE_RESOURCE_DIRECTORY_ENTRY < <IDR_MENU1>,   <SECTIONREL menu1 + 80000000h> >

;--- third level: enum the languages of ID X
bm1   IMAGE_RESOURCE_DIRECTORY <0,0,0,0,0,1>
      IMAGE_RESOURCE_DIRECTORY_ENTRY < <409h>, <SECTIONREL bm1_l1> >
menu1 IMAGE_RESOURCE_DIRECTORY <0,0,0,0,0,1>
      IMAGE_RESOURCE_DIRECTORY_ENTRY < <409h>, <SECTIONREL m1_l1> >

;--- last level: define the resource data
;--- data for menu IDR_MENU1, language 409h
m1_l1 IMAGE_RESOURCE_DATA_ENTRY <IMAGEREL m1_l1_data, size_m1_l1, 0, 0>
m1_l1_data dw 0,0	;menu header
    dw MF_POPUP or MF_END, '&','F','i','l','e',0
    dw MF_END, IDM_EXIT,   'E','&','x','i','t',0
size_m1_l1 equ $ - m1_l1_data
    align 4

;--- data for bitmap IDR_BITMAP1
bm1_l1 IMAGE_RESOURCE_DATA_ENTRY <IMAGEREL bm1_l1_data, size_bm1_l1, 0, 0>
bm1_l1_data label word
    incbin <Win32_8.bmp>,14	;skip bitmap file header
size_bm1_l1 equ $ - ( bm1_l1_data )

.rsrc ends

;--- set /subsystem:windows
;--- the PE header is stored in section .hdr$2
    option dotname
.hdr$2 segment DWORD FLAT public 'HDR'
    org 5Ch ;position to IMAGE_NT_HEADER64.OptionalHeader.Subsystem
    dw 2    ;2=subsystem windows
.hdr$2 ends

endif

end WinMainCRTStartup
