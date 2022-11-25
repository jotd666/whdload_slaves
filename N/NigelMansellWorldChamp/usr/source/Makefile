PROGNAME = NigelMansellWC

all : $(PROGNAME).slave $(PROGNAME)CD32.slave

$(PROGNAME).slave: $(PROGNAME)HD.asm
	basm $(PROGNAME)HD.asm

$(PROGNAME)CD32.slave: $(PROGNAME)CD32HD.asm
	basm $(PROGNAME)CD32HD.asm
