include ../../options.mk

PROGNAME = Outrun


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER) 

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)

