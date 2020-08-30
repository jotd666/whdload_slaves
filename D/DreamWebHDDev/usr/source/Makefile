PROGNAME = DreamWeb

all : $(PROGNAME)ECS.slave  $(PROGNAME)AGA.slave

$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.asm
	basm $?

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.asm
	basm $?
