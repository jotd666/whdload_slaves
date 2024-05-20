include ../../options.mk

PROGNAME = Turrican2


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
OPTS = -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)/Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(WHDLOADER) 

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	vasmm68k_mot $(OPTS) -o $(WHDLOADER) $(SOURCE)
	vasmm68k_mot -DCDTV_VERSION $(OPTS) -o $(PROGNAME)CDTV.slave $(SOURCE)
