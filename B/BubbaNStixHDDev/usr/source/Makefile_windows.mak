#added by python script

PROGNAME = BubbaNStix
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad

SOURCE = $(PROGNAME)HD.s

all :  $(PROGNAME).slave $(PROGNAME)CD32.slave

$(PROGNAME).slave : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(PROGNAME).slave $(SOURCE)
$(PROGNAME)CD32.slave : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot -DCD32 -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(PROGNAME)CD32.slave $(SOURCE)
