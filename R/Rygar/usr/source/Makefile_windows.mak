include ../../options.mk

PROGNAME = Rygar


SOURCE = $(PROGNAME)HD.s

all :  $(PROGNAME).slave $(PROGNAME)_2MB.slave

$(PROGNAME)_2MB.slave : $(SOURCE)
	$(WDATE)
	vasmm68k_mot -DCHIP_ONLY -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(PROGNAME)_2MB.slave $(SOURCE)

$(PROGNAME).slave : $(SOURCE)
	$(WDATE)
	$(VASM) -o $(PROGNAME).slave $(SOURCE)
