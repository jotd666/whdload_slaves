PROGNAME = ThemePark

all : $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave

$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.asm
	basm $<

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.asm
	basm $<
