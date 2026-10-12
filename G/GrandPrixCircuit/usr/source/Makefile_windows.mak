include ../../options.mk

PROGNAME = GrandPrixCircuit


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) verification.s render.s render-subunit.s render-verify.s simulation.s simulation-verify.s verification-driving.s
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
