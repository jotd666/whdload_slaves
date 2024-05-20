include ../../options.mk

PROGNAME = WhoFramedRogerRabbit


WHDLOADER = $(PROGNAME).slave
SOURCE = WhoFramedRRHD.s
OPTS = -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)/Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	vasmm68k_mot $(OPTS) -o $(WHDLOADER) $(SOURCE)
