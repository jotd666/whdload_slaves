include ../../options.mk

PROGNAME = SmartyAndTheNastyGluttons



CMD = vasmm68k_mot
OPTS =  -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o

all :  $(PROGNAME).slave


$(PROGNAME).slave: $(PROGNAME)HD.s
	$(WDATE)
	$(CMD) $(OPTS) $(PROGNAME).slave $(PROGNAME)HD.s

