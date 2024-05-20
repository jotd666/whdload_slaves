include ../../options.mk

PROGNAME = WrongWayDriver


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER) 
#$(PROGNAME)_kick.slave

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)

$(PROGNAME)_kick.slave : $(PROGNAME)_kick_HD.s
	$(WDATE)
	$(VASM) -o $(PROGNAME)_kick.slave $(PROGNAME)_kick_HD.s
