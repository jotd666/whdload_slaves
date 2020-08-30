PROGNAME = FantasticVoyage

all : $(PROGNAME).slave $(PROGNAME)CDTV.slave $(PROGNAME).islave

$(PROGNAME).islave : $(PROGNAME).islave.s
	basm $?

$(PROGNAME).slave : $(PROGNAME)HD.asm
	basm $?


$(PROGNAME)CDTV.slave : $(PROGNAME)CDTVHD.asm
	basm $?
