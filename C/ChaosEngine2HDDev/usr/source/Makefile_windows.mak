#added by python script

PROGNAME = ChaosEngine2
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE
WHDLOADER_ECS = $(PROGNAME)ECS.slave
SOURCE_ECS = $(PROGNAME)ECSHD.s
WHDLOADER_AGA = $(PROGNAME)AGA.slave
SOURCE_AGA = $(PROGNAME)AGAHD.s

all :  $(WHDLOADER_AGA) $(WHDLOADER_ECS) 

$(WHDLOADER_ECS) : $(SOURCE_ECS) shared.s
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(WHDLOADER_ECS) $(SOURCE_ECS)
	vasmm68k_mot -DCHIP_ONLY -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(PROGNAME)ECS_1MB_chip.slave $(SOURCE_ECS)
$(WHDLOADER_AGA) : $(SOURCE_AGA) shared.s
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(WHDLOADER_AGA) $(SOURCE_AGA)
