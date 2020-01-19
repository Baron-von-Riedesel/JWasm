
# This makefile creates the JWasm Win32 binary with CLang on Unix
#  'make CLUnix.mak'

name = jwasm

ifndef DEBUG
DEBUG=0
endif

inc_dirs  = -IH

#cflags stuff

ifeq ($(DEBUG),1)
extra_c_flags = -DDEBUG_OUT -g
OUTD=CLUnixD
else
extra_c_flags = -DNDEBUG -O2 -s
OUTD=CLUnixR
endif

TARGET1=$(OUTD)/$(name)
CC=clang
c_flags = -D__UNIX__ -Wno-parentheses -Wno-switch -Wno-enum-conversion $(extra_c_flags)

.SUFFIXES:
.SUFFIXES: .c .o

include gccmod.inc

$(OUTD)/%.o: %.c
	$(CC) -c $(inc_dirs) $(c_flags) -o $(OUTD)/$*.o $<

ALL: $(OUTD) $(TARGET1)

$(OUTD):
	mkdir $(OUTD)

$(OUTD)/$(name) : $(OUTD)/main.o $(proj_obj)
	$(CC) $(OUTD)/main.o $(proj_obj) -o $@ -Wl,-Map,$(TARGET1).map

$(OUTD)/msgtext.o: msgtext.c H/msgdef.h
	$(CC) -c $(inc_dirs) $(c_flags) -o $(OUTD)/msgtext.o msgtext.c

$(OUTD)/reswords.o: reswords.c H/instruct.h H/special.h H/directve.h
	$(CC) -c $(inc_dirs) $(c_flags) -o $(OUTD)/reswords.o reswords.c

######

clean:
	@rm -f $(OUTD)/$(name)
	@rm -f $(OUTD)/*.o
	@rm -f $(OUTD)/$(name).map
