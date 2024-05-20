include ../../options.mk

PROGNAME = SkeletonKrew


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
CMD = $(VASM) -o

all :  $(PROGNAME)CD32.slave $(PROGNAME)AGA.slave

$(PROGNAME)AGA.slave: $(PROGNAME)AGAHD.s
	$(WDATE)
	$(CMD) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
$(PROGNAME)CD32.slave: $(PROGNAME)CD32HD.s
	$(WDATE)
	$(CMD) $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
