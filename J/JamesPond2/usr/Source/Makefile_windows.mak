#added by python script

PROGNAME = JamesPond2
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE


all :  $(PROGNAME)CD32.slave $(PROGNAME)AGA.slave

$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.s
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
