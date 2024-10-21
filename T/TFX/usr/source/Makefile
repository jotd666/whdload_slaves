include ../../options.mk

PROGNAME = TFX


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER) fpsp

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -nosym -Fhunkexe -o $(WHDLOADER) $(SOURCE)

#fp.s: big.asm
#	mit2mot.py --optimize --noincludes --showduplabels big.asm fp.s

fpsp: fp.s code.s fpsp.defs
	vasmm68k_mot -maxerrors=0 -devpac -nosym -Fhunkexe -o fpsp code.s

