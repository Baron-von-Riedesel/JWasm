
;--- movd64 macro.
;--- allows to use opcodes A0-A3 in 64-bit ( direct memory addressing
;--- with a full 64-bit offset )

movd64 macro dst, src
    .errnz (type near) - 0FF08h, <movd64 can be used in 64-bit code only>
    ; the "nop" + "org" sequence enforces prologue generation.
    ; this is needed if the macro is the first line in a PROC.
    nop
    org $-1
if ( (.type dst ) and 10h )
    ifidni <dst>,<al>
      db 0A0h
    else
      ifidni <dst>,<ax>
        db 66h
      elseifidni <dst>,<rax>
        db 48h
      endif
      db 0A1h
    endif
    dq src
elseif ( (.type src ) and 10h )
    ifidni <src>,<al>
      db 0A2h
    else
      ifidni <src>,<ax>
        db 66h
      elseifidni <src>,<rax>
        db 48h
      endif
      db 0A3h
    endif
    dq dst
else
;--- no register involved
    .err <invalid instruction operands>
endif

endm

