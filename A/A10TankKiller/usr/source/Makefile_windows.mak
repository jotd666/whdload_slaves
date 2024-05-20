include ../../options.mk

PROGNAME = A10TankKiller


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(WHDLOADER) $(SOURCE)
