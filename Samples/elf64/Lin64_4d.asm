
;--- jwasm -elf64 -Zd -zcw -pic2 Lin64_4d.asm
;--- see mLin64_4.sh for linking

`.note.GNU-stack` segment info
`.note.GNU-stack` ends

	.data

string db ">string returned by Lin64_4d<",10,0

	.code

so_getvalue proc export uses rsi rdi

	lea rsi, string
@@:
	lodsb
	stosb
	and al,al
	jnz @B
	ret

so_getvalue endp

	end
