#added by python script

PROGNAME = QuasarWars

HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o

all :  $(PROGNAME).slave
#$(PROGNAME).slave

$(PROGNAME).slave: $(PROGNAME)HD.s
	wdate.py> datetime
	$(CMD) $(PROGNAME).slave $(PROGNAME)HD.s
