
;--- print 64-bit commandline arguments
;--- uses msvcrt.dll
;--- to link this program, enter:
;--- link win64_6x.obj crtexe.obj

	option casemap:none
	option frame:auto
	option win64:3

	includelib msvcrt.lib

printf proto : vararg

CStr macro text:vararg
local xxx
	.const
xxx db text, 0
	.code
	exitm <offset xxx>
endm

    .code

main proc frame argc:dword, argv:ptr ptr byte

	mov rbx, argv
	.while argc
		mov rax, [rbx]
		invoke printf, CStr("%s",10), rax
		add rbx, 8
		dec argc
	.endw
	ret

main endp

    end
