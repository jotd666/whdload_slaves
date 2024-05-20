PROGNAME = AlienBreed2
W\PROJETS\WHDLoad
all :  $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s
	$(WDATE)
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE)\Src\sources\whdload -phxass -nosym -Fhunkexe -o $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.s
	$(WDATE)
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE)\Src\sources\whdload -phxass -nosym -Fhunkexe -o $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s
