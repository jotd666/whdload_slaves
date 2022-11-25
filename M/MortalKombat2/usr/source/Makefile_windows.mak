#added by python script

PROGNAME = MortalKombat2
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE

SOURCE = $(PROGNAME)HD.s
OPTS = -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(PROGNAME).slave $(PROGNAME)_512k_chip.slave  

$(PROGNAME)_512k_chip.slave : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot -DHALF_MEG_CHIP $(OPTS) -o $(PROGNAME)_512k_chip.slave $(SOURCE)
$(PROGNAME).slave : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot -DONE_MEG_CHIP $(OPTS) -o $(PROGNAME).slave $(SOURCE)
