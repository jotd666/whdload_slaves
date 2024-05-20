include ../../options.mk

PROGNAME = Obliterator


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
OPTS = -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)/Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(WHDLOADER) $(PROGNAME).islave

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	vasmm68k_mot $(OPTS) -o $(WHDLOADER) $(SOURCE)
$(PROGNAME).islave: $(PROGNAME).islave.s
	$(WDATE)
	vasmm68k_mot $(OPTS) -o $(PROGNAME).islave $(PROGNAME).islave.s
