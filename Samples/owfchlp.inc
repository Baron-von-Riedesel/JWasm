
;--- helper macros for Open Watcom register calling convention

;--- @StoreArg: copies a parameter hold in a pair/quadruplet of
;---            registers to memory.
;---   dst: destination memory location
;---   src: register pair/quadruplet

;--- defines global equates ?Reg1End, ?Reg2End, ?Reg3End

@StoreArg macro dst, src
local displ, typ
?Reg1End InStr src,<::>
if ?Reg1End
  ?Reg2End InStr ?Reg1End+2, src, <::>
  if ?Reg2End
	?Reg3End InStr ?Reg2End+2, src, <::>
  else
	?Reg3End = 0
  endif
  if @WordSize eq 4
	typ equ <dword>
  else
	typ equ <word>
  endif
  if ?Reg3End
	mov typ ptr dst, @SubStr( %src, ?Reg3End+2 )
	mov typ ptr dst+@WordSize, @SubStr( %src, ?Reg2End+2, ?Reg3End-(?Reg2End+2) )
	displ = 2*@WordSize
  else
	displ = 0
  endif
  if ?Reg2End
	mov typ ptr dst+displ, @SubStr( %src, ?Reg1End+2, ?Reg2End-(?Reg1End+2) )
  else
	mov typ ptr dst+displ, @SubStr( %src, ?Reg1End+2 )
  endif
	mov typ ptr dst+displ+@WordSize, @SubStr( %src, 1, ?Reg1End-1 )
else
	mov dst, src
endif
	endm

