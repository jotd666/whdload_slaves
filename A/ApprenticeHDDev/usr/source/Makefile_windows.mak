PROGNAME = Apprentice
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE
 
SOURCE = $(PROGNAME)HD.s
OPTS = -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)/whdload/Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(PROGNAME).slave $(PROGNAME).islave

$(PROGNAME).slave : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot $(OPTS) -o $(PROGNAME).slave $(SOURCE)

$(PROGNAME).islave : $(PROGNAME).islave.s
	vasmm68k_mot $(OPTS) -o $(PROGNAME).islave $(PROGNAME).islave.s
