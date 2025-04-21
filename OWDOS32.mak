
# This makefile in OW WMake style creates JWasmd.EXE (DOS32).
# unlike the DOS version created with OWWin32.mak, which uses
# a statically linked Win32 emulation layer, this creates
# a DOS version that uses the native OW DOS32 support. Besides
# a noticeable size reduction there isn't much gained, though.
# Tools used:
# - Open Watcom v2.0
# - jwlink ( OW's wlink might also be used )
# - HXDev ( for modules cstrtdhr.obj and loadpero.bin )
#
# OW's DOS32 support has a very slow memory management.
# Fortunately this doesn't matter too much for JWasm, since
# JWasm usually allocates memory in 512 kB chunks and does
# further management itself. A measureable speed reduction
# will still exist, though.
#
# LibFile clock.obj is a replacement for the std OW clock();
# it has a resolution of 1 ms instead of 55 ms.
#
# "WMake debug=1" - creates a debug version.
#
# Note that OW 1.9 has severe bugs concerning its LFN support!

name = JWasm

# Open Watcom root directory
!ifndef WATCOM
WATCOM = \ow20
!endif

NOGBL = 1

!ifndef DEBUG
DEBUG=0
!endif
!ifndef DJGPP
DJGPP=1
!endif

# to track memory leaks, the Open Watcom TRMEM module can be included.
# it's useful only if FASTMEM=0 is set, though, otherwise most allocs 
# won't use the C heap.
!ifndef TRMEM
TRMEM=0
!endif

!ifndef OUTD
BOUT=Build
!if $(DEBUG)
OUTD=$(BOUT)\OWDOS32D
!else
OUTD=$(BOUT)\OWDOS32R
!endif
!endif

inc_dirs  = -Isrc\H -I$(WATCOM)\H
c_flags = -q -bc -bt=dos -3r -fpi87 -wcd=115 -wcd=303 -D__WATCOM_LFN__

# OW's wlink could be used as well, but jwlink can better handle CONST segments in PE file format;
# also, it understands "format windows pe hx" ( which simply produces a 'PX' instead of 'PE' binary )
LINK = jwlink.exe

#cflags stuff
#########
extra_c_flags =
!if $(DEBUG)
extra_c_flags += -od -d2 -w3 -hc -DDEBUG_OUT
!else
#extra_c_flags += -obmilrt -s -DNDEBUG
extra_c_flags += -oxa -s -DNDEBUG
!endif

!if $(TRMEM)
extra_c_flags += -of -DTRMEM -DFASTMEM=0
!endif
!if !$(DJGPP)
extra_c_flags += -DDJGPP_SUPPORT=0
!endif
#########

!if $(DEBUG)
LOPTD = debug c op cvp, symfile
!else
LOPTD =
!endif

CC=$(WATCOM)\binnt\wcc386 $(c_flags) $(inc_dirs) $(extra_c_flags) -fo$@
LIB=$(WATCOM)\binnt\wlib

{src}.c{$(OUTD)}.obj:
	$(CC) $<

proj_obj = &
!include owmod.inc

!if $(TRMEM)
proj_obj += $(OUTD)/trmem.obj
!endif

TARGET1=$(OUTD)/$(name)d.exe

ALL: $(BOUT) $(OUTD) $(TARGET1)

!ifdef BOUT
$(BOUT):
	@mkdir $(BOUT)
!endif

$(OUTD):
	@mkdir $(OUTD)

$(OUTD)/$(name)d.exe: $(OUTD)/main.obj $(proj_obj)
	$(LINK) @<<
$(LOPTD)
format windows pe hx runtime console
file { $(OUTD)/main.obj $(proj_obj) }
name $@
Libpath $(WATCOM)\lib386\dos;$(WATCOM)\lib386
Libfile cstrtdhr.obj, inirmlfn.obj, clock.obj
op quiet, stack=0x10000, heapsize=0x1000, map=$^*, stub=loadpero.bin
disable 171
!ifndef NOGBL
sort global
!endif
op statics
!ifndef WLINK
segment CONST readonly
segment CONST2 readonly
!endif
<<

$(OUTD)/msgtext.obj: src/msgtext.c src/H/msgdef.h src/H/globals.h
	$(CC) src\msgtext.c

$(OUTD)/reswords.obj: src/reswords.c src/H/instruct.h src/H/special.h src/H/directve.h src/H/opndcls.h src/H/instravx.h
	$(CC) src\reswords.c

######

clean: .SYMBOLIC
	@if exist $(OUTD)\$(name).exe erase $(OUTD)\$(name).exe
	@if exist $(OUTD)\$(name).map erase $(OUTD)\$(name).map
	@if exist $(OUTD)\*.obj erase $(OUTD)\*.obj
