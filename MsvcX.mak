
# building JWasm with MS Visual C++ Toolkit
# and the import libraries from WinInc,
# so no need to download huge Windows SDKs 

name   = jwasm
VCDIR  = \msvc71
W32LIB = \WinInc\Lib
LIBC   = \msvc71\lib\libc.lib

BOUT=build
OUTD=$(BOUT)\Msvc71
inc_dirs  = -Isrc\H -I"$(VCDIR)\include"
linker = $(VCDIR)\Bin\link.exe
lib = $(VCDIR)\Bin\lib.exe
extra_c_flags = -Ox -Gs -DNDEBUG
c_flags =-D__NT__ $(extra_c_flags)
LOPT = /NOLOGO /OPT:NOWIN98
lflagsw = $(LOPTD) /SUBSYSTEM:CONSOLE $(LOPT) /map:$^*.map
TARGET1=$(OUTD)\$(name).exe

CC=$(VCDIR)\bin\cl.exe -c -nologo $(inc_dirs) $(c_flags)

{src}.c{$(OUTD)}.obj:
	@$(CC) -Fo$* $<

proj_obj = \
!include msmod.inc

ALL: $(BOUT) $(OUTD) $(TARGET1)

$(BOUT):
	@mkdir $(BOUT)

$(OUTD):
	@mkdir $(OUTD)

$(OUTD)\$(name).exe : $(OUTD)/main.obj $(OUTD)/$(name).lib
	@$(linker) @<<
$(lflagsw) $(OUTD)/main.obj $(OUTD)/$(name).lib
/nodefaultlib:libc /nodefaultlib:oldnames "$(LIBC)" "$(W32LIB)/kernel32.lib" /OUT:$@
<<

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
