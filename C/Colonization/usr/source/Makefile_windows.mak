include ../../options.mk

PROGNAME = Colonization



SOURCE = $(PROGNAME)HD.s

all :  $(PROGNAME)AGA.slave

$(PROGNAME)AGA.slave : $(SOURCE)
	$(WDATE)
	$(VASM) -o $(PROGNAME)ECS.slave $(SOURCE)
	vasmm68k_mot -DAGA -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(PROGNAME)AGA.slave $(SOURCE)
