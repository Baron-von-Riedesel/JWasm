
;--- a Windows GUI app to demonstrate -pe cmdline option.
;--- a menu and a bitmap resource are defined "manually".
;--- Unlike Win32_8, this sample uses Masm32 include files.
;---
;--- to create the binary enter:
;---   JWasm -pe Win32_8m.asm
;--- expects bitmap "Win32_8.bmp" in current directory.

    .486
    .model flat,stdcall
    option casemap:none

    include \masm32\include\windows.inc
    option dllimport:<kernel32.dll>
    include \masm32\include\kernel32.inc
    option dllimport:<gdi32.dll>
    include \masm32\include\gdi32.inc
    option dllimport:<user32.dll>
    include \masm32\include\user32.inc
    option dllimport:none

;--- resource IDs
IDR_MENU1   EQU 100
IDR_BITMAP1 EQU 101
IDM_EXIT    EQU 1000

WinMain proto :HINSTANCE, :HINSTANCE, :LPSTR, :DWORD

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
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL hwnd:HWND

    invoke LoadBitmapA, hInst, IDR_BITMAP1
    mov   hBitmap, eax

    mov   wc.cbSize, SIZEOF WNDCLASSEX
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

WndProc proc hWnd:HWND, uMsg:DWORD, wParam:WPARAM, lParam:LPARAM

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

if 1 ;1 for PE format: define resources

    option dotname

.rsrc segment dword read FLAT public 'RSRC'

;--- define menu IDR_MENU1 and bitmap IDR_BITMAP1

      IMAGE_RESOURCE_DIRECTORY <0,0,0,0,0,2>
      IMAGE_RESOURCE_DIRECTORY_ENTRY < <RT_BITMAP>, <SECTIONREL bms   + 80000000h> >
      IMAGE_RESOURCE_DIRECTORY_ENTRY < <RT_MENU>,   <SECTIONREL menus + 80000000h> >

bms   IMAGE_RESOURCE_DIRECTORY <0,0,0,0,0,1>
      IMAGE_RESOURCE_DIRECTORY_ENTRY < <IDR_BITMAP1>, <SECTIONREL bm1   + 80000000h> >
menus IMAGE_RESOURCE_DIRECTORY <0,0,0,0,0,1>
      IMAGE_RESOURCE_DIRECTORY_ENTRY < <IDR_MENU1>,   <SECTIONREL menu1 + 80000000h> >
bm1   IMAGE_RESOURCE_DIRECTORY <0,0,0,0,0,1>
      IMAGE_RESOURCE_DIRECTORY_ENTRY < <409h>, <SECTIONREL bm1_l1> >
menu1 IMAGE_RESOURCE_DIRECTORY <0,0,0,0,0,1>
      IMAGE_RESOURCE_DIRECTORY_ENTRY < <409h>, <SECTIONREL m1_l1> >

m1_l1 IMAGE_RESOURCE_DATA_ENTRY <IMAGEREL m1_l1_data, size_m1_l1, 0, 0>
m1_l1_data dw 0,0	;menu header
    dw MF_POPUP or MF_END, '&','F','i','l','e',0
    dw MF_END, IDM_EXIT,   'E','&','x','i','t',0
size_m1_l1 equ $ - m1_l1_data
    align 4

bm1_l1 IMAGE_RESOURCE_DATA_ENTRY <IMAGEREL bm1_l1_data, size_bm1_l1, 0, 0>
bm1_l1_data label word
    incbin <Win32_8.bmp>,14	;skip bitmap file header
size_bm1_l1 equ $ - ( bm1_l1_data )

.rsrc ends

;--- set /subsystem:windows
    option dotname
.hdr$2 segment DWORD FLAT public 'HDR'
    org IMAGE_NT_HEADERS.OptionalHeader.Subsystem
    dw 2    ;2=Windows GUI
.hdr$2 ends

endif

end start
