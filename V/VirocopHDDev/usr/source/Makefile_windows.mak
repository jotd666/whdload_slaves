#added by python script

PROGNAME = Virocop
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o

all :  $(PROGNAME)AGA.slave $(PROGNAME).slave

$(PROGNAME).slave: $(PROGNAME)HD.s
	wdate.py> datetime
	$(CMD) $(PROGNAME).slave $(PROGNAME)HD.s
$(PROGNAME)AGA.slave: $(PROGNAME)AGAHD.s
	wdate.py> datetime
	$(CMD) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
