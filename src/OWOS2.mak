
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
# - Added check for existence of files to 'clean:' to supress
#   abort when files are not found.
# - Replaced 'erase' with 'del' in 'clean:' as this is the more common name.

name = JWasm

# Detect which platform we're _running_ on, to use proper
# directory separator.

!ifdef __LINUX__
DS=/
!else
DS=\
!endif

# When building _on_ Linux, use the script in the Watcom root
# directory to set up the proper environment variables. Call
# this script as ¨. owsetevn.sh¨ The WATCOM directory
# declarations should not end with a / or \.

!ifndef %WATCOM
WATCOM=$(DS)Watcom
!else
WATCOM=$(%WATCOM)
!endif

!ifndef DEBUG
DEBUG=0
!endif

!if $(DEBUG)
OUTD=OWOS2D
!else
OUTD=OWOS2R
!endif

# calling convention for compiler: s=Stack, r=register
# r will create a slightly smaller binary
CCV=r

# Linux is case-sensitive, so use lower case h for the Watcom includes.
inc_dirs  = -IH -I$(WATCOM)$(DS)h -I$(WATCOM)$(DS)h$(DS)os2

LINK = wlink

#cflags stuff
#########
extra_c_flags =
!if $(DEBUG)
extra_c_flags += -od -d2 -DDEBUG_OUT
!else
extra_c_flags += -obmilrt -s -DNDEBUG
!endif

#########

#LOPT = op quiet
!if $(DEBUG)
LOPTD = debug dwarf op symfile
!endif

lflagso = $(LOPTD) system os2v2 $(LOPT) op map=$^*

CC=wcc386 -q -3$(CCV) -bc -bt=os2 $(inc_dirs) $(extra_c_flags) -fo$@

.c{$(OUTD)}.obj:
   $(CC) $<

proj_obj = &
!include owmod.inc

TARGET1=$(OUTD)$(DS)$(name).exe

ALL: $(OUTD) $(TARGET1)

$(OUTD):
    @if not exist $(OUTD) mkdir $(OUTD)

$(TARGET1): $(OUTD)$(DS)main.obj $(proj_obj)
    $(LINK) @<<
$(lflagso) file { $(OUTD)$(DS)main.obj $(proj_obj) } name $@ op stack=0x20000
<<

$(OUTD)$(DS)msgtext.obj: msgtext.c H$(DS)msgdef.h H$(DS)globals.h
    $(CC) msgtext.c

$(OUTD)$(DS)reswords.obj: reswords.c H$(DS)instruct.h H$(DS)special.h H$(DS)directve.h
    $(CC) reswords.c

######

clean: .SYMBOLIC
    @if exist $(OUTD)$(DS)*.exe -rm $(OUTD)$(DS)*.exe
    @if exist $(OUTD)$(DS)*.obj -rm $(OUTD)$(DS)*.obj
    @if exist $(OUTD)$(DS)*.map -rm $(OUTD)$(DS)*.map
