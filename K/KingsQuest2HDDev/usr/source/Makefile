PROGNAME = KingsQuest2

all : $(PROGNAME).slave $(PROGNAME)Files.slave

$(PROGNAME).slave : $(PROGNAME)HD.asm
	basm $?

$(PROGNAME)Files.slave : $(PROGNAME)FilesHD.asm
	basm $?
