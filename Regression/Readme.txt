
  Regression Tests for JWasm

  1. Prepare Tests
  
  - tool JFC must be created. Source code is supplied in directory Tools.
  - jwlink (modified OW WLink) must be downloaded from github.
  - MS link from VC 8 is used for one Win64 SEH test.
  - jwasmr.exe ( the 16-bit real-mode version of jwasm ) is used for
    a few tests.
  - tools jfc, jwlink and MS link are expected to be in directory ..\Tools

  2. Run Tests
  
  Windows: RUNTEST.CMD
  DOS:     start cmd.exe (from Windows XP), then RUNTEST.CMD
  Linux:   runtest.sh

  If everything is ok, there's no display at all.

  3. Known Bugs

  Windows:
  - jwasmr.exe: 16-bit programs won't work in 64-bit Windows.
  Linux:
  - jwlink: There's currently no 64-bit version available.
  - jwasmr.exe: no 16-bit programs for Linux.
  - link.exe: won't run natively, maybe Wine?



