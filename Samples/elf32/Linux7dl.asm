
;--- source for (position-independent) shared lib Linux7dl.so;
;--- requires jwasm v2.21+;
;--- assemble: jwasm -elf -zcw -pic2 Linux7dl.asm

    .386
    .model flat

externdef _GLOBAL_OFFSET_TABLE_:near
externdef export so_data1:dword

`.note.GNU-stack` segment info
`.note.GNU-stack` ends

strcpy proto c :ptr, :ptr

@ofs macro symbol
	exitm <[ebx][sectionrel symbol]>
endm

	.const

string1 db "string 1",0

	.data

so_data1 dd 1234

	.code

;--- with -pic2, only exported symbols will
;--- become visible outside the component.

so_func1 proc c export uses ebx a1:ptr

	call geteip_ebx
	add ebx, _GLOBAL_OFFSET_TABLE_ + 2
	lea edx, @ofs(string1)
	invoke strcpy, a1, edx
	ret
geteip_ebx::
	mov ebx,[esp]
	retn

so_func1 endp

;--- so_func2() increments so_data1
;--- since so_data1 is exported, access is
;--- thru a GOT entry; accessing so_data1 gets
;--- the (GOT-relative) address of that entry!

so_func2 proc export uses ebx
	call geteip_ebx
	add ebx, _GLOBAL_OFFSET_TABLE_ + 2
	mov eax, [ebx][so_data1]  ;get address of so_data1
	inc dword ptr [eax]       ;increment so_data1
	ret
so_func2 endp

	end

