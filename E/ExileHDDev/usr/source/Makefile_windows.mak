#added by python script

PROGNAME = Exile
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o

all :  $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave

$(PROGNAME)ECS.slave: $(PROGNAME)ECSHD.s
	wdate.py> datetime
	$(CMD) $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s
$(PROGNAME)CD32.slave: $(PROGNAME)CD32HD.s
	wdate.py> datetime
	$(CMD) $(PROGNAME)CD32.slave $(PROGNAME)AGAHD.s
$(PROGNAME)AGA.slave: $(PROGNAME)AGAHD.s
	wdate.py> datetime
	$(CMD) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
