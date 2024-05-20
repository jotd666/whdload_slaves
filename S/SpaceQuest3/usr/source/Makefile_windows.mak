include ../../options.mk

PROGNAME = SpaceQuest3


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) sierra_hdinit.s
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
