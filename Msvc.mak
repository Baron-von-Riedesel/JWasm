
# this makefile (NMake) creates the JWasm Win32 binary with MS Visual C++.
#
# optionally, a DOS binary can be created. Then the HXDEV package is needed.
#
# to use jwlink instead of MS link, enter: "nmake -f msvc.mak mslink=0
# to additionally create a DOS binary, enter: "nmake -f msvc.mak dos=1 mslink=0"

name = jwasm
WIN=1

!ifndef DOS
DOS=0
!endif
!ifndef MSLINK
MSLINK=1
!endif

# directory paths to adjust
# VCDIR  - root directory for VC compiler, linker, include and lib files
# W32LIB - directory for Win32 import library files (kernel32.lib).
# HXDIR  - for DOS=1 only: root directory to search for stub LOADPEX.BIN,
#          libs DKRNL32S.LIB + IMPHLP.LIB and tool PATCHPE.EXE.

!ifndef VCDIR
VCDIR  = %VCToolsInstallDir%
!endif
VCBIN=$(VCDIR)\bin\Hostx86\x86

!ifndef W32LIB
W32LIB = %WindowsSdkDir%\Lib\%WindowsSdkVersion%\um\x86
W32LIBU = %WindowsSdkDir%\Lib\%WindowsSdkVersion%\ucrt\x86
!endif

!if $(DOS)
HXDIR  = \HX
!endif

!ifndef DEBUG
DEBUG=0
!endif

!ifndef OUTD
!if $(DEBUG)
OUTD=build\MSVCD
!else
OUTD=build\MSVCR
!endif
!endif

inc_dirs  = -Isrc\H -I"$(VCDIR)\include"

linker = link.exe
lib = lib.exe

!ifndef TRMEM
TRMEM=0
!endif

!if $(DEBUG)
#extra_c_flags = -Zi -Od -DDEBUG_OUT -FAa
extra_c_flags = -Z7 -Od -DDEBUG_OUT
!else
extra_c_flags = -O2 -Gs -DNDEBUG
!endif

!if $(TRMEM)
extra_c_flags = $(extra_c_flags) -DTRMEM -DFASTMEM=0
!endif

c_flags =-D__NT__ $(extra_c_flags)

# linker option /OPT:NOWIN98 is not accepted by all MS linkers
#LOPT = /NOLOGO /OPT:NOWIN98
LOPT = /NOLOGO
!if $(DEBUG)
LOPTD = /debug
!endif

lflagsd = $(LOPTD) /SUBSYSTEM:CONSOLE $(LOPT) /map:$^*.map /Libpath:$(HXDIR)\lib
lflagsw = $(LOPTD) /SUBSYSTEM:CONSOLE $(LOPT) /map:$^*.map

CC="$(VCBIN)\cl.exe" -c -nologo $(inc_dirs) $(c_flags)

{src}.c{$(OUTD)}.obj:
	@$(CC) -Fo$* $<

proj_obj = \
!include msmod.inc

!if $(TRMEM)
proj_obj = $(proj_obj) $(OUTD)/trmem.obj
!endif

!if $(WIN)
TARGET1=$(OUTD)\$(name).exe
!endif
!if $(DOS)
TARGET2=$(OUTD)\$(name)d.exe
!endif

ALL: build $(OUTD) $(TARGET1) $(TARGET2)

build:
	@mkdir build

$(OUTD):
	@mkdir $(OUTD)

$(OUTD)\$(name).exe : $(OUTD)/main.obj $(OUTD)/$(name).lib
!if $(MSLINK)
	@$(linker) $(lflagsw) $(OUTD)/main.obj $(OUTD)/$(name).lib /LibPath:"$(VCDIR)\lib\x86" /LibPath:"$(W32LIB)" /LibPath:"$(W32LIBU)" /OUT:$@
!else
	@jwlink @<<
format windows pe file $(OUTD)/main.obj name $@ 
lib $(OUTD)/$(name).lib libpath "$(VCDIR)\Lib\x86" libpath "$(W32LIB)" op start=_mainCRTStartup, norelocs, eliminate, map=$(OUTD)/$(name).map
#sort global op statics
disable 173
<<
!endif

$(OUTD)\$(name)d.exe : $(OUTD)/main.obj $(OUTD)/$(name).lib
!if $(MSLINK)
	@$(linker) @<<
$(lflagsd) /NODEFAULTLIB initw32.obj $(OUTD)/main.obj $(OUTD)/$(name).lib /LIBPATH:$(VCDIR)\Lib
libc.lib oldnames.lib /LIBPATH:$(HXDIR)\Lib imphlp.lib dkrnl32s.lib /STUB:$(HXDIR)\Bin\LOADPEX.BIN
/OUT:$@ /FIXED:NO
<<
	@$(HXDIR)\bin\patchpe $@
!else
	@jwlink @<<
format windows pe hx file $(HXDIR)/lib/initw32.obj, $(OUTD)/main.obj name $@ lib $(OUTD)/$(name).lib
libpath $(VCDIR)/Lib
libpath $(HXDIR)/Lib lib imphlp.lib, dkrnl32s.lib, hxemu387.lib reference EMUInit 
op start=_start, eliminate, map=$(OUTD)/$(name)d.map, stub=$(HXDIR)\Bin\LOADPEX.BIN
<<
!endif

$(OUTD)\$(name).lib : $(proj_obj)
	@$(lib) /nologo /out:$(OUTD)\$(name).lib @<<
$(proj_obj)
<<

$(OUTD)/msgtext.obj: src/msgtext.c src/H/msgdef.h src/H/globals.h
	@$(CC) -Fo$* src/msgtext.c

$(OUTD)/reswords.obj: src/reswords.c src/H/instruct.h src/H/special.h src/H/directve.h src/H/opndcls.h src/H/instravx.h
	@$(CC) -Fo$* src/reswords.c

######

clean:
	@erase $(OUTD)\*.exe
	@erase $(OUTD)\*.obj
	@erase $(OUTD)\*.map
