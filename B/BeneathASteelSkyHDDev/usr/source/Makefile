PROGNAME = BeneathASteelSky
WHDLOADER = $(PROGNAME).slave $(PROGNAME)CD32.slave
SOURCE = $(PROGNAME)HD.asm

all :  $(WHDLOADER)

$(PROGNAME).slave : $(SOURCE)
	basm $(SOURCE)

$(PROGNAME)CD32.slave : BASSCD32HD.asm
	basm BASSCD32HD.asm
