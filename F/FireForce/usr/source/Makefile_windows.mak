PROGNAME = FireForce
W\PROJETS\WHDLoad
all :  $(PROGNAME)CD32.slave $(PROGNAME).slave

$(PROGNAME).slave : $(PROGNAME)HD.s
	$(WDATE)
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE)\Src\sources\whdload -phxass -nosym -Fhunkexe -o $(PROGNAME).slave $(PROGNAME)HD.s
$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.s
	$(WDATE)
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE)\Src\sources\whdload -phxass -nosym -Fhunkexe -o $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
