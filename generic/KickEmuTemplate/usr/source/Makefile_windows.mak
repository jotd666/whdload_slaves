include ../../options.mk

PROGNAME = TowerFRA


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
CMD = $(VASM) -o

all :  $(PROGNAME).slave
#$(PROGNAME).slave

$(PROGNAME).slave: $(PROGNAME)HD.s
	$(WDATE)
	$(CMD) $(PROGNAME).slave $(PROGNAME)HD.s
