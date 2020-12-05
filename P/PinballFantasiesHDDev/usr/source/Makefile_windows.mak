#added by python script

PROGNAME = PinballFantasies
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad
CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(PROGNAME).islave $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave $(PROGNAME)AGACHIP.slave

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s
	wdate.py> datetime
	$(CMD) -DFAST_SLAVE -o $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
PinballFantasiesAGACHIP.slave : PinballFantasiesAGAHD.s
	wdate.py> datetime
	$(CMD) -o PinballFantasiesAGACHIP.slave PinballFantasiesAGACHIPHD.s

$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.s
	wdate.py> datetime
	$(CMD) -o $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s

$(PROGNAME).islave: $(PROGNAME).islave.s
	wdate.py> datetime
	$(CMD) -o $(PROGNAME).islave $(PROGNAME).islave.s
