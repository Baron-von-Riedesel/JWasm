
;--- a basic Windows driver (NT platform).
;--- it returns value of CR0, CR2 and CR3

;--- assemble: jwasm -coff Win32Drv.asm
;--- link:     link /subsystem:native Win32Drv.obj /base:0x10000 ntoskrnl.lib /out:Win32Drv.sys

;--- to run the driver, assemble, link and run the Win32DrvA.asm service control program.

;--- tool GdtDump from Four-F's KmdKit was used as a template for this driver.

    .386
    .model flat, stdcall
    option casemap:none

DRIVERNAME equ <"Win32Drv">

STATUS_SUCCESS                    equ 0
STATUS_UNSUCCESSFUL               equ 0C0000001h
STATUS_INVALID_DEVICE_REQUEST     equ 0C0000010h
STATUS_BUFFER_TOO_SMALL           equ 0C0000023h
STATUS_DEVICE_CONFIGURATION_ERROR equ 0C0000182h

NTSTATUS typedef SDWORD
TRUE equ 1

    include ntddk.inc		;small subset of the DDK definitions
    includelib ntoskrnl.lib

;--- macro to define a control code (may be found in winioctl.inc)
CTL_CODE macro DeviceType,Function,Method,Access
    exitm <( ( DeviceType shl 16 ) or ( Access shl 14 ) or  ( Function shl 2 )  or  Method )>
    endm

;--- define control code. this code must match the one in Win32DrvA.asm.
IOCTL_READ_INFO equ CTL_CODE( FILE_DEVICE_UNKNOWN, 800h, METHOD_BUFFERED, FILE_READ_ACCESS )

;--- prototypes of exports in ntoskrnl.exe
DbgPrintEx            proto c :DWORD, :DWORD, :ptr BYTE, :VARARG
IofCompleteRequest    proto fastcall :dword, :dword
IoCreateDevice        proto stdcall :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
IoCreateSymbolicLink  proto stdcall :DWORD, :DWORD
IoDeleteSymbolicLink  proto stdcall :DWORD
IoDeleteDevice        proto stdcall :DWORD

;--- macro to define a string constant

CStr macro Text:VARARG
local szText
    .const
szText  db Text,0
    .code
    exitm <offset szText>
endm

;--- macro to define a wide string

L macro parms:VARARG
local wstr
    wstr textequ <>
    for parm,<parms>
      ifidn <">,@SubStr(parm,1,1)
%       forc chr$, <@SubStr(parm,2,@SizeStr(parm)-2)>
          ifnb wstr
             wstr CatStr wstr,<,>
          endif
          wstr CatStr wstr,<'&chr$'>
        endm
      else
        ifnb wstr
           wstr CatStr wstr,<,>
        endif
        wstr CatStr wstr,<parm>
      endif
    endm
    exitm <wstr>
endm

	.const

name1 dw L( "\Device\", %DRIVERNAME ), 0
	align 4
name2 dw L( "\DosDevices\", %DRIVERNAME ), 0
	align 4

usDeviceName       UNICODE_STRING < sizeof name1 - 2, sizeof name1, name1 >
usSymbolicLinkName UNICODE_STRING < sizeof name2 - 2, sizeof name2, name2 >

    .code

DispatchCreateClose proc pDeviceObject:ptr DEVICE_OBJECT, pIrp:ptr IRP_

    invoke DbgPrintEx, DPFLTR_DEFAULT_ID, DPFLTR_INFO_LEVEL, CStr("Win32Drv.DispatchCreateClose entry",10)
    mov eax, pIrp
    mov [eax].IRP_.IoStatus.Status, STATUS_SUCCESS
    and [eax].IRP_.IoStatus.Information, 0

    invoke IofCompleteRequest, pIrp, IO_NO_INCREMENT

    mov eax, STATUS_SUCCESS
    ret

DispatchCreateClose endp


DispatchControl proc uses esi edi pDeviceObject:ptr DEVICE_OBJECT, pIrp:ptr IRP_

    mov esi, pIrp
    mov [esi].IRP_.IoStatus.Status, STATUS_UNSUCCESSFUL
    and [esi].IRP_.IoStatus.Information, 0
    mov edi, [esi].IRP_.Tail.Overlay.CurrentStackLocation

    .if [edi].IO_STACK_LOCATION.Parameters.DeviceIoControl.IoControlCode == IOCTL_READ_INFO

        invoke DbgPrintEx, DPFLTR_DEFAULT_ID, DPFLTR_INFO_LEVEL, CStr("Win32Drv.DispatchControl, CC=IOCTL_READ_INFO",10)
        .if [edi].IO_STACK_LOCATION.Parameters.DeviceIoControl.OutputBufferLength >= 3 * sizeof DWORD

            mov ecx, [esi].IRP_.AssociatedIrp.SystemBuffer

            ; get value of CR0, CR2 and CR3 
            mov eax, cr0
            mov [ecx+0], eax
            mov eax, cr2
            mov [ecx+4], eax
            mov eax, cr3
            mov [ecx+8], eax

            mov [esi].IRP_.IoStatus.Information, 3*4
            mov [esi].IRP_.IoStatus.Status, STATUS_SUCCESS

        .else
            mov [esi].IRP_.IoStatus.Status, STATUS_BUFFER_TOO_SMALL
        .endif

    .else
        mov [esi].IRP_.IoStatus.Status, STATUS_INVALID_DEVICE_REQUEST
    .endif

    ; save status BEFORE IofCompleteRequest
    push [esi].IRP_.IoStatus.Status
    invoke IofCompleteRequest, esi, IO_NO_INCREMENT
    pop eax
    ret

DispatchControl endp


DriverUnload proc pDriverObject:ptr DRIVER_OBJECT

    invoke DbgPrintEx, DPFLTR_DEFAULT_ID, DPFLTR_INFO_LEVEL, CStr("Win32Drv.DriverUnload entry",10)
    invoke IoDeleteSymbolicLink, addr usSymbolicLinkName
    .if ( eax != STATUS_SUCCESS )
        invoke DbgPrintEx, DPFLTR_DEFAULT_ID, DPFLTR_INFO_LEVEL, CStr("Win32Drv.DriverUnload: IoDeleteSymbolicLink() failed [%u]",10), eax
    .endif
    mov eax, pDriverObject
    invoke IoDeleteDevice, [eax].DRIVER_OBJECT.DeviceObject
    ret

DriverUnload endp

;--- driver initialization

DriverEntry proc pDriverObject:ptr DRIVER_OBJECT, pRegistryPath:ptr UNICODE_STRING

local status:NTSTATUS
local pDeviceObject:ptr DEVICE_OBJECT

    invoke DbgPrintEx, DPFLTR_DEFAULT_ID, DPFLTR_INFO_LEVEL, CStr("Win32Drv.DriverEntry entry",10)
    invoke IoCreateDevice, pDriverObject, 0, addr usDeviceName, FILE_DEVICE_UNKNOWN, 0, TRUE, addr pDeviceObject
    mov status, eax
    .if eax == STATUS_SUCCESS
        invoke DbgPrintEx, DPFLTR_DEFAULT_ID, DPFLTR_INFO_LEVEL, CStr("Win32Drv.DriverEntry: IoCreateDevice() ok",10)
        invoke IoCreateSymbolicLink, addr usSymbolicLinkName, addr usDeviceName
        .if eax == STATUS_SUCCESS
            invoke DbgPrintEx, DPFLTR_DEFAULT_ID, DPFLTR_INFO_LEVEL, CStr("Win32Drv.DriverEntry: IoCreateSymbolikLink() ok",10)
            mov eax, pDriverObject
            mov [eax].DRIVER_OBJECT.MajorFunction[IRP_MJ_CREATE * sizeof PVOID], offset DispatchCreateClose
            mov [eax].DRIVER_OBJECT.MajorFunction[IRP_MJ_CLOSE * sizeof PVOID], offset DispatchCreateClose
            mov [eax].DRIVER_OBJECT.MajorFunction[IRP_MJ_DEVICE_CONTROL * sizeof PVOID], offset DispatchControl
            mov [eax].DRIVER_OBJECT.DriverUnload, offset DriverUnload
            mov status, STATUS_SUCCESS
        .else
            mov status, eax
            invoke IoDeleteDevice, pDeviceObject
        .endif
    .endif
    mov eax, status
    ret

DriverEntry endp

end DriverEntry
