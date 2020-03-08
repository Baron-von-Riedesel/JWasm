
# Makefile to create JWasm.chm/JWasm.chi
# input files:
# - Manual.html

OUTD=Win32
hc_hh = "d:\tools\html_help_workshop\hhc.exe"

.EXTENSIONS: .chm .chi

$(OUTD)\JWasm.chm $(OUTD)\JWasm.chi : $(OUTD)\Jwasm.hhc $(OUTD)\Jwasm.hhk $(OUTD)\Jwasm.hhp
	@cd $(OUTD)
	-$(hc_hh) JWasm.hhp
	@cd ..

$(OUTD)\JWasm.hhc $(OUTD)\JWasm.hhk $(OUTD)\JWasm.hhp: Manual.html Manual.mix
	@if not exist $(OUTD) mkdir $(OUTD)
	awk -f splithtm.awk -v dir=$(OUTD) Manual.html
	awk -f makehhc.awk Manual.html >$(OUTD)/JWasm.hhc
	awk -f makehhk.awk Manual.mix >$(OUTD)/JWasm.hhk
	awk -f makehhp.awk -v hhcfile=JWasm.hhc -v hhkfile=JWasm.hhk Manual.html >$(OUTD)/JWasm.hhp

