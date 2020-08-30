PROGNAME = Coala
WHDBASE = K:\jff\AmigaHD\PROJETS\WHDLoad
all :  $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s $(PROGNAME)HD.s
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE)\Src\sources\whdload -phxass -nosym -Fhunkexe -o $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.s $(PROGNAME)HD.s
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE)\Src\sources\whdload -phxass -nosym -Fhunkexe -o $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s
