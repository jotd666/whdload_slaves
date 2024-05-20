include ../../options.mk

PROGNAME = Exile


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
CMD = $(VASM) -o

all :  $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave

$(PROGNAME)ECS.slave: $(PROGNAME)ECSHD.s
	$(WDATE)
	$(CMD) $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s
$(PROGNAME)CD32.slave: $(PROGNAME)CD32HD.s
	$(WDATE)
	$(CMD) $(PROGNAME)CD32.slave $(PROGNAME)AGAHD.s
$(PROGNAME)AGA.slave: $(PROGNAME)AGAHD.s
	$(WDATE)
	$(CMD) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
