include ../../options.mk

PROGNAME = BlackDawn


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
