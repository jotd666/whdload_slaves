include ../../options.mk

PROGNAME = TestDrive


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) simulation.s render.s render-patches.i simulation-patches.i simulation-verify.s
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
