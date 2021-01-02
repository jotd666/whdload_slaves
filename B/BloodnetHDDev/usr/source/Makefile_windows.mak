#added by python script

PROGNAME = Bloodnet
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(PROGNAME)ECS.slave $(PROGNAME)AGA.slave

CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o

$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.s $(PROGNAME)Shared.s
	wdate.py> datetime
	$(CMD) $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s
    
$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s $(PROGNAME)Shared.s
	wdate.py> datetime
	$(CMD) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
