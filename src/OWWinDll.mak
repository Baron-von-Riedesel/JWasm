
# this makefile in OW WMake style creates JWASM.DLL (Win32)
# tools used:
# - Open Watcom v1.8/v1.9

name = JWasm

# Open Watcom root directory
!ifndef WATCOM
WATCOM = \Watcom
!endif

!ifndef DEBUG
DEBUG=0
!endif

!ifndef OUTD
!if $(DEBUG)
OUTD=OWWinDllD
!else
OUTD=OWWinDll
!endif
!endif

# calling convention for compiler: s=Stack, r=register
# r will create a slightly smaller binary
CCV=r

inc_dirs  = -IH -I$(WATCOM)\H

LINK = $(WATCOM)\binnt\wlink.exe

#cflags stuff
#########
extra_c_flags =
!if $(DEBUG)
extra_c_flags += -od -d2 -w3 -DDEBUG_OUT
!else
extra_c_flags += -ox -s -DNDEBUG
!endif

#########

LOPT = op quiet
!if $(DEBUG)
# for OW v1.8, the debug version needs user32.lib to resolve CharUpperA()
# without it, WD(W) will crash immediately.
LOPTD = debug dwarf op symfile lib user32.lib
!endif

lflagsw = $(LOPTD) format windows pe dll $(LOPT) op map=$^*, offset=0x5000000 export AssembleModule='_AssembleModule@4', ParseCmdline='_ParseCmdline@8', CmdlineFini='_CmdlineFini@0'

CC=$(WATCOM)\binnt\wcc386 -q -3$(CCV) -bd -zc -bt=nt $(inc_dirs) $(extra_c_flags) -fo$@

.c{$(OUTD)}.obj:
	$(CC) $<

proj_obj = &
!include owmod.inc

ALL: $(OUTD) $(OUTD)/$(name).dll

$(OUTD):
	@if not exist $(OUTD) mkdir $(OUTD)

$(OUTD)/$(name).dll: $(proj_obj)
	$(LINK) @<<
$(lflagsw) file { $(proj_obj) } name $@
Libpath $(WATCOM)\lib386 
Libpath $(WATCOM)\lib386\nt
Library kernel32, user32
<<

$(OUTD)/msgtext.obj: msgtext.c H/msgdef.h H/usage.h H/globals.h
	$(CC) msgtext.c

$(OUTD)/reswords.obj: reswords.c H/instruct.h H/special.h H/directve.h
	$(CC) reswords.c

######

clean:
	@erase $(OUTD)\*.dll
	@erase $(OUTD)\*.obj
	@erase $(OUTD)\*.map
