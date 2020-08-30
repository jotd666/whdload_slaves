#added by python script

PROGNAME = Ishar
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad


all :  $(PROGNAME)AGA.slave $(PROGNAME)OCS.slave

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
$(PROGNAME)OCS.slave : $(PROGNAME)OCSHD.s
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(PROGNAME)OCS.slave $(PROGNAME)OCSHD.s
