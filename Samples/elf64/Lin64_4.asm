
;--- jwasm -elf64 -Zd -zcw Lin64_4.asm
;--- see mLin64_4.sh how to link

`.note.GNU-stack` segment info
`.note.GNU-stack` ends

printf proto c :ptr byte, :vararg

;--- function defined in Lin64_4d.asm
so_getvalue proto c :ptr byte

	.data

string db "start Lin64_4",10,0

	.data?

buffer db 128 dup (?)

	.code

main proc
	push rbp	;align rsp
	lea rdi, string
	xor eax, eax
	call printf
	lea rdi, buffer
	call so_getvalue
	xor eax, eax
	call printf
	pop rbp
	ret
main endp

	end
