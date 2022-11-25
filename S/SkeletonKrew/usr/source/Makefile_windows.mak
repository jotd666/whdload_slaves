#added by python script

PROGNAME = SkeletonKrew
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o

all :  $(PROGNAME)CD32.slave $(PROGNAME)AGA.slave

$(PROGNAME)AGA.slave: $(PROGNAME)AGAHD.s
	wdate.py> datetime
	$(CMD) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
$(PROGNAME)CD32.slave: $(PROGNAME)CD32HD.s
	wdate.py> datetime
	$(CMD) $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
