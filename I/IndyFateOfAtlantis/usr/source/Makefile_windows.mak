PROGNAME = IndyFateOfAtlantis
W\PROJETS\HDInstall\DONE\WHDLoad
all :  $(PROGNAME).slave

$(PROGNAME).slave : $(PROGNAME)HD.s
	wdate.py > datetime
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -phxass -nosym -Fhunkexe -o $(PROGNAME).slave $(PROGNAME)HD.s
