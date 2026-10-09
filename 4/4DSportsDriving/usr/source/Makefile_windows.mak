include ../../options.mk

PROGNAME = 4DSportsDriving


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) driving_tape.s performance.s geometry.s geometry_verify.s
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
