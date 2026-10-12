include ../../options.mk

PROGNAME = GrandPrixCircuit


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) verification.s render.s
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
