include ../../options.mk

PROGNAME = GrandPrixCircuit


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) render.s render-subunit.s simulation.s
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
