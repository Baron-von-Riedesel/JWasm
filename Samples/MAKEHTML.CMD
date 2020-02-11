@echo off
FOR %%f in (*.asm) DO masm2htm %%f ..\SmplHtml\%%~nf.html
