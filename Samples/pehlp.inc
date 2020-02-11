
;--- helper macros for PE output format

;--- @PESetHeader: set values in IMAGE_NT_HEADER
;---
;--- offset type field
;----------------------------------
;---   30h  dq   imagebase (64-bit)
;---   34h  dd   imagebase (32-bit)
;---   5Ch  dw   subsystem

@PESetHeader macro ofs, type_, value
.hdr$2 segment DWORD FLAT public 'HDR'
	org ofs	;position to member offset
	type_ value
.hdr$2 ends
endm

