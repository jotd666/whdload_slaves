include :whdl-options.mk

PROGNAME = Brat


WHDLSLAVE = $(PROGNAME).slave
SOURCE = $(PROGNAME).asm
ISLAVE = $(PROGNAME).islave

all : $(WHDLSLAVE) $(ISLAVE)

$(WHDLSLAVE) : $(SOURCE)
	$(NEWDATE2)
	$(VASM) -o $(WHDLSLAVE) $(SOURCE)


$(ISLAVE) : $(ISLAVE).asm
	$(NEWDATE2)
	$(VASM_NOPIC) -o $(ISLAVE) $(ISLAVE).asm
