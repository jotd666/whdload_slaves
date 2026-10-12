include ../../options.mk

PROGNAME = TestDrive


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) simulation-verify.s
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
