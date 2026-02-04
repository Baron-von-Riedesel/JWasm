
;--- sample how to create a pie in 32-bit assembly; requires jwasm v2.21+
;--- assemble: jwasm -elf -zcw Linux6.asm

    .386
    .model flat

externdef _GLOBAL_OFFSET_TABLE_:near

`.note.GNU-stack` segment info
`.note.GNU-stack` ends

printf proto c :ptr, :vararg

;--- get position-independent offset, assuming ebx=GOT;
;--- SECTIONREL qualifier reused in ELF for GOTOFF relocation type.
@ofs macro symbol
	exitm <[ebx][sectionrel symbol]>
endm

	.const

fmtstr1 db "GOT=%X",10,0
fmtstr2 db "ImageBase=%X",10,0

    .code

main proc
	call geteip_ebx
	add ebx, _GLOBAL_OFFSET_TABLE_ + 2
    lea eax, @ofs(fmtstr1)
    invoke printf, eax, ebx
    call @F
@@:
	pop edx
    mov ecx, imagerel @B
    sub edx, ecx
    lea eax, @ofs(fmtstr2)
    invoke printf, eax, edx
    ret
geteip_ebx:
	mov ebx,[esp]
	retn
main endp

    end

