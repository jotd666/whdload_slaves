include ../../options.mk

PROGNAME = AlienBreed2

all :  $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s
	$(WDATE)
	$(VASM) -o $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.s
	$(WDATE)
	$(VASM) -o $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s
