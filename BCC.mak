
# this makefile (NMake) creates the JWasm Win32 binary with Borland Commandline Tools.

name = jwasm

!ifndef DEBUG
DEBUG=0
!endif

!if $(DEBUG)
OUTD=build\BCC32D
!else
OUTD=build\BCC32R
!endif

inc_dirs  = /Isrc\H

!if $(DEBUG)
extra_c_flags = -v -y -DDEBUG_OUT
!else
extra_c_flags = -O2 /DNDEBUG
!endif

c_flags =-q -WC -K -D__NT__ -w-8012 -w-8057 -w-8060 $(extra_c_flags)

CC = bcc32.exe -c $(inc_dirs) $(c_flags)
LINK = ilink32.exe -s -Tpe -ap -Gn -c -L$(BCDIR)\Lib 

{src}.c{$(OUTD)}.obj:
	@$(CC) -o$* $<

proj_obj = \
!include msmod.inc

TARGET1=$(OUTD)\$(name).exe 

ALL: $(OUTD) $(TARGET1)

$(OUTD):
	@mkdir $(OUTD)

$(OUTD)\$(name).exe : $(OUTD)/main.obj $(OUTD)/$(name).lib
	@cd $(OUTD)
	$(LINK) c0x32.obj +main.obj, $(name).exe, $(name).map, $(name).lib import32.lib cw32.lib
	@cd ..

$(OUTD)\$(name).lib: $(proj_obj)
	@cd $(OUTD)
	@erase $(name).lib
!if $(DEBUG)
	tlib $(name).lib /C $(proj_obj:BCC32D/=+)
!else
	tlib $(name).lib /C $(proj_obj:BCC32R/=+)
!endif
	@cd ..

$(OUTD)/msgtext.obj: src/msgtext.c src/H/msgdef.h
	@$(CC) /o$* src/msgtext.c

$(OUTD)/reswords.obj: src/reswords.c src/H/instruct.h src/H/special.h src/H/directve.h
	@$(CC) /o$* src/reswords.c

######

clean:
	@erase $(OUTD)\*.exe
	@erase $(OUTD)\*.obj
	@erase $(OUTD)\*.map
