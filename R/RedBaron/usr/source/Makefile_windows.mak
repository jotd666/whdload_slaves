include ../../options.mk

PROGNAME = RedBaron


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) tape.s tape-route.i
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
