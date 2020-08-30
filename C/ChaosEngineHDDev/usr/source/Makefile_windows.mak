#added by python script

PROGNAME = ChaosEngine
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad
SOURCE = $(PROGNAME)HD.s
CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o
DEPS = shared.s ReadJoyPad.s

all :  $(PROGNAME)CD32.slave $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave


$(PROGNAME)ECS.slave: $(PROGNAME)ECSHD.s
	wdate.py> datetime
	$(CMD) $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s
$(PROGNAME)CD32.slave: $(PROGNAME)CD32HD.s $(DEPS)
	wdate.py> datetime
	$(CMD) $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
$(PROGNAME)AGA.slave: $(PROGNAME)AGAHD.s $(DEPS)
	wdate.py> datetime
	$(CMD) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
