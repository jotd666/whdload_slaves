include ../../options.mk

PROGNAME = JamesPond


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(PROGNAME).slave $(PROGNAME)1MB.slave

$(PROGNAME).slave : $(SOURCE)
	$(WDATE)
	$(VASM) -o $(PROGNAME).slave $(SOURCE)
$(PROGNAME)1MB.slave : $(SOURCE)
	$(WDATE)
	vasmm68k_mot -DUSE_FASTMEM -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(PROGNAME)1MB.slave $(SOURCE)
