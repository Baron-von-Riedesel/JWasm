
;--- "hello world" for 64-bit Linux, using external printf;
;--- with line number debug info.
;--- assemble: JWasm -elf64 -zcw -Zd Lin64_2.asm
;--- link:     gcc -g Lin64_2.o -o Lin64_2

printf proto c :ptr byte, :vararg

`.note.GNU-stack` segment info ; define this segment to suppress ld linker warning
`.note.GNU-stack` ends

	.data

string  db "Hello, world!",10,0

	.code

main proc
	push rbp	;align rsp
	lea rdi, string
	xor eax, eax	;no xmm registers used
	call printf
	pop rbp
	ret
main endp

	end
