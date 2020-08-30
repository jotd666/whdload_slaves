PROGNAME = TestDrive2
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.asm

all :  $(WHDLOADER) datmerger

$(WHDLOADER) : $(SOURCE)
	basm $(SOURCE)

datmerger : datmerger.c Makefile
	dcc -3.1 datmerger.c 
