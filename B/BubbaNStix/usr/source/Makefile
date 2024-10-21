include ../../options.mk

PROGNAME = BubbaNStix



SOURCE = $(PROGNAME)HD.s

all :  $(PROGNAME).slave $(PROGNAME)CD32.slave

$(PROGNAME).slave : $(SOURCE)
	$(WDATE)
	$(VASM) -o $(PROGNAME).slave $(SOURCE)
$(PROGNAME)CD32.slave : $(SOURCE)
	$(WDATE)
	vasmm68k_mot -DCD32 -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(PROGNAME)CD32.slave $(SOURCE)
