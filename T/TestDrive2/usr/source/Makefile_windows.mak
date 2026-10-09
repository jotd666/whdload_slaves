include ../../options.mk

PROGNAME = TestDrive2


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) simulation.s simulation-patches.i simulation-verify.s render.s
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
