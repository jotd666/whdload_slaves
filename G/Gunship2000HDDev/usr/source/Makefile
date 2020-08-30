PROGNAME = Gunship2000
SOURCE = $(PROGNAME)HD.asm

all :   $(PROGNAME)ECS.slave $(PROGNAME)AGA.slave $(PROGNAME)CD32.slave

$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.asm slave_version
	basm $(PROGNAME)CD32HD.asm

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.asm slave_version
	basm $(PROGNAME)AGAHD.asm

$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.asm slave_version
	basm $(PROGNAME)ECSHD.asm
