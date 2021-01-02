#added by python script

PROGNAME = Colonization
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE

SOURCE = $(PROGNAME)HD.s

all :  $(PROGNAME)AGA.slave

$(PROGNAME)AGA.slave : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(PROGNAME)ECS.slave $(SOURCE)
	vasmm68k_mot -DAGA -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(PROGNAME)AGA.slave $(SOURCE)
