#added by python script

PROGNAME = Zool
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(PROGNAME).slave $(PROGNAME)AGA.slave $(PROGNAME)CD32.slave

CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o 

$(PROGNAME).slave : $(SOURCE)
	wdate.py> datetime
	$(CMD) $(PROGNAME).slave $(SOURCE)
$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s
	wdate.py> datetime
	$(CMD) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.s lowlevel.s
	wdate.py> datetime
	$(CMD) $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
