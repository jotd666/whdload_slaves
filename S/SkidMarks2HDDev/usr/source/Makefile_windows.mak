PROGNAME = Skidmarks2
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE
all :  $(PROGNAME).slave $(PROGNAME)_221.islave $(PROGNAME)_22.islave

CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

$(PROGNAME).slave : $(PROGNAME)HD.s
	wdate.py> datetime
	$(CMD) -DEIGHTMEGS  -o $(PROGNAME).slave $(PROGNAME)HD.s
	$(CMD)  -o $(PROGNAME)_lowmem.slave $(PROGNAME)HD.s

$(PROGNAME)_221.islave : $(PROGNAME).islave.s
	wdate.py> datetime
	$(CMD) -DSIX_TRACKDISKS -o $(PROGNAME)_221.islave $(PROGNAME).islave.s
$(PROGNAME)_22.islave : $(PROGNAME).islave.s
	wdate.py> datetime
	$(CMD) -o $(PROGNAME)_22.islave $(PROGNAME).islave.s
	

