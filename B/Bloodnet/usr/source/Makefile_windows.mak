include ../../options.mk

PROGNAME = Bloodnet


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(PROGNAME)ECS.slave $(PROGNAME)AGA.slave

CMD = $(VASM) -o

$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.s $(PROGNAME)Shared.s
	$(WDATE)
	$(CMD) $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s
    
$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s $(PROGNAME)Shared.s
	$(WDATE)
	$(CMD) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
