#added by python script

PROGNAME = RiseOfTheRobots
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad
PREFIX = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o 


all : $(PROGNAME)AGA.slave $(PROGNAME)CD32.slave $(PROGNAME)ECS.slave

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s
	wdate.py> datetime
	$(PREFIX) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.s
	wdate.py> datetime
	$(PREFIX) $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s
$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.s
	wdate.py> datetime
	$(PREFIX) $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
