PROGNAME = TheHumans
WHDLOADER = $(PROGNAME).slave
WHDLOADER_CD32 = $(PROGNAME)CD32.slave
SOURCE = $(PROGNAME)HD.asm
SOURCE_CD32 = $(PROGNAME)CD32HD.asm
ISLAVE = $(PROGNAME).islave
ISOURCE = $(PROGNAME).islave.s

all :  $(WHDLOADER) $(WHDLOADER_CD32) $(ISLAVE)

$(WHDLOADER) : $(SOURCE) slave_version
	basm $(SOURCE)

$(WHDLOADER_CD32) : $(SOURCE_CD32) slave_version
	basm $(SOURCE_CD32)

$(ISLAVE) : $(ISOURCE)
	basm $?
