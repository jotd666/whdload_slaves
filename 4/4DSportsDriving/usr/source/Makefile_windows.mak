include ../../options.mk

PROGNAME = 4DSportsDriving


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(wildcard *.s *.i)
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
