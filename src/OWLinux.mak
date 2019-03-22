
# this makefile (WMake) creates the Linux binary of JWasm (jwasm)
# Open Watcom v1.8-v1.9 may be used.

# Note that this makefile assumes that the OW environment is
# set - the OW tools are to be found in the PATH and the INCLUDE
# environment variable is set correctly.

name = jwasm

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
OUTD=OWLinuxD
!else
OUTD=OWLinuxR
!endif

# calling convention for compiler: s=Stack, r=Register
CCV=r

# Linux is case-sensitive, so use lower case h for the Watcom includes.
inc_dirs  = -IH -I$(WATCOM)$(DS)lh

# to track memory leaks, the Open Watcom TRMEM module can be included
# it's useful only if FASTMEM=0 is set, though, otherwise most allocs
# won't use the C heap.
!ifndef TRMEM
TRMEM=0
!endif

!ifdef JWLINK
LINK = jwlink.exe
c_flags = -zc
!else
LINK = wlink
c_flags = -zc
!endif

#cflags stuff
#########
extra_c_flags =
!if $(DEBUG)
extra_c_flags += -od -d2 -DDEBUG_OUT
!else
extra_c_flags += -ot -s -DNDEBUG
!endif

!if $(TRMEM)
extra_c_flags += -DTRMEM -DFASTMEM=0
!endif

!if $(DEBUG)
LOPTD = debug dwarf op symfile
!endif

CC = wcc386 -q -3$(CCV) $(c_flags) -bc -bt=linux $(inc_dirs) $(extra_c_flags) -fo$@

.c{$(OUTD)}.obj:
    $(CC) $<

proj_obj = &
!include owmod.inc

!if $(TRMEM)
proj_obj += $(OUTD)$(DS)trmem.obj
!endif

ALL: $(OUTD) $(OUTD)$(DS)$(name)

$(OUTD):
    @if not exist $(OUTD) mkdir $(OUTD)

$(OUTD)$(DS)$(name) : $(OUTD)$(DS)main.obj $(proj_obj)
    $(LINK) @<<
format elf runtime linux
!if $(DEBUG)
$(LOPTD)
!endif
libpath $(WATCOM)$(DS)lib386
libpath $(WATCOM)$(DS)lib386$(DS)linux
op map=$^*, norelocs, quiet, stack=0x20000
file { $(OUTD)/main.obj $(proj_obj) }
name $@
<<

$(OUTD)$(DS)msgtext.obj: msgtext.c H$(DS)msgdef.h H$(DS)globals.h
    $(CC) msgtext.c

$(OUTD)$(DS)reswords.obj: reswords.c H$(DS)instruct.h H$(DS)special.h H$(DS)directve.h
    $(CC) reswords.c

######
# Under non-Linux, the link format "elf" forces a file name extension of .elf.
# While this can be prevented by the NOEXTENSION link option, the resulting
# file without extension will not be detected by the "exist" below, so a "clean"
# leaves the file in place. Under Linux this detection works properly.
# Watcom ought to have a internal (=platform independent) command to detect
# the presence of such a file. E.g. %exist alllowing wildcards.

clean: .SYMBOLIC
    @if exist $(OUTD)$(DS)*     -rm $(OUTD)$(DS)*
    @if exist $(OUTD)$(DS)*.elf -rm $(OUTD)$(DS)*.elf
    @if exist $(OUTD)$(DS)*.obj -rm $(OUTD)$(DS)*.obj
    @if exist $(OUTD)$(DS)*.map -rm $(OUTD)$(DS)*.map
