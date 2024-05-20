include ../../options.mk

PROGNAME = Virocop


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
CMD = $(VASM) -o

all :  $(PROGNAME)AGA.slave $(PROGNAME).slave

$(PROGNAME).slave: $(PROGNAME)HD.s
	$(WDATE)
	$(CMD) $(PROGNAME).slave $(PROGNAME)HD.s
$(PROGNAME)AGA.slave: $(PROGNAME)AGAHD.s
	$(WDATE)
	$(CMD) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
