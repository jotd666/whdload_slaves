#added by python script

PROGNAME = EnchantedLand
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad

SOURCE = $(PROGNAME)HD.s
OPTS = -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(PROGNAME).slave

$(PROGNAME).slave : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot $(OPTS) -o $(PROGNAME).slave $(SOURCE)
	