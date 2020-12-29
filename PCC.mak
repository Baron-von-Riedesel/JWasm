
# This makefile (NMake) creates the JWasm Win32 binary with PCC.

name = jwasm

!ifndef PCCROOT
PCCROOT  = \pcc
!endif
!ifndef DEBUG
DEBUG=0
!endif

!if $(DEBUG)
OUTD=build\PCCD
!else
OUTD=build\PCCR
!endif

inc_dirs  = -Isrc\H -I"$(PCCROOT)\include"

!if $(DEBUG)
extra_c_flags = -g -DDEBUG_OUT
!else
extra_c_flags = -DNDEBUG
!endif

CC=$(PCCROOT)\bin\pcc.exe $(inc_dirs) -D__NT__ $(extra_c_flags)

ALL: $(OUTD) $(OUTD)\$(name).exe

$(OUTD):
	@mkdir $(OUTD)

$(OUTD)\$(name).exe: src\*.c
	set PCCDIR=$(PCCROOT)
	$(CC) -o $(OUTD)\$(name).exe src\*.c

clean:
	@erase $(OUTD)\$(name).exe
