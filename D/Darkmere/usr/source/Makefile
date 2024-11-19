include ../../options.mk

PROGNAME = Darkmere


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) ReadJoyPad.s
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
