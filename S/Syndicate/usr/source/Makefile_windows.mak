include ../../options.mk

PROGNAME = Syndicate


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all : $(PROGNAME)CD32.slave

$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.s
	$(WDATE)
	$(VASM) -o $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
