#added by python script

PROGNAME = BodyBlowsGalactic
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad
CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o

all :  $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s BBUtil.s
	wdate.py> datetime
	$(CMD) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s 
$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.s BBUtil.s
	wdate.py> datetime
	$(CMD) $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s 
