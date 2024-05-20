include ../../options.mk

PROGNAME = Paperboy


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER) $(PROGNAME).islave

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)

$(PROGNAME).islave: $(PROGNAME).islave.s
	$(WDATE)
	$(VASM) -o $(PROGNAME).islave $(PROGNAME).islave.s
