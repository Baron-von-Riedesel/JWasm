
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

inc_dirs  = -IH

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

$(OUTD)/%.o: %.c
	$(CC) -o $(OUTD)/$*.o $<

include gccmod.inc

TARGET1=$(OUTD)/$(name).exe

ALL: $(OUTD) $(TARGET1)

$(OUTD):
	mkdir $(OUTD)

$(OUTD)/$(name).exe : $(OUTD)/main.o $(proj_obj)
	$(CC) $(OUTD)/main.o $(proj_obj) -s -o $(OUTD)/$(name).exe -Wl,-Map,$(OUTD)/$(name).map

$(OUTD)/msgtext.o: msgtext.c H/msgdef.h
	$(CC) -o $(OUTD)/msgtext.o msgtext.c

$(OUTD)/reswords.o: reswords.c H/instruct.h H/special.h H/directve.h
	$(CC) -o $(OUTD)/reswords.o reswords.c

######

clean:
	@rm $(OUTD)/*.exe
	@rm $(OUTD)/*.o
	@rm $(OUTD)/*.map
