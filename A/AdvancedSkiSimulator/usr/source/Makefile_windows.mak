include ../../options.mk

PROGNAME = AdvancedSkiSimulator


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
OPTS = -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)/whdload/Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	vasmm68k_mot $(OPTS) -o $(WHDLOADER) $(SOURCE)
