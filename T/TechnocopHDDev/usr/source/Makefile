PROGNAME = Technocop
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.asm

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) binfixes.asm
	basm $(SOURCE)
