PROGNAME = BubbleNSqueak
WHDBASE = K:\jff\AmigaHD\PROJETS\HDInstall\DONE\WHDLoad
SHARED = BubbleShared.s ReadJoyPad.s
CMD = vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -I$(WHDBASE) -phxass -nosym -Fhunkexe

all :  $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave

$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s $(SHARED)
	wdate.py> datetime
	$(CMD) -o $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.s $(SHARED)
	wdate.py> datetime
	$(CMD) -o $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s
