include ../../options.mk

PROGNAME = BreakoutRevolution


CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(PROGNAME).slave
$(PROGNAME).slave : $(PROGNAME)HD.s
	$(WDATE)
	$(CMD) -o $(PROGNAME).slave $(PROGNAME)HD.s
	