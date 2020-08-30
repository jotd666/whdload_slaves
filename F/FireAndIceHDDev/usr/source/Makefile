PROGNAME = FireAndIce

all: $(PROGNAME).slave $(PROGNAME)CD32.slave $(PROGNAME).islave


$(PROGNAME).slave: $(PROGNAME)HD.asm
	basm $<

$(PROGNAME)CD32.slave: $(PROGNAME)CD32HD.asm
	basm $<

$(PROGNAME).islave:  $(PROGNAME).islave.s
	basm $<
