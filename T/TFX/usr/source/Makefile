include ../../options.mk

PROGNAME = TFX


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER) fpsp040 fpsp060

$(WHDLOADER) : $(SOURCE) chip_reloc_new.i native_fpu_sites.i native_math.i
	$(WDATE)
	vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -nosym -Fhunkexe -o $(WHDLOADER) $(SOURCE)

#fp.s: big.asm
#	mit2mot.py --optimize --noincludes --showduplabels big.asm fp.s

fpsp040: fp040.s code040.s fpsp.defs
	vasmm68k_mot -maxerrors=0 -devpac -nosym -Fhunkexe -o fpsp040 code040.s

fpsp060: code060.s fskel060_mot.s os_simple.s
	vasmm68k_mot -maxerrors=0 -devpac -nosym -Fhunkexe -o fpsp060 code060.s

