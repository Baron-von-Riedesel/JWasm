
;--- sample demonstrates how to 
;--- + define static TLS variables ( "__declspec(thread)" in MSC) in assembly. 
;--- + access static thread variables.
;--- + use OPTION CODEVIEW to make debugger access the items correctly.

;--- from an assembly point of view, there is not much gained with
;--- static TLS. Unlike in C, access isn't transparent, it's quite similiar
;--- to variables allocated vis TlsAlloc().

;--- assemble: jwasm -coff win32tls.asm
;--- link:     link win32tls.obj /subsystem:console kernel32.lib msvcrt.lib

	.386
	.model FLAT, stdcall
	option casemap:none

;--- TLS directory definition from PE/COFF specification (32-bit)
IMAGE_TLS_DIRECTORY32  struct 
StartAddressOfRawData  DWORD ?
EndAddressOfRawData    DWORD ?
AddressOfIndex         DWORD ?
AddressOfCallBacks     DWORD ?
SizeOfZeroFill         DWORD ?
Characteristics        DWORD ?
IMAGE_TLS_DIRECTORY32  ends

HANDLE typedef ptr

;--- Win32 functions used in this program
CloseHandle  proto :ptr
CreateMutexA proto :ptr, :dword, :ptr
CreateThread proto :ptr, :dword, :ptr, :ptr, :dword, :ptr
ExitProcess  proto :dword
ReleaseMutex proto :ptr
Sleep        proto :dword
WaitForMultipleObjects proto :dword, :ptr, :dword, :dword
WaitForSingleObject    proto :ptr, :dword

;--- CRT functions used in this program
memset proto c :ptr, :dword, :dword
printf proto c :vararg

;--- macro to define a text constant
CStr macro Text:VARARG
local szText
    .const
szText  db Text,0
    .code
    exitm <offset szText>
endm

;--- macro to access thread variables
TLSACC macro var
	mov eax,fs:[2Ch]	;this is Win32-specific
	mov edx,tls_index
	mov eax,[eax+edx*4]
	exitm <[eax + sectionrel var]>
endm

ifdef __JWASM__
;--- if option -Zi is set and debugger is to show correct value
;--- of static thread variables, option codeview:1 must be set.
	option codeview:1
endif

_TLS segment dword alias(".tls") public 'TLS'
tls_start label byte ;start of initialized thread variables
var1 DD -1
tls_end label byte   ;end of initialized thread variables
_TLS ends

	.const

;--- the important thing is public "_tls_used".
;--- if the linker finds this global label, it will set the TLS data
;--- directory entry in the PE binary.

	public _tls_used	;tell the linker that a TLS directory is wanted
_tls_used IMAGE_TLS_DIRECTORY32 <tls_start, tls_end, tls_index, tls_cb_array>

;--- zero-terminated array of TLS callbacks
tls_cb_array label ptr
	dd tls_callback
	dd 0

	.data

tls_index dd -1	;this variable will receive the index allocated by the loader

	.data?

g_hMutex HANDLE ?

	.code

	assume fs:nothing

;--- thread callback - does nothing
tls_callback proc hMod:HANDLE, Reason:dword, Reserved:ptr
;	invoke printf, CStr("tls_callback: reason=%d",10), Reason
	ret
tls_callback endp

;--- thread procedure

threadproc proc uses ebx lParam:dword

;--- use mutex to serialize access to printf (not needed for msvcrt)
	invoke WaitForSingleObject, g_hMutex, 5000
	lea eax, TLSACC(var1)
	mov ecx, TLSACC(var1)
	invoke printf, CStr("thread(%u): init var1=%d &var1=%Xh",10), lParam, ecx, eax
	invoke ReleaseMutex, g_hMutex

;--- release time slice so the other threads will get a chance to run
	invoke Sleep, 0
;--- modify the thread variable
	mov ecx, lParam
	mov TLSACC(var1), ecx

;--- use mutex to serialize access to printf (not needed for msvcrt)
	invoke WaitForSingleObject, g_hMutex, 5000
	mov ecx, TLSACC(var1)
	invoke printf, CStr("thread(%u): mod. var1=%d",10), lParam, ecx
	invoke ReleaseMutex, g_hMutex

	ret
	align 4

threadproc endp


start:

mainCRTStartup proc 

local hConInp:HANDLE
local hThread[10]:HANDLE

	invoke printf, CStr("main: tls_index=%d",10), tls_index

;--- create a mutex to synchronize access to printf()
	invoke CreateMutexA, 0, 0, 0
	mov g_hMutex, eax

;--- reset thread handles
	invoke memset, addr hThread, 0, sizeof hThread

;--- start threads
	mov esi,0
	lea ebx, hThread
	.while esi < lengthof hThread
		invoke CreateThread, 0, 4000h, offset threadproc, esi, 0, 0
		mov [ebx], eax
		inc esi
		;invoke printf, CStr("main: %u. CreateThread()=%X",10), esi, eax
		add ebx, sizeof HANDLE
	.endw

;--- wait until all threads are done
	invoke WaitForMultipleObjects, lengthof hThread, addr hThread, 1, 5000

	invoke CloseHandle, g_hMutex

	mov ecx, TLSACC(var1)
	lea eax, TLSACC(var1)
	invoke printf, CStr("main: var1=%d &var1=%X",10), ecx, eax

	invoke ExitProcess, 0
	ret
	align 4
mainCRTStartup endp

	END start
