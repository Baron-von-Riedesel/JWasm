/*
 * This is the main program of a mixed-language sample.
 * The external functions - AsmFunc1() and AsmFunc2() - are written
 * in assembly (see Mixed132.asm or Mixed116.asm).
 *
 * To create a 32bit binary:
 * 1. Open Watcom
 *    wcc386 -ecc -3s mixed1c.c
 *    jwasm mixed132.asm
 *    wlink sys nt file mixed1c.obj, mixed132.obj
 * 2. MS VC
 *    cl -c mixed1c.c
 *    jwasm -coff mixed132.asm
 *    link mixed1c.obj mixed132.obj
 * 3. GCC (MinGW)
 *    gcc -c mixed1c.c
 *    jwasm -coff mixed132.asm
 *    gcc mixed1c.o mixed132.obj -o mixed1c.exe
 * 4. GCC (Linux)
 *    gcc -c Mixed1c.c
 *    JWasm -zcw -elf Mixed132.asm
 *    gcc Mixed1c.o Mixed132.o -o Mixed1c
 *
 * To create a 16bit binary:
 * 1. Open Watcom
 *    wcc -ecc mixed1c.c
 *    jwasm mixed116.asm
 *    wlink sys dos file mixed1c.obj, mixed116.obj
 * 2. MS VC 1.52c
 *    cl -c mixed1c.c
 *    jwasm mixed116.asm
 *    link16 mixed1c.obj + mixed116.obj, mixed1c.exe;
 */

#include <stdio.h>

extern long AsmFunc1(int, int);
extern double AsmFunc2(int);

int main()
{
    printf("AsmFunc1(2,3)=%d\n", AsmFunc1(2,3));
    printf("AsmFunc2(2)=%f\n", AsmFunc2(2));
    return(0);
}
