
# this makefile (NMake) creates the JWasm Win32 binary with Borland Commandline Tools.

name = jwasm

!ifndef BCDIR
BCDIR = \bcc55
!endif
!ifndef DEBUG
DEBUG=0
!endif

!if $(DEBUG)
OUTD=BCC32D
!else
OUTD=BCC32R
!endif

inc_dirs  = /IH /I"$(BCDIR)\include"

!if $(DEBUG)
extra_c_flags = -v -y -DDEBUG_OUT
!else
extra_c_flags = -O2 /DNDEBUG
!endif

c_flags =-q -WC -K -D__NT__ -w-8012 -w-8057 -w-8060 $(extra_c_flags)

CC = $(BCDIR)\bin\bcc32.exe -c $(inc_dirs) $(c_flags)
LINK = $(BCDIR)\Bin\ilink32.exe -s -Tpe -ap -Gn -c -L$(BCDIR)\Lib 

.c{$(OUTD)}.obj:
	@$(CC) -o$* $<

proj_obj = \
!include msmod.inc

TARGET1=$(OUTD)\$(name).exe 

ALL: $(OUTD) $(TARGET1)

$(OUTD):
	@mkdir $(OUTD)

$(OUTD)\$(name).exe : $(OUTD)/main.obj $(OUTD)/$(name).lib
	@cd $(OUTD)
	$(LINK) $(BCDIR)\Lib\c0x32.obj +main.obj, $(name).exe, $(name).map, $(name).lib import32.lib cw32.lib
	@cd ..

$(OUTD)/$(name).lib: $(proj_obj)
	@cd $(OUTD)
	@erase $(name).lib
!if $(DEBUG)
	$(BCDIR)\bin\tlib $(name).lib /C $(proj_obj:BCC32D/=+)
!else
	$(BCDIR)\bin\tlib $(name).lib /C $(proj_obj:BCC32R/=+)
!endif
	@cd ..

$(OUTD)/msgtext.obj: msgtext.c H/msgdef.h
	@$(CC) /o$* msgtext.c

$(OUTD)/reswords.obj: reswords.c H/instruct.h H/special.h H/directve.h
	@$(CC) /o$* reswords.c

######

clean:
	@erase $(OUTD)\*.exe
	@erase $(OUTD)\*.obj
	@erase $(OUTD)\*.map
