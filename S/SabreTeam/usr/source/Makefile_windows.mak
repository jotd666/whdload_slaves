include ../../options.mk

PROGNAME = SabreTeam


CMD = $(VASM) -o

all :  $(PROGNAME)AGA.slave $(PROGNAME)CD32.slave

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s
	$(WDATE)
	$(CMD) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s 
$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.s
	$(WDATE)
	$(CMD) $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s 
