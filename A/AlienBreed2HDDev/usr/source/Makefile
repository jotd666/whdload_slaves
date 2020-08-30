PROGNAME = AlienBreed2

all : $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.asm
	basm $?

$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.asm
	basm $?

