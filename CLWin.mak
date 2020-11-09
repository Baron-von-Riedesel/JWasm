
# This makefile creates the JWasm Win32 binary with 
# the CLang driver on either MinGW or Cygwin.
#  'make -f CLang.mak'            will use MinGW.
#  'make -f CLang.mak CYGWIN=1'   will use Cygwin.

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
ifeq ($(CYGWIN),1)
OUTD=CygwinD
else
OUTD=CLangD
endif
else
extra_c_flags = -DNDEBUG -O2
ifeq ($(CYGWIN),1)
OUTD=CygwinR
else
OUTD=CLangR
endif
endif

c_flags = -D__NT__ $(extra_c_flags)

CC=clang.exe -c $(inc_dirs) $(c_flags)

$(OUTD)/%.o: src/%.c
	$(CC) -o $(OUTD)/$*.o $<

include gccmod.inc

TARGET1=$(OUTD)/$(name).exe

ALL: $(OUTD) $(TARGET1)

$(OUTD):
	mkdir $(OUTD)

$(OUTD)/$(name).exe : $(OUTD)/main.o $(proj_obj)
	clang.exe $(OUTD)/main.o $(proj_obj) -s -o $(OUTD)/$(name).exe -Wl,-Map,$(OUTD)/$(name).map

$(OUTD)/msgtext.o: src/msgtext.c src/H/msgdef.h
	$(CC) -o $(OUTD)/msgtext.o src/msgtext.c

$(OUTD)/reswords.o: src/reswords.c src/H/instruct.h src/H/special.h src/H/directve.h
	$(CC) -o $(OUTD)/reswords.o src/reswords.c

######

clean:
	@rm $(OUTD)/*.exe
	@rm $(OUTD)/*.obj
	@rm $(OUTD)/*.map
