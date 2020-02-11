
;---  Win32DrvA - Service Control Program to load 32-bit driver Win32Drv.sys
;---  assemble: jwasm -coff Win32DrvA.asm
;---  link:     link Win32DrvA.obj /out:Win32Drv.exe /subsystem:console /Libpath:\wininc\lib

    .386
    .model flat, stdcall
    option casemap:none

    .nolist
    .nocref
WIN32_LEAN_AND_MEAN equ 1
    include \wininc\include\windows.inc
    include \wininc\include\winioctl.inc
    .list
    .cref

    includelib kernel32.lib
    includelib user32.lib
    includelib advapi32.lib
    includelib msvcrt.lib

;--- driver name to load
DRIVERNAME equ <"Win32Drv">

;--- control code used to talk to driver
IOCTL_READ_INFO equ CTL_CODE( FILE_DEVICE_UNKNOWN, 800h, METHOD_BUFFERED, FILE_READ_ACCESS )

CStr macro Text:VARARG
local szText
    .const
szText  db Text,0
    .code
    exitm <offset szText>
endm

printf proto c :VARARG

    .data

buffer dd 3 dup (0)

    .code

;--- display the infos returned by driver

PrintInfo proc pBuffer:ptr
    mov edx, pBuffer
    mov eax,[edx+0]
    mov ecx,[edx+4]
    mov edx,[edx+8]
    invoke printf, CStr("CR0=%X, CR2=%X, CR3=%X",10), eax, ecx, edx
    ret
PrintInfo endp

start proc

local hSCManager:HANDLE
local hService:HANDLE
local hDevice:HANDLE
local dwBytesReturned:DWORD
local sstat:SERVICE_STATUS
local szDriverPath[MAX_PATH]:CHAR

    invoke OpenSCManager, NULL, NULL, SC_MANAGER_CREATE_SERVICE
    .if eax != NULL
        mov hSCManager, eax

        push eax ; make room on stack for return value
        invoke GetFullPathName, CStr( DRIVERNAME, ".sys" ), sizeof szDriverPath, addr szDriverPath, esp
        pop eax  ; get return value and restore stack

        ; Register driver in SCM database
        invoke CreateService, hSCManager, CStr( DRIVERNAME, ".sys" ), CStr("get some low-level system information"),
                SERVICE_START or SERVICE_STOP or DELETE, SERVICE_KERNEL_DRIVER, SERVICE_DEMAND_START,
                SERVICE_ERROR_IGNORE, addr szDriverPath, NULL, NULL, NULL, NULL, NULL
        .if eax != NULL
            mov hService, eax
            invoke StartService, hService, 0, NULL
            .if ( eax  )
                mov esi, CStr( "\\.\", DRIVERNAME )
                invoke CreateFile, esi, GENERIC_READ, 0, NULL, OPEN_EXISTING, 0, NULL
                .if eax != INVALID_HANDLE_VALUE
                    mov hDevice, eax
                    invoke DeviceIoControl, hDevice, IOCTL_READ_INFO, NULL, 0,
                            addr buffer, sizeof buffer, addr dwBytesReturned, NULL
                    .if ( eax != 0 ) && ( dwBytesReturned != 0 )
                        invoke PrintInfo, addr buffer
                    .else
                        invoke GetLastError
                        invoke printf, CStr("DeviceIoControl() failed [%u], bytes returned=%u.",10), eax, dwBytesReturned
                    .endif
                    invoke CloseHandle, hDevice
                .else
                    invoke GetLastError
                    invoke printf, CStr("CreateFile('%s') failed [%u], can't talk to driver."), esi, eax
                .endif
                invoke ControlService, hService, SERVICE_CONTROL_STOP, addr sstat
                .if ( eax == 0 )
                    invoke GetLastError
                    invoke printf, CStr("ControlService() failed [%u], can't stop the kernel driver service."), eax
                .endif
            .else
                invoke GetLastError
                invoke printf, CStr("StartService() failed [%u]",10), eax
            .endif
            invoke DeleteService, hService
            invoke CloseServiceHandle, hService
        .else
            invoke GetLastError
            invoke printf, CStr("CreateService() failed [%u], can't register driver.",10), eax
        .endif
        invoke CloseServiceHandle, hSCManager
    .else
        invoke GetLastError
        invoke printf, CStr("OpenSCManager() failed [%u], can't connect to Service Control Manager.",10), eax
    .endif

    invoke ExitProcess, 0

start endp

end start
