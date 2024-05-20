include ../../options.mk

PROGNAME = TheSettlers


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
