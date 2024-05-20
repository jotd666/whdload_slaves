include ../../options.mk

PROGNAME = ChaosEngine


SOURCE = $(PROGNAME)HD.s
CMD = $(VASM) -o
DEPS = shared.s ReadJoyPad.s

all :  $(PROGNAME)CD32.slave $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave


$(PROGNAME)ECS.slave: $(PROGNAME)ECSHD.s
	$(WDATE)
	$(CMD) $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s
$(PROGNAME)CD32.slave: $(PROGNAME)CD32HD.s $(DEPS)
	$(WDATE)
	$(CMD) $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
$(PROGNAME)AGA.slave: $(PROGNAME)AGAHD.s $(DEPS)
	$(WDATE)
	$(CMD) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
