include ../../options.mk

PROGNAME = CastleMaster


WHDLOADER = $(PROGNAME)2.slave
SOURCE = ../CastleMasterHDDev/$(PROGNAME)HD.s
OPTS = -DCM2_STANDALONE -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	vasmm68k_mot $(OPTS) -o $(WHDLOADER) $(SOURCE)

