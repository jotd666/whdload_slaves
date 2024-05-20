include ../../options.mk

PROGNAME = LaserSquad


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) savegame.s
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
