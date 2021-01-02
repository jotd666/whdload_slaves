#added by python script

PROGNAME = FantasticDizzy
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE

OPTS = -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :   $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s savegame.s
	wdate.py> datetime
	vasmm68k_mot $(OPTS) -o $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
    
$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.s
	wdate.py> datetime
	vasmm68k_mot $(OPTS) -o $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s
