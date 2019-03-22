
# this makefile creates a DOS 16-bit real-mode version of JWasm (JWASMR.EXE).
# Open Watcom v1.8-v1.9 may be used.

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
OUTD=OWDOS16D
!else
OUTD=OWDOS16R
!endif

# Linux is case-sensitive, so use lower case h for the Watcom includes.
inc_dirs  = -IH -I$(WATCOM)$(DS)h

# to track memory leaks, the Open Watcom TRMEM module can be included.
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
!if $(TRMEM)
extra_c_flags += -od -d2 -DDEBUG_OUT -DTRMEM
!else
extra_c_flags += -od -d2 -DDEBUG_OUT
!endif
!else
extra_c_flags += -obmilrs -s -DNDEBUG
!endif

!if $(DEBUG)
LOPTD = debug dwarf op symfile
!endif

lflagsd = $(LOPTD) sys dos op map=$^*, stack=0x8400

CC = wcc -q -0 -w3 -zc -ml -bc -bt=dos $(inc_dirs) $(extra_c_flags) -fo$@ -DFASTMEM=0 -DFASTPASS=0 -DCOFF_SUPPORT=0 -DELF_SUPPORT=0 -DAMD64_SUPPORT=0 -DSSSE3SUPP=0 -DSSE4SUPP=0 -DOWFC_SUPPORT=0 -DDLLIMPORT=0 -DAVXSUPP=0 -DPE_SUPPORT=0 -DVMXSUPP=0 -DSVMSUPP=0 -DCVOSUPP=0 -DCOMDATSUPP=0 -DSTACKBASESUPP=0 -zt=12000

.c{$(OUTD)}.obj:
    $(CC) $<

proj_obj = &
!include owmod.inc

!if $(TRMEM)
proj_obj += $(OUTD)$(DS)trmem.obj
!endif

ALL: $(OUTD) $(OUTD)$(DS)$(name)r.exe

$(OUTD):
    @if not exist $(OUTD) mkdir $(OUTD)

$(OUTD)$(DS)$(name)r.exe: $(OUTD)$(DS)$(name).lib $(OUTD)$(DS)main.obj
    @set LIB=$(WATCOM)$(DS)Lib286;$(WATCOM)$(DS)Lib286$(DS)DOS
    $(LINK) $(lflagsd) file $(OUTD)$(DS)main.obj name $@ lib $(OUTD)$(DS)$(name).lib

$(OUTD)$(DS)$(name).lib: $(proj_obj)
    @cd $(OUTD)
    wlib -q -n $(name).lib $(proj_obj:$(OUTD)$(DS)=+)
    @cd ..

$(OUTD)$(DS)msgtext.obj: msgtext.c H$(DS)msgdef.h H$(DS)globals.h
    @$(CC) msgtext.c

$(OUTD)$(DS)reswords.obj: reswords.c H$(DS)instruct.h H$(DS)special.h H$(DS)directve.h
    @$(CC) reswords.c

######

clean: .SYMBOLIC
    @if exist $(OUTD)$(DS)*.obj        -rm $(OUTD)$(DS)*.obj
    @if exist $(OUTD)$(DS)$(name)r.exe -rm $(OUTD)$(DS)$(name)r.exe
    @if exist $(OUTD)$(DS)$(name)r.map -rm $(OUTD)$(DS)$(name)r.map
    @if exist $(OUTD)$(DS)$(name).lib  -rm $(OUTD)$(DS)$(name).lib
