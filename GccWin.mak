
# This makefile creates the JWasm Win32 binary with either MinGW or Cygwin.
#  'mingw32-make -f GccWin.mak'    will use MinGW (no MSys needed!).
#  'make -f GccWin.mak CYGWIN=1'   will use Cygwin.
#
# As for MinGW: you don't need MSYS - just run mingw32-make.exe. However,
# the MinGW 'bin' subdirectory has to be in your path.

name = jwasm

ifndef CYGWIN
CYGWIN=0
endif

ifndef DEBUG
DEBUG=0
endif

inc_dirs  = -Isrc/H

#cflags stuff

ifeq ($(DEBUG),1)

extra_c_flags = -DDEBUG_OUT -g
lflagsd=
ifeq ($(CYGWIN),1)
OUTD=build/CygwinD
else
OUTD=build/MinGWD
endif

else

extra_c_flags = -DNDEBUG -O2 -fomit-frame-pointer
lflagsd=-s
ifeq ($(CYGWIN),1)
OUTD=build/CygwinR
else
OUTD=build/MinGWR
endif

endif

c_flags = -D__NT__ $(extra_c_flags)

CC=gcc.exe -c $(inc_dirs) $(c_flags)
LINK=gcc.exe

$(OUTD)/%.o: src/%.c
	$(CC) -o $(OUTD)/$*.o $<

include gccmod.inc

TARGET1=$(OUTD)/$(name).exe

ALL: $(OUTD) $(TARGET1)

$(OUTD):
	mkdir $(OUTD)

$(OUTD)/$(name).exe : $(OUTD)/main.o $(proj_obj)
	$(LINK) $(OUTD)/main.o $(proj_obj) $(lflagsd) -o $(OUTD)/$(name).exe -Wl,-Map,$(OUTD)/$(name).map

$(OUTD)/msgtext.o: src/msgtext.c src/H/msgdef.h
	$(CC) -o $(OUTD)/msgtext.o src/msgtext.c

$(OUTD)/reswords.o: src/reswords.c src/H/instruct.h src/H/special.h src/H/directve.h
	$(CC) -o $(OUTD)/reswords.o src/reswords.c

######

clean:
	@rm $(OUTD)/*.exe
	@rm $(OUTD)/*.o
	@rm $(OUTD)/*.map
