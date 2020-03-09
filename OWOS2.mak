
# this makefile creates the 32bit OS/2 binary of JWasm.
# tools used:
# - Open Watcom v1.8/v1.9

# Note that this makefile assumes that the OW environment is
# set - the OW tools are to be found in the PATH and the INCLUDE
# environment variable is set correctly.

# 2011-07-09 -- rousseau at ecomstation.com -- fixed some stuff.
# - Removed a trailing space after the '&' in the object-list on the 
#   line with '$(OUTD)/omffixup.obj' that breaks wmake v1.9.
# - Added '.SYMBOLIC' to 'clean:' to supress dependency checking.
# - Added check for existence of files to 'clean:' to suppress 
#   abort when files are not found.
# - Replaced 'erase' with 'del' in 'clean:' as this is the more common name.


name = JWasm

!ifndef DEBUG
DEBUG=0
!endif

!if $(DEBUG)
OUTD=Build\OWOS2D
!else
OUTD=Build\OWOS2R
!endif

# calling convention for compiler: s=Stack, r=register
# r will create a slightly smaller binary
CCV=r

inc_dirs  = -Isrc\H

LINK = wlink.exe

#cflags stuff
#########
extra_c_flags =
!if $(DEBUG)
extra_c_flags += -od -d2 -DDEBUG_OUT
!else
extra_c_flags += -obmilrt -s -DNDEBUG
!endif

#########

LOPT = op quiet
!if $(DEBUG)
LOPTD = debug dwarf op symfile
!endif

lflagso = $(LOPTD) system os2v2 $(LOPT) op map=$^*

CC=wcc386 -q -3$(CCV) -bc -bt=os2 $(inc_dirs) $(extra_c_flags) -fo$@

{src}.c{$(OUTD)}.obj:
   $(CC) $<

proj_obj = &
!include owmod.inc

TARGET1=$(OUTD)/$(name).exe

ALL: $(OUTD) $(TARGET1)

$(OUTD):
	@if not exist $(OUTD) mkdir $(OUTD)

$(TARGET1): $(OUTD)/main.obj $(proj_obj)
	$(LINK) @<<
$(lflagso) file { $(OUTD)/main.obj $(proj_obj) } name $@ op stack=0x20000
<<

$(OUTD)\msgtext.obj: src\msgtext.c src\H\msgdef.h src\H\globals.h
	$(CC) src\msgtext.c

$(OUTD)\reswords.obj: src\reswords.c src\H\instruct.h src\H\special.h src\H\directve.h
	$(CC) src\reswords.c

######

clean: .SYMBOLIC
	@if exist $(OUTD)\*.exe del $(OUTD)\*.exe
	@if exist $(OUTD)\*.obj del $(OUTD)\*.obj
	@if exist $(OUTD)\*.map del $(OUTD)\*.map
