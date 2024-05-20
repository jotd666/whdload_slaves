include ../../options.mk

PROGNAME = JamesPond2




all :  $(PROGNAME)CD32.slave $(PROGNAME)AGA.slave

$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.s
	$(WDATE)
	$(VASM) -o $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s
	$(WDATE)
	$(VASM) -o $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
