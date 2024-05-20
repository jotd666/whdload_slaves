include ../../options.mk

PROGNAME = Prehistorik


CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(PROGNAME)CDTV.slave  $(PROGNAME).slave

$(PROGNAME).slave : $(PROGNAME)HD.s
	$(WDATE)
	$(CMD) -o $(PROGNAME).slave $(PROGNAME)HD.s

$(PROGNAME)CDTV.slave : $(PROGNAME)CDTVHD.s
	$(WDATE)
	$(CMD) -o $(PROGNAME)CDTV.slave $(PROGNAME)CDTVHD.s
