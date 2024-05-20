include ../../options.mk

PROGNAME = Speedball2


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)CD32HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
