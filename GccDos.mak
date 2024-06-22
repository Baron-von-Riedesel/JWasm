
# This makefile creates the JWasm 32-bit DOS binary with DJGPP.
#  'make -f GccDos.mak'

name = jwasm

ifndef DEBUG
DEBUG=0
endif

inc_dirs  = -Isrc/H

#cflags stuff

ifeq ($(DEBUG),1)
extra_c_flags = -DDEBUG_OUT -g
OUTD=build\DJGPPd
else
extra_c_flags = -DNDEBUG -O2
OUTD=build\DJGPPr
endif

c_flags = $(extra_c_flags)

CC=gcc.exe -c $(inc_dirs) $(c_flags)

$(OUTD)/%.o: src/%.c
	$(CC) -o $(OUTD)/$*.o $<

include gccmod.inc

TARGET1=$(OUTD)/$(name).exe

ALL: $(OUTD) $(TARGET1)

$(OUTD):
	mkdir $(OUTD)

$(OUTD)/$(name).exe : $(OUTD)/main.o $(proj_obj)
	gcc.exe $(OUTD)/main.o $(proj_obj) -s -o $(OUTD)/$(name).exe -Wl,-Map,$(OUTD)/$(name).map

$(OUTD)/msgtext.o: src/msgtext.c src/H/msgdef.h src/H/globals.h
	$(CC) -o $(OUTD)/msgtext.o src/msgtext.c

$(OUTD)/reswords.o: src/reswords.c src/H/instruct.h src/H/special.h src/H/directve.h
	$(CC) -o $(OUTD)/reswords.o src/reswords.c

######

clean:
	@erase $(OUTD)\*.exe
	@erase $(OUTD)\*.obj
	@erase $(OUTD)\*.map
