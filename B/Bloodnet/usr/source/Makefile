PROGNAME = Bloodnet

all : $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave

$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.asm $(PROGNAME)Shared.asm
	basm $(PROGNAME)ECSHD.asm

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.asm $(PROGNAME)Shared.asm
	basm $(PROGNAME)AGAHD.asm
