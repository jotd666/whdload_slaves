#added by python script

PROGNAME = Oscar
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE

CMD = vasmm68k_mot
OPTS =  -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o

all :  $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave

$(PROGNAME)AGA.slave: $(PROGNAME)HD.s
	wdate.py> datetime
	$(CMD) -DAGA_VERSION $(OPTS) $(PROGNAME)AGA.slave $(PROGNAME)HD.s

$(PROGNAME)ECS.slave: $(PROGNAME)HD.s
	wdate.py> datetime
	$(CMD) $(OPTS) $(PROGNAME)ECS.slave $(PROGNAME)HD.s

