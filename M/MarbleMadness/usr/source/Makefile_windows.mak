include ../../options.mk

PROGNAME = MarbleMadness


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(WHDLOADER) $(PROGNAME)Image.slave

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	$(CMD) -o $(WHDLOADER) $(SOURCE)
$(PROGNAME)Image.slave : $(SOURCE)
	$(WDATE)
	$(CMD) -DDISKIMAGE -o $(PROGNAME)Image.slave $(SOURCE)
