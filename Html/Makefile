
# Makefile (OW wmake style) to create JWasm.chm/JWasm.chi 
# input files:
# - Manual.html
# tools:
# - awk.exe, from Open Watcom
# - hhc.exe, from MS Html-Help Workshop

OUTD=Win32
hc_hh = "\HTMLHelp\hhc.exe"

#.EXTENSIONS: .chm .chi

$(OUTD)\JWasm.chm $(OUTD)\JWasm.chi : $(OUTD)\Jwasm.hhc $(OUTD)\Jwasm.hhk $(OUTD)\Jwasm.hhp
	@cd $(OUTD)
	-$(hc_hh) JWasm.hhp
	@cd ..

$(OUTD)\JWasm.hhc $(OUTD)\JWasm.hhk $(OUTD)\JWasm.hhp: Manual.html Manual.mix
	@if not exist $(OUTD) mkdir $(OUTD)
	..\Tools\awk -f splithtm.awk -v dir=$(OUTD) Manual.html
	..\Tools\awk -f makehhc.awk Manual.html >$(OUTD)\JWasm.hhc
	..\Tools\awk -f makehhk.awk Manual.mix >$(OUTD)\JWasm.hhk
	..\Tools\awk -f makehhp.awk -v hhcfile=JWasm.hhc -v hhkfile=JWasm.hhk Manual.html >$(OUTD)\JWasm.hhp

