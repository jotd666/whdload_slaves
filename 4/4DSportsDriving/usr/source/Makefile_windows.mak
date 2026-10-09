include ../../options.mk

PROGNAME = 4DSportsDriving


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) driving_tape.s
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
