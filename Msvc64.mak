
# this makefile (NMake) creates the JWasm Win64 binary with MS Visual Studio

name = jwasm

# directory paths to adjust
# VCDIR  - root directory for VC include and lib files.
# W64LIB - directory for Win64 import library files (kernel32.lib, ...).


!ifndef VCDIR
VCDIR  = %VCToolsInstallDir%
!endif
VCBIN=$(VCDIR)\bin\Hostx64\x64

!ifndef W64LIB
W64LIB = %WindowsSdkDir%\Lib\%WindowsSdkVersion%\um\x64
W64LIBU = %WindowsSdkDir%\Lib\%WindowsSdkVersion%\ucrt\x64
!endif

# use the MS linker or jwlink
!ifndef MSLINK
MSLINK=1
!endif

!ifndef DEBUG
DEBUG=0
!endif

!ifndef OUTD
!if $(DEBUG)
OUTD=build\MSVC64D
!else
OUTD=build\MSVC64R
!endif
!endif

inc_dirs  = -Isrc/H -I"$(VCDIR)\include"

linker = link.exe
lib = lib.exe

!if $(DEBUG)
extra_c_flags = -ZI -Od -DDEBUG_OUT -FAa
!else
extra_c_flags = -O2 -Ox -GS- -DNDEBUG
#extra_c_flags = -Ox -DNDEBUG
!endif

c_flags =-D__NT__ $(extra_c_flags)

#lflags stuff
#########
LOPT = /NOLOGO
!if $(DEBUG)
LOPTD = /debug
!endif

lflagsw = $(LOPTD) /SUBSYSTEM:CONSOLE $(LOPT) /map:$^*.map

CC="$(VCBIN)\cl.exe" -c -nologo $(inc_dirs) $(c_flags)

{src}.c{$(OUTD)}.obj:
	@$(CC) -Fo$* $<

proj_obj = \
!include msmod.inc

ALL: build $(OUTD) $(OUTD)\$(name).exe

build:
	@mkdir build

$(OUTD):
	@mkdir $(OUTD)

$(OUTD)\$(name).exe : $(OUTD)/main.obj $(OUTD)/$(name).lib
!if $(MSLINK)
	@$(linker) $(lflagsw) $(OUTD)/main.obj $(OUTD)/$(name).lib /LIBPATH:"$(VCDIR)/lib/x64" /LIBPATH:"$(W64LIB)" /LIBPATH:"$(W64LIBU)" /OUT:$@
!else
	@jwlink.exe format windows pe file $(OUTD)/main.obj name $@ lib $(OUTD)/$(name).lib libpath "$(VCDIR)/Lib/x64" lib "$(W64LIB)/kernel32.lib" op start=mainCRTStartup, norelocs, eliminate, map=$(OUTD)/$(name).map
!endif

$(OUTD)\$(name).lib : $(proj_obj)
	@$(lib) /nologo /out:$(OUTD)\$(name).lib @<<
$(proj_obj)
<<

$(OUTD)/msgtext.obj: src/msgtext.c src/H/msgdef.h src/H/globals.h
	@$(CC) -Fo$* src/msgtext.c

$(OUTD)/reswords.obj: src/reswords.c src/H/instruct.h src/H/special.h src/H/directve.h
	@$(CC) -Fo$* src/reswords.c

######

clean:
	@erase $(OUTD)\*.exe
	@erase $(OUTD)\*.obj
	@erase $(OUTD)\*.map
