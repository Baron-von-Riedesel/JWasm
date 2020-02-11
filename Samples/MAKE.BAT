@echo off
rem assembles all samples (no link!)
JWasm -nologo -bin -Fo Dos1.com Dos1.asm
JWasm -nologo -mz Dos2.asm
JWasm -nologo -mz Dos3.asm
JWasm -nologo -mz DOS64.asm
JWasm -nologo -elf gtk01.asm
JWasm -nologo -coff html2txt.asm
JWasm -nologo -coff jfc.asm
JWasm -nologo -elf64 -Fo=Lin64_1.o Lin64_1.asm
JWasm -nologo -Fo=Linux1.o Linux1.asm
JWasm -nologo -elf -zcw -Fo=Linux2.o Linux2.asm
JWasm -nologo -elf -Fo=Linux3.o Linux3.asm
JWasm -nologo -elf -Fo=Linux4a.o Linux4a.asm
JWasm -nologo -elf -Fo=Linux4d.o Linux4d.asm
JWasm -nologo -q -bin -Fo=Linux5. Linux5.asm
JWasm -nologo -coff masm2htm.asm
JWasm -nologo -coff bin2inc.asm
JWasm -nologo -coff res2inc.asm
JWasm -nologo -coff Math1.asm
JWasm -nologo Mixed116.asm
JWasm -nologo -coff Mixed132.asm
JWasm -nologo Mixed216.asm
JWasm -nologo -coff Mixed232.asm
JWasm -nologo -elf -zcw -Fo ncurs1.o ncurs1.asm
JWasm -nologo os216.asm
JWasm -nologo os232.asm
JWasm -nologo Win16_1.asm
JWasm -nologo Win16_2d.asm
JWasm -nologo Win32_1.asm
if exist "\WinInc" JWasm -nologo Win32_2.asm
if exist "\Masm32" JWasm -nologo -coff Win32_3.asm
JWasm -nologo -coff Win32_4a.asm
JWasm -nologo -coff Win32_4d.asm
JWasm -nologo -bin -Fo Win32_5.exe Win32_5.asm
JWasm -nologo -coff -DUNICODE Win32_6.asm
if exist "\WinInc" JWasm -nologo -coff -DUNICODE Win32_6w.asm
JWasm -nologo -coff -Fd Win32_7.asm
JWasm -nologo -pe Win32_8.asm
if exist "\Masm32" JWasm -nologo -pe Win32_8m.asm
JWasm -nologo -coff Win32Drv.asm
if exist "\WinInc" JWasm -nologo -coff Win32DrvA.asm
JWasm -nologo -coff JWasmDyn.asm
JWasm -nologo -coff Win32Tls.asm
JWasm -nologo -coff ComDat.asm
JWasm -nologo -zf1 owfc16.asm
JWasm -nologo -zf1 owfc32.asm
JWasm -nologo -win64 Win64_1.asm
JWasm -nologo -win64 Win64_2.asm
JWasm -nologo -win64 Win64_3.asm
JWasm -nologo -win64 Win64_3e.asm
if exist "\WinInc" JWasm -nologo -win64 -Zp8 -I\WinInc\Include Win64_4.asm
if exist "\WinInc" JWasm -nologo -win64 Win64_5.asm
JWasm -nologo -win64 Win64_6.asm
JWasm -nologo -pe Win64_8.asm
JWasm -nologo -win64 Win64_9a.asm
JWasm -nologo -win64 Win64_9d.asm
if exist "\WinInc" JWasm -nologo -coff -I\WinInc\Include WinXX_1.asm
