include ../../options.mk

PROGNAME = RiseOfTheRobots


PREFIX = $(VASM) -o 


all : $(PROGNAME)AGA.slave $(PROGNAME)CD32.slave $(PROGNAME)ECS.slave

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s
	$(WDATE)
	$(PREFIX) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.s
	$(WDATE)
	$(PREFIX) $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s
$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.s
	$(WDATE)
	$(PREFIX) $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
