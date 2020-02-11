
;--- this include file enables "frame pointer omission".
;--- for this to work it tries to track changes of ESP.
;--- it replaces some keywords with macros.
;--- since macros are usually case-dependent and keywords
;--- aren't, it will only work if the following keywords
;--- are coded in lower-case:
;---   push, pushw, pop
;---   invoke
;---   pushd, pushad, popad (32-bit only )
;---   add, sub
;---   endp

	pushcontext cpu
if (@Cpu and 7fh) lt 8
	.386	;make sure 32-bit is set for option stackbase
endif
if type near eq 0ff04h
	option stackbase:esp
else
	option stackbase:rsp
endif
	popcontext cpu
	option renamekeyword: <push>=@@push
	option renamekeyword: <pushw>=@@pushw
	option renamekeyword: <pop>=@@pop
	option renamekeyword: <invoke>=@@invoke

ifndef push

push macro x:vararg
	@@push x
  if (@ProcStatus and 7) eq 4  ;outside prologue/epilogue and fpo?
	if type (x)
		@StackBase = @StackBase + type (x)
	else
		@StackBase = @StackBase + @WordSize
	endif
  endif
endm

pushw macro x:vararg
	@@pushw x
  if (@ProcStatus and 7) eq 4 ;outside prologue/epilogue and fpo?
	@StackBase = @StackBase + 2
  endif
endm

pop macro x:vararg
  if (@ProcStatus and 7) eq 4 ;outside prologue/epilogue and fpo?
	if type (x)
		@StackBase = @StackBase - type (x)
	else
		@StackBase = @StackBase - @WordSize
	endif
    .errnz @StackBase lt 0, <@StackBase below 0!!>
  endif
	@@pop x
endm

invoke macro args:varargml
  if @ProcStatus and 4
	SavedBase = @StackBase
	@@invoke args
	@StackBase = SavedBase
  else
	@@invoke args
  endif
endm

endif

if type near ne 0ff08h

;--- this is 32-bit only
	option renamekeyword: <pushd>=@@pushd
	option renamekeyword: <pushad>=@@pushad
	option renamekeyword: <popad>=@@popad

ifndef pushd

pushd macro x:vararg
	@@pushd x
  if ( @ProcStatus and 7) eq 4 ;outside prologue/epilogue and fpo?
	@StackBase = @StackBase + 4
  endif
endm

pushad macro
	@@pushad
  if ( @ProcStatus and 7) eq 4 ;outside prologue/epilogue and fpo?
	@StackBase = @StackBase + 8 * @WordSize
  endif
endm

popad macro
	@@popad
  if ( @ProcStatus and 7) eq 4 ;outside prologue/epilogue and fpo?
	@StackBase = @StackBase - 8 * @WordSize
  endif
endm

endif

endif

if 1
	option renamekeyword: <sub>=@@sub
	option renamekeyword: <add>=@@add

ifndef sub

sub macro dst:req, opnd:req
	@@sub dst, opnd
  if (@ProcStatus and 7) eq 4 ;outside prologue/epilogue and fpo?
	ifidni <dst>,<esp>
	  if ( opattr opnd ) and 4 
		@StackBase = @StackBase + (opnd)
	  endif
	endif
	if type near eq 0ff08h
	  ifidni <dst>,<rsp>
		if ( opattr opnd ) and 4 
			@StackBase = @StackBase + (opnd)
		endif
	  endif
	endif
  endif
endm

add macro dst:req, opnd:req
	@@add dst, opnd
  if (@ProcStatus and 7) eq 4 ;outside prologue/epilogue and fpo?
	ifidni <dst>,<esp>
	  if ( opattr opnd ) and 4 
		@StackBase = @StackBase - (opnd)
	  endif
	endif
	if type near eq 0ff08h
	  ifidni <dst>,<rsp>
		if ( opattr opnd ) and 4 
			@StackBase = @StackBase - (opnd)
		endif
	  endif
	endif
  endif
endm

endif

endif

if 1
	option renamekeyword: <endp>=@@endp

ifndef endp

;--- check if @StackBase is zero at procedure's end.

endp macro name_:label
  if (@ProcStatus and 4) ;fpo on?
	.errnz @StackBase, <@StackBase not zero!!>
  endif
	name_ @@endp
endm

endif

endif
