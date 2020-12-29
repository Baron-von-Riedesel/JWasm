
# this makefile (NMake) creates the JWasm Win32 dll with MS Visual C++.
# it has been tested with:
# - VC++ Toolkit 2003 ( = VC++ 7.1 )

name = jwasm


!ifndef DEBUG
DEBUG=0
!endif

!ifndef OUTD
!if $(DEBUG)
OUTD=build\MsvcDllD
!else
OUTD=build\MsvcDllR
!endif
!endif

inc_dirs  = -Isrc\H

linker = link.exe
lib = lib.exe

!if $(DEBUG)
extra_c_flags = -Zd -Od -DDEBUG_OUT
!else
extra_c_flags = -O2 -Gs -DNDEBUG
#extra_c_flags = -Ox -DNDEBUG
!endif

c_flags =-D__NT__ -D__SW_BD $(extra_c_flags) $(c_flags64)

LOPT = /NOLOGO
!if $(DEBUG)
LOPTD = /debug
!endif

lflagsw = $(LOPTD) $(LOPT) /map:$^*.map /OPT:NOWIN98

CC=@cl.exe -c -nologo $(inc_dirs) $(c_flags)

{src}.c{$(OUTD)}.obj:
	$(CC) -Fo$* $<

proj_obj = \
!include msmod.inc

ALL: $(OUTD) $(OUTD)\$(name).dll

$(OUTD):
	@mkdir $(OUTD)

$(OUTD)\$(name).dll : $(OUTD)/$(name)s.lib
	$(linker) @<<
$(lflagsw) $(OUTD)/$(name)s.lib
/LIBPATH:"$(VCDIR)\Lib" /DLL "$(W32LIB)/kernel32.lib" /OUT:$@
/EXPORT:AssembleModule /EXPORT:ParseCmdline /EXPORT:CmdlineFini
<<

$(OUTD)\$(name)s.lib : $(proj_obj)
	@$(lib) /out:$(OUTD)\$(name)s.lib $(proj_obj)

$(OUTD)/msgtext.obj: src/msgtext.c src/H/msgdef.h src/H/globals.h
	$(CC) -Fo$* src/msgtext.c

$(OUTD)/reswords.obj: src/reswords.c src/H/instruct.h src/H/special.h src/H/directve.h
	$(CC) -Fo$* src/reswords.c

######

clean:
	@erase $(OUTD)\*.dll
	@erase $(OUTD)\*.obj
	@erase $(OUTD)\*.map
