# JWasm
masm compatible assembler.

Runs under Windows, Linux, DOS ( and probably other OSes as well ).

Hints:

- For Windows, use file Msvc.mak if Visual C is to be used to create a 32-bit version of JWasm. OWWin32.mak will create it using Open Watcom. Msvc64.mak will make a 64-bit version, using Visual C.

- For Linux, use GccUnix.mak to produce JWasm with gcc or CLUnix.mak to use CLang instead.

- For DOS, Open Watcom may be the best choice. It even allows to create a 16-bit (limited) version of JWasm that runs on a 8088 cpu. But Visual C is also possible, although you probably need the HX development files then.

There is a bunch of other makefiles in the main directory, intended for other compilers. Some of them might be a bit outdated.
