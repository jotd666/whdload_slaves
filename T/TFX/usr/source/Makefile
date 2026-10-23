include ../../options.mk

PROGNAME = TFX


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER) fpsp040 fpsp060

$(WHDLOADER) : $(SOURCE) chip_reloc_new.i native_fpu_sites.i native_math.i
	$(WDATE)
	vasmm68k_mot -DDATETIME -I$(HDBASE) -I$(WHDBASE)  -nosym -Fhunkexe -o $(PROGNAME)AGA.slave $(PROGNAME)HD.s

#fp.s: big.asm
#	mit2mot.py --optimize --noincludes --showduplabels big.asm fp.s

fpsp040: fp040.s code040.s fpsp.defs
	$(VASM_NOPIC) -maxerrors=0  -o fpsp040 code040.s

fpsp060: code060.s fskel060_mot.s os_simple.s
	$(VASM_NOPIC) -maxerrors=0  -o fpsp060 code060.s

