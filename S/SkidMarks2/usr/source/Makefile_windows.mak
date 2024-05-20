PROGNAME = Skidmarks2


all :  $(PROGNAME).slave $(PROGNAME)_221.islave $(PROGNAME)_22.islave

CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

$(PROGNAME).slave : $(PROGNAME)HD.s
	$(WDATE)
	$(CMD) -DEIGHTMEGS  -o $(PROGNAME).slave $(PROGNAME)HD.s
	$(CMD)  -o $(PROGNAME)_lowmem.slave $(PROGNAME)HD.s

$(PROGNAME)_221.islave : $(PROGNAME).islave.s
	$(WDATE)
	$(CMD) -DSIX_TRACKDISKS -o $(PROGNAME)_221.islave $(PROGNAME).islave.s
$(PROGNAME)_22.islave : $(PROGNAME).islave.s
	$(WDATE)
	$(CMD) -o $(PROGNAME)_22.islave $(PROGNAME).islave.s
	

