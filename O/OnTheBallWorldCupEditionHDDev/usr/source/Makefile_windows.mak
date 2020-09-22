#added by python script

PROGNAME = OnTheBallWCE
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad

CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe 

all :  $(PROGNAME)ECS.slave $(PROGNAME)AGA.slave

$(PROGNAME)ECS.slave : $(PROGNAME)HD.s
	wdate.py> datetime
	$(CMD) -o $(PROGNAME)ECS.slave $(PROGNAME)HD.s
    
$(PROGNAME)AGA.slave : $(PROGNAME)HD.s
	wdate.py> datetime
	$(CMD) -DAGA -o $(PROGNAME)AGA.slave $(PROGNAME)HD.s
