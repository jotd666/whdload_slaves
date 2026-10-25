include ../../options.mk

PROGNAME = RedBaron
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all : $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) $(wildcard *.s *.i)
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
