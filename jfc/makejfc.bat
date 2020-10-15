@echo off
\watcom\binnt\wcc386 -oxa -s -i\watcom\H jfc.c
jwlink format windows pe runtime console f jfc.obj libpath \watcom\lib386\nt;\watcom\lib386 lib kernel32,user32

rem debug version
rem \watcom\binnt\wcc386 -od -d2 -w3 -hc -i\watcom\H jfc.c
rem jwlink debug c op cvp,symfile format windows pe runtime console f jfc.obj libpath \watcom\lib386\nt;\watcom\lib386 lib kernel32,user32
