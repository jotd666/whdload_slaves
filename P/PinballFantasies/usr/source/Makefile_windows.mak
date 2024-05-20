include ../../options.mk

PROGNAME = PinballFantasies


CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(PROGNAME).islave $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave $(PROGNAME)AGACHIP.slave

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s
	$(WDATE)
	$(CMD) -DFAST_SLAVE -o $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
PinballFantasiesAGACHIP.slave : PinballFantasiesAGAHD.s
	$(WDATE)
	$(CMD) -o PinballFantasiesAGACHIP.slave PinballFantasiesAGACHIPHD.s

$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.s
	$(WDATE)
	$(CMD) -o $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s

$(PROGNAME).islave: $(PROGNAME).islave.s
	$(WDATE)
	$(CMD) -o $(PROGNAME).islave $(PROGNAME).islave.s
