include ../../options.mk

PROGNAME = IndyLastCrusade


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	$(CMD) -o $(WHDLOADER) $(SOURCE)
