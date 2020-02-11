
;--- Enable alternative register names (64-bit only).
;--- Once the file has been included, most of the 
;--- old names are gone, and the new names are:

;---           registers 
;--------------------------------------------
;---  64-bit   r0  - r15
;---  32-bit   r0d - r15d
;---  16-bit   r0w - r15w
;---   8-bit   r0b - r15b    ah, bh, ch, dh

	option renamekeyword:<rax>=r0
	option renamekeyword:<rcx>=r1
	option renamekeyword:<rdx>=r2
	option renamekeyword:<rbx>=r3
	option renamekeyword:<rsp>=r4
	option renamekeyword:<rbp>=r5
	option renamekeyword:<rsi>=r6
	option renamekeyword:<rdi>=r7
	option renamekeyword:<eax>=r0d
	option renamekeyword:<ecx>=r1d
	option renamekeyword:<edx>=r2d
	option renamekeyword:<ebx>=r3d
	option renamekeyword:<esp>=r4d
	option renamekeyword:<ebp>=r5d
	option renamekeyword:<esi>=r6d
	option renamekeyword:<edi>=r7d
	option renamekeyword:<ax>=r0w
	option renamekeyword:<cx>=r1w
	option renamekeyword:<dx>=r2w
	option renamekeyword:<bx>=r3w
	option renamekeyword:<sp>=r4w
	option renamekeyword:<bp>=r5w
	option renamekeyword:<si>=r6w
	option renamekeyword:<di>=r7w
	option renamekeyword:<al>=r0b
	option renamekeyword:<cl>=r1b
	option renamekeyword:<dl>=r2b
	option renamekeyword:<bl>=r3b
	option renamekeyword:<spl>=r4b
	option renamekeyword:<bpl>=r5b
	option renamekeyword:<sil>=r6b
	option renamekeyword:<dil>=r7b
