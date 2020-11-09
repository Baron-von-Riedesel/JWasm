
# this makefile (NMake) creates the JWasm Win32 binary with Orange C.

name = jwasm

# directory paths to adjust
# CCDIR  - root directory for compiler, linker, include and lib files
!ifndef CCDIR
CCDIR  = \orangec
!endif
!ifndef DEBUG
DEBUG=0
!endif

!ifndef OUTD
!if $(DEBUG)
OUTD=Build\OCD
!else
OUTD=Build\OCR
!endif
!endif

inc_dirs  = -Isrc\H -I"$(CCDIR)\include"

linker = $(CCDIR)\bin\olink.exe

!if $(DEBUG)
extra_c_flags = -DDEBUG_OUT
!else
extra_c_flags = -DNDEBUG
!endif

c_flags =-D__NT__ $(extra_c_flags)

#lflags stuff
#########
LOPT =
!if $(DEBUG)
LOPTD =
!endif

lflagsw = $(LOPTD) $(LOPT)

CC=$(CCDIR)\bin\occ.exe /c /C+F -D__OCC__ $(inc_dirs) $(c_flags)

{src}.c{$(OUTD)}.o:
	@set ORANGEC=$(CCDIR)
	@set PATH=$(CCDIR)\bin;%PATH%
	@$(CC) -o$* $<

!include gccmod.inc

ALL: $(OUTD) $(OUTD)\$(name).exe

$(OUTD):
	@mkdir $(OUTD)

$(OUTD)\$(name).exe : $(OUTD)/main.o $(proj_obj)
	@set ORANGEC=$(CCDIR)
	@set PATH=$(CCDIR)\bin;%PATH%
	$(linker) /c /T:CON32 /m /o$(OUTD)\$(name) @<<
$(lflagsw) /L$(CCDIR)\Lib $(OUTD)\main.o $(proj_obj:/=\) c0xpe.o "clwin.l" "climp.l"
<<

$(OUTD)/msgtext.o: src/msgtext.c src/H/msgdef.h src/H/globals.h
	@set ORANGEC=$(CCDIR)
	@set PATH=$(CCDIR)\bin;%PATH%
	@$(CC) -o$* src/msgtext.c

$(OUTD)/reswords.o: src/reswords.c src/H/instruct.h src/H/special.h src/H/directve.h
	@set ORANGEC=$(CCDIR)
	@set PATH=$(CCDIR)\bin;%PATH%
	@$(CC) -o$* src/reswords.c

######

clean:
	@erase $(OUTD)\*.exe
	@erase $(OUTD)\*.o
	@erase $(OUTD)\*.map
