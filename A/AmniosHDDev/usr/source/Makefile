PROGNAME = Amnios

all : $(PROGNAME).slave $(PROGNAME).islave

$(PROGNAME).slave : $(PROGNAME)HD.asm
	basm $?

$(PROGNAME).islave : $(PROGNAME).islave.s
	basm $?
