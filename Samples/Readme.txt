
  Samples for JWasm

  Name          OS      fmt    type     comment
 -------------------------------------------------------------------
  Dos1.asm      DOS     bin    console  16bit program in COM format
  Dos2.asm      DOS     omf    console  16bit DPMI client
  Dos3.asm      DOS     mz     console  32bit DPMI client
  Dos64.asm     DOS     mz     console  switch to 64bit and back

  OS216.asm     OS/2    omf    console  16bit OS/2
  OS232.asm     OS/2    omf    console  32bit OS/2

  Win16_1.asm   Win16   omf    GUI      "Empty Window" sample
  Win16_2d.asm  Win16   omf    dll      simple dll with 2 exports

  Win32_1.asm   Win32   coff   console  "Hello world", no include files
  Win32_2.asm   Win32   coff   console  uses WinInc include files
  Win32_3.asm   Win32   coff   GUI      "Empty Window", no include files
  Win32_3m.asm  Win32   coff   GUI      like Win32_3, but uses Masm32
  Win32_4a.asm  Win32   coff   console  to run dll Win32_4d
  Win32_4d.asm  Win32   coff   dll      simple dll with 2 exports
  Win32_5.asm   Win32   bin    console  "manually" created PE binary 
  Win32_6.asm   Win32   coff   console  UNICODE sample, no include files
  Win32_6w.asm  Win32   coff   console  like Win32_6, but uses WinInc
  Win32_7.asm   Win32   coff   console  shows usage of OPTION DLLIMPORT
  Win32_8.asm   Win32   pe     GUI      renders a bitmap, no include files
  Win32_8e.asm  Win32   pe     GUI      like Win32_8, but uses res2inc
  Win32_8m.asm  Win32   pe     GUI      like Win32_8, but uses Masm32
  Win32Drv.asm  Win32   coff   driver   basic kernel driver (NT platform)
  Win32DrvA.asm Win32   coff   console  loads Win32Drv.sys
  JWasmDyn.asm  Win32   coff   console  sample how to use JWasm.dll
  Win32Tls.asm  Win32   coff   console  shows usage of static TLS
  ComDat.asm    Win32   coff   console  demonstrates usage of COMDAT sections

  Win64_1.asm   Win64   win64  GUI      "MessageBox" sample
  Win64_2.asm   Win64   win64  GUI      "Empty Window" sample
  Win64_3.asm   Win64   win64  GUI      "Empty Window" with SEH
  Win64_3e.asm  Win64   win64  GUI      like Win64_3, but with hll directives
  Win64_4.asm   Win64   win64  console  "Hello world", uses WinInc
  Win64_5.asm   Win64   win64  console  exception test, uses WinInc
  Win64_5m.asm  Win64   win64  console  exception test, no include files
  Win64_6.asm   Win64   win64  console  "Hello world", uses MSVCRT
  Win64_6p.asm  Win64   pe     console  "Hello world", uses MSVCRT
  Win64_8.asm   Win64   pe     GUI      renders a bitmap, no include files
  Win64_9a.asm  Win64   win64  console  to run dll Win64_9d
  Win64_9d.asm  Win64   win64  dll      simple dll with 2 exports

  WinXX_1.asm   Win32/64       console  "bimodal" source

  Linux1.asm    Linux   elf    console  uses int 80h
  Linux2.asm    Linux   elf    console  uses libc
  Linux3.asm    Linux   elf    GUI      uses Xlib
  Linux4a.asm   Linux   elf    console  test for Linux4d
  Linux4d.asm   Linux   elf             shared library
  Linux5.asm    Linux   bin    console  no link step required
  ncurs1.asm    Linux   elf    console  ncurses sample
  Lin64_1.asm   Linux64 elf64  console  uses syscall
  FreeBSD1.asm  FreeBSD bin    console  ELF header created manually

  Mixed1c.c                    console  mixed-language, main
  Mixed132.asm          coff            functions for Mixed1c, 32bit
  Mixed116.asm          omf             functions for Mixed1c, 16bit
  Mixed232.asm                 console  uses CRT functions, 32bit
  Mixed216.asm          omf    console  uses CRT functions, 16bit
  owfc16.asm            omf    console  how to use OW register conv, 16bit
  owfc32.asm            omf    console  how to use OW register conv, 32bit
  bin2inc.asm                  console  convert binary to assembly include file
  res2inc.asm                  console  convert .RES file to include file
  html2txt.asm                 console  simple Html to Text converter
  masm2htm.asm                 console  Masm source to Html converter
  jfc.asm                      console  simple binary file compare
  gtk01.asm                    GUI      GTK+ "hello world"
