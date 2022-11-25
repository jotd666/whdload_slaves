#added by python script

PROGNAME = ThemePark
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE
WHDLOADER = $(PROGNAME).slave
CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o

all: $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave $(PROGNAME)CD32.slave 
$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s
	wdate.py> datetime
	$(CMD) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
    
$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.s
	wdate.py> datetime
	$(CMD) $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s
$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.s
	wdate.py> datetime
	$(CMD) $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
