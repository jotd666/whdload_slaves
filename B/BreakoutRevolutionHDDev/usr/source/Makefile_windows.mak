#added by python script

PROGNAME = BreakoutRevolution
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE
CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(PROGNAME).slave
$(PROGNAME).slave : $(PROGNAME)HD.s
	wdate.py> datetime
	$(CMD) -o $(PROGNAME).slave $(PROGNAME)HD.s
	