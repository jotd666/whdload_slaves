include ../../options.mk

PROGNAME = Prey


WHDLOADER = 
SOURCE = $(PROGNAME)HD.s
ASM = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(PROGNAME).slave

$(PROGNAME).slave : $(PROGNAME)HD.s
	$(WDATE)
	$(ASM) -o $(PROGNAME).slave $(PROGNAME)HD.s

