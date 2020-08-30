#added by python script

PROGNAME = Prehistorik
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad
CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(PROGNAME)CDTV.slave  $(PROGNAME).slave

$(PROGNAME).slave : $(PROGNAME)HD.s
	wdate.py> datetime
	$(CMD) -o $(PROGNAME).slave $(PROGNAME)HD.s

$(PROGNAME)CDTV.slave : $(PROGNAME)CDTVHD.s
	wdate.py> datetime
	$(CMD) -o $(PROGNAME)CDTV.slave $(PROGNAME)CDTVHD.s
