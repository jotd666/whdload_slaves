include ../../options.mk

PROGNAME = BodyBlowsGalactic


CMD = $(VASM) -o

all :  $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s BBUtil.s
	$(WDATE)
	$(CMD) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s 
$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.s BBUtil.s
	$(WDATE)
	$(CMD) $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s 
