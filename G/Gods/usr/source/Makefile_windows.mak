include ../../options.mk

PROGNAME = Gods


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
$(PROGNAME)_1MB_chip.slave : $(SOURCE)
	$(WDATE)
	vasmm68k_mot -DONEMEG_CHIP -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(PROGNAME)_1MB_chip.slave $(SOURCE)
