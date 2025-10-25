include ../../options.mk

PROGNAME = BeneathASteelSky




WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)  $(PROGNAME)CD32.slave

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.s
	$(WDATE)
	$(VASM) -o $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s

