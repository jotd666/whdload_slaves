PROGNAME = PinballFantasies

all : $(PROGNAME).slave $(PROGNAME)CHIPONLY.slave 

$(PROGNAME).slave : PinballFantAGAHD.asm
	basm $?

$(PROGNAME)CHIPONLY.slave : PinballFantCHIPONLYHD.asm
	basm $?

