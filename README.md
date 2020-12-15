# JWasm
masm compatible assembler.

Runs under Windows, Linux, DOS, OS/2 ( and probably other OSes as well ).

Hints:

- For Windows, use file Msvc.mak/Msvc64.mak if Visual C++ is to be used to create a 32-/64-bit version of JWasm. OWWin32.mak will create a 32-bit binary using Open Watcom.

- For Linux, use GccUnix.mak to produce JWasm with gcc or CLUnix.mak to use CLang instead.

- For DOS, Open Watcom may be the best choice. It even allows to create a 16-bit (limited) version of JWasm that runs on a 8088 cpu. Old versions of Visual C++ are also possible, although you probably need the HX development files then.

- For OS/2, OWOS2.mak (Open Watcom) is supplied.

There is a bunch of other makefiles in the main directory, intended for other compilers. Some of them might be a bit outdated.

[JWasm Manual](https://Baron-von-Riedesel.github.io/JWasm/Html/Manual.html)
