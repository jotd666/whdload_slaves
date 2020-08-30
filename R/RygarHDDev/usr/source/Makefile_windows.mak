#added by python script

PROGNAME = Rygar
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad
SOURCE = $(PROGNAME)HD.s

all :  $(PROGNAME).slave $(PROGNAME)_2MB.slave

$(PROGNAME)_2MB.slave : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot -DCHIP_ONLY -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(PROGNAME)_2MB.slave $(SOURCE)

$(PROGNAME).slave : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(PROGNAME).slave $(SOURCE)
