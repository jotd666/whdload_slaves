#added by python script

PROGNAME = NickFaldosGolf
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE
WHDLOADER = $(PROGNAME).slave
WHDLOADERCD = $(PROGNAME)CD32.slave
SOURCE = $(PROGNAME)HD.s
SOURCECD = $(PROGNAME)CD32HD.s

all :  $(WHDLOADER) $(WHDLOADERCD)

$(WHDLOADER) : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(WHDLOADER) $(SOURCE)
$(WHDLOADERCD) : $(SOURCECD)
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(WHDLOADERCD) $(SOURCECD)
