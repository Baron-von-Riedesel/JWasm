# assembles all samples (no link!)
set -e

./jwasm -nologo -bin -Fo Dos1.com Dos1.asm
./jwasm -nologo -mz Dos2.asm
./jwasm -nologo -mz Dos3.asm
./jwasm -nologo -mz Dos64.asm
./jwasm -nologo -elf gtk01.asm
./jwasm -nologo -coff html2txt.asm
./jwasm -nologo -coff jfc.asm
./jwasm -nologo -elf64 -Fo=Lin64_1.o Lin64_1.asm
./jwasm -nologo -Fo=Linux1.o Linux1.asm
./jwasm -nologo -elf -zcw -Fo=Linux2.o Linux2.asm
./jwasm -nologo -elf -Fo=Linux3.o Linux3.asm
./jwasm -nologo -elf -Fo=Linux4a.o Linux4a.asm
./jwasm -nologo -elf -Fo=Linux4d.o Linux4d.asm
./jwasm -nologo -q -bin -Fo=Linux5. Linux5.asm
./jwasm -nologo -coff masm2htm.asm
./jwasm -nologo -coff Bin2Inc.asm
./jwasm -nologo -coff Res2Inc.asm
./jwasm -nologo -coff Math1.asm
./jwasm -nologo Mixed116.asm
./jwasm -nologo -coff Mixed132.asm
./jwasm -nologo Mixed216.asm
./jwasm -nologo -coff Mixed232.asm
./jwasm -nologo -elf -zcw -Fo=ncurs1.o ncurs1.asm
./jwasm -nologo OS216.asm
./jwasm -nologo OS232.asm
./jwasm -nologo Win16_1.asm
./jwasm -nologo Win16_2d.asm
./jwasm -nologo Win32_1.asm
if [ -d "./WinInc" ]; then
  ./jwasm -nologo Win32_2.asm
fi
if [ -d "./Masm32" ]; then
  ./jwasm -nologo -coff Win32_3.asm
fi
./jwasm -nologo -coff Win32_4a.asm
./jwasm -nologo -coff Win32_4d.asm
./jwasm -nologo -bin -Fo=Win32_5.exe Win32_5.asm
./jwasm -nologo -coff -DUNICODE Win32_6.asm
if [ -d "./WinInc" ]; then
  ./jwasm -nologo -coff -DUNICODE Win32_6w.asm
fi
./jwasm -nologo -coff -Fd Win32_7.asm
./jwasm -nologo -pe Win32_8.asm
if [ -d "./Masm32" ]; then
  ./jwasm -nologo -pe Win32_8m.asm
fi
./jwasm -nologo -coff Win32Drv.asm
if [ -d "./WinInc" ]; then
  ./jwasm -nologo -coff Win32DrvA.asm
fi
./jwasm -nologo -coff ./JWasmDyn.asm
./jwasm -nologo -coff Win32Tls.asm
./jwasm -nologo -coff ComDat.asm
./jwasm -nologo -zf1 owfc16.asm
./jwasm -nologo -zf1 owfc32.asm
./jwasm -nologo -win64 Win64_1.asm
./jwasm -nologo -win64 Win64_2.asm
./jwasm -nologo -win64 Win64_3.asm
./jwasm -nologo -win64 Win64_3e.asm
if [ -d "./WinInc" ]; then
  ./jwasm -nologo -win64 -Zp8 -I/WinInc/Include Win64_4.asm
  ./jwasm -nologo -win64 Win64_5.asm
fi
./jwasm -nologo -win64 Win64_6.asm
./jwasm -nologo -pe Win64_8.asm
./jwasm -nologo -win64 Win64_9a.asm
./jwasm -nologo -win64 Win64_9d.asm
if [ -d "./WinInc" ]; then
  ./jwasm -nologo -coff -I/WinInc/Include WinXX_1.asm
fi
