include ../../options.mk

PROGNAME = RuffNTumble


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER) 
#$(PROGNAME)_512chip.slave

$(WHDLOADER): $(SOURCE)
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)

#$(PROGNAME)_512chip.slave: $(SOURCE)
#	$(VASM) -DUSE_FASTMEM -o $(PROGNAME)_512chip.slave $(SOURCE)
