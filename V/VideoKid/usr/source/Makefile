include ../../options.mk

PROGNAME = VideoKid


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER) $(PROGNAME).islave

$(WHDLOADER) : $(SOURCE) ReadJoyPad.s
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
	
$(PROGNAME).islave : $(PROGNAME).islave.s
	$(WDATE)
	$(VASM_NOPIC) -o $(PROGNAME).islave $(PROGNAME).islave.s
