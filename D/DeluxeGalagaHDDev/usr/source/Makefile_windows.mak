#added by python script

PROGNAME = DeluxeGalaga
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad

SOURCE = $(PROGNAME)HD.s
OPTS = -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave

$(PROGNAME)AGA.slave : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot -D_AGA $(OPTS) -o $(PROGNAME)AGA.slave $(SOURCE)
	
$(PROGNAME)ECS.slave : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot $(OPTS) -o $(PROGNAME)ECS.slave $(SOURCE)
