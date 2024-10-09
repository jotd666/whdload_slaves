
include ../../options.mk

PROGNAME = Superfrog


WHDLOADER = $(PROGNAME).slave
WHDLOADER_CD32 = $(PROGNAME)CD32.slave
SOURCE = $(PROGNAME)HD.s
SOURCE_CD32 = $(PROGNAME)CD32HD.s
ISLAVE = $(PROGNAME).islave

all :  $(WHDLOADER) $(WHDLOADER_CD32)
# $(ISLAVE)


$(WHDLOADER) : $(SOURCE) ReadJoypad.s
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)


$(WHDLOADER_CD32) : $(SOURCE) ReadJoypad.s
	$(WDATE)
	$(VASM) -o $(WHDLOADER_CD32) $(SOURCE_CD32)



$(ISLAVE) : $(ISLAVE).s
	$(WDATE)
	$(VASM_NOPIC) -o $(ISLAVE) $(ISLAVE).s


