#added by python script

PROGNAME = FireAndIce
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o

all :  $(PROGNAME)CD32.slave $(PROGNAME).slave

$(PROGNAME).slave: $(PROGNAME)HD.s
	wdate.py> datetime
	$(CMD) $(PROGNAME).slave $(PROGNAME)HD.s
$(PROGNAME)CD32.slave: $(PROGNAME)CD32HD.s
	wdate.py> datetime
	$(CMD) $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
