include ../../options.mk

PROGNAME = EnchantedLand



SOURCE = $(PROGNAME)HD.s
OPTS = -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(PROGNAME).slave

$(PROGNAME).slave : $(SOURCE)
	$(WDATE)
	vasmm68k_mot $(OPTS) -o $(PROGNAME).slave $(SOURCE)
	