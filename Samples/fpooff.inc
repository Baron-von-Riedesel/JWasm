
;--- disable "frame pointer omission" (FPO)

if type near eq 0ff04h
	option stackbase:ebp
else
	option stackbase:rbp
endif
	option renamekeyword: <@@push>=push
	option renamekeyword: <@@pushw>=pushw
	option renamekeyword: <@@pop>=pop
	option renamekeyword: <@@invoke>=invoke

if type near ne 0ff08h
;--- this is 32-bit only
	option renamekeyword: <@@pushd>=pushd
	option renamekeyword: <@@pushad>=pushad
	option renamekeyword: <@@popad>=popad
endif

if 1
	option renamekeyword: <@@sub>=sub
	option renamekeyword: <@@add>=add
endif

if 1
	option renamekeyword: <@@endp>=endp
endif
