include ../../options.mk

PROGNAME = Gulp


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
CMD = $(VASM) -o

all :  $(PROGNAME).slave
# $(PROGNAME).slave

$(PROGNAME).slave: $(PROGNAME)HD.s shared.s
	$(WDATE)
	$(CMD) $(PROGNAME).slave $(PROGNAME)HD.s
$(PROGNAME)CD32.slave: $(PROGNAME)CD32HD.s shared.s
	$(WDATE)
	$(CMD) $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s