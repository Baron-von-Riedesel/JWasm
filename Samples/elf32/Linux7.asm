
;--- create pie and shared object in 32-bit assembly.
;--- calls 2 exports in Linux7dl.so;
;--- and accesses exported data (so_data1).

    .386
    .model flat

externdef _GLOBAL_OFFSET_TABLE_:near

`.note.GNU-stack` segment info
`.note.GNU-stack` ends

printf proto c :ptr, :vararg
so_func1 proto c :dword
so_func2 proto c
externdef export so_data1:dword

;--- get position-independent offset, assuming ebx=GOT;
;--- SECTIONREL qualifier reused in ELF for GOTOFF relocation type.
@ofs macro symbol
	exitm <[ebx][sectionrel symbol]>
endm

	.const

fmtstr1 db "so_func1()=>%s<",10,0
fmtstr2 db "so_data1()=>%d<",10,0
fmtstr3 db "so_func2() called<",10,0

	.code

main proc

local buffer[64]:byte

;--- get GOT address into ebx
	call geteip_ebx
	add ebx, _GLOBAL_OFFSET_TABLE_ + 2

;--- call so_func1(), which returns a string in buffer
	invoke so_func1, addr buffer
	lea edx, @ofs(fmtstr1)
	invoke printf, edx, addr buffer

;--- read and display so_data1
	mov eax, @ofs(so_data1)
	lea edx, @ofs(fmtstr2)
	invoke printf, edx, eax

;--- so_func2() will increment so_data1
	invoke so_func2
	lea edx, @ofs(fmtstr3)
	invoke printf, edx

;--- reread and display so_data1
	lea edx, @ofs(fmtstr2)
	mov eax, @ofs(so_data1)
	invoke printf, edx, eax
	ret
geteip_ebx:
	mov ebx,[esp]
	retn
main endp

	end

