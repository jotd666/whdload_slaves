PROGNAME = DGeneration
WHDBASE = K:\jff\AmigaHD\PROJETS\HDInstall\DONE\WHDLoad
all :  $(PROGNAME)ECS.slave $(PROGNAME)AGA.slave $(PROGNAME)CD32.slave

$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.s
	wdate.py > datetime
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -phxass -nosym -Fhunkexe -o $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s
	wdate.py > datetime
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -phxass -nosym -Fhunkexe -o $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.s
	wdate.py > datetime
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -phxass -nosym -Fhunkexe -o $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
