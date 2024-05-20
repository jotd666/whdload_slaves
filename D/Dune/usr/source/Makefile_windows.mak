include ../../options.mk

PROGNAME = Dune


WHDLOADER = $(PROGNAME).slave
WHDLOADERFLOP = $(PROGNAME)_floppy.slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER) $(WHDLOADERFLOP)

$(WHDLOADERFLOP) : $(SOURCE)
	$(WDATE)
	vasmm68k_mot -DFLOPPY_VERSION -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(WHDLOADERFLOP) $(SOURCE)
$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
