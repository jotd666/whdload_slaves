include ../../options.mk

PROGNAME = Zool


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(PROGNAME).slave $(PROGNAME)AGA.slave $(PROGNAME)CD32.slave

CMD = $(VASM) -o 

$(PROGNAME).slave : $(SOURCE)
	$(WDATE)
	$(CMD) $(PROGNAME).slave $(SOURCE)
$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s
	$(WDATE)
	$(CMD) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.s lowlevel.s
	$(WDATE)
	$(CMD) $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
