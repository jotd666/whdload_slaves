include ../../options.mk

PROGNAME = Oscar




all :  $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave

$(PROGNAME)AGA.slave: $(PROGNAME)HD.s
	$(WDATE)
	$(VASM) -DAGA_VERSION -o $(PROGNAME)AGA.slave $(PROGNAME)HD.s

$(PROGNAME)ECS.slave: $(PROGNAME)HD.s
	$(WDATE)
	$(VASM) -o $(PROGNAME)ECS.slave $(PROGNAME)HD.s

