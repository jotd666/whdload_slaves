PROGNAME = NickFaldosGolf

all : $(PROGNAME)CD32.slave $(PROGNAME).slave $(PROGNAME).islave


$(PROGNAME).islave : $(PROGNAME).islave.s
	basm $?

$(PROGNAME).slave : $(PROGNAME)HD.asm slave_version
	basm $(PROGNAME)HD.asm

$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.asm slave_version
	basm $(PROGNAME)CD32HD.asm
