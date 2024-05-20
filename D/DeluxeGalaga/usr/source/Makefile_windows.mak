include ../../options.mk

PROGNAME = DeluxeGalaga



SOURCE = $(PROGNAME)HD.s
OPTS = -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave

$(PROGNAME)AGA.slave : $(SOURCE)
	$(WDATE)
	vasmm68k_mot -D_AGA $(OPTS) -o $(PROGNAME)AGA.slave $(SOURCE)
	
$(PROGNAME)ECS.slave : $(SOURCE)
	$(WDATE)
	vasmm68k_mot $(OPTS) -o $(PROGNAME)ECS.slave $(SOURCE)
