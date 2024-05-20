include ../../options.mk

PROGNAME = FireAndIce


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
CMD = $(VASM) -o

all :  $(PROGNAME)CD32.slave $(PROGNAME).slave

$(PROGNAME).slave: $(PROGNAME)HD.s
	$(WDATE)
	$(CMD) $(PROGNAME).slave $(PROGNAME)HD.s
$(PROGNAME)CD32.slave: $(PROGNAME)CD32HD.s
	$(WDATE)
	$(CMD) $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
