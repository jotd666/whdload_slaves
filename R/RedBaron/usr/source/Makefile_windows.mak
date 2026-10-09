include ../../options.mk

PROGNAME = RedBaron


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) tape.s tape-route.i observe.s perf.s originals.s paint-observe.s
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)

developer : $(PROGNAME)-developer.slave

verify : $(PROGNAME)-verify.slave

$(PROGNAME)-developer.slave : $(SOURCE) tape.s tape-route.i observe.s perf.s originals.s paint-observe.s
	$(WDATE)
	$(VASM) -DDEVELOPER=1 -o $@ $(SOURCE)

$(PROGNAME)-verify.slave : $(SOURCE) tape.s tape-route.i observe.s perf.s originals.s paint-observe.s
	$(WDATE)
	$(VASM) -DVERIFY=1 -o $@ $(SOURCE)
