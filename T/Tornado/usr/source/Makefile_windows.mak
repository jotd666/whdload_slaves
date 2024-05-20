include ../../options.mk

PROGNAME = Tornado


WHDLOADER = 
SOURCE = $(PROGNAME)HD.s
ASM = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -nosym -Fhunkexe

all :  $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s
	$(WDATE)
	$(ASM) -o $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.s
	$(WDATE)
	$(ASM) -o $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s
