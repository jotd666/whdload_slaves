include ../../options.mk

PROGNAME = TowerOfSouls


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER) usr/install_hack_english usr/install_hack_german

usr/install_hack_english: install_hack_english.s
	vasmm68k_mot -I$(HDBASE)/amiga39_JFF_OS/include -devpac -nosym -Fhunkexe -o usr/install_hack_english install_hack_english.s
usr/install_hack_german: install_hack_german.s
	vasmm68k_mot -I$(HDBASE)/amiga39_JFF_OS/include -devpac -nosym -Fhunkexe -o usr/install_hack_german install_hack_german.s

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
