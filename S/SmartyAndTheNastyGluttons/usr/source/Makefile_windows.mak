#added by python script

PROGNAME = SmartyAndTheNastyGluttons
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE

CMD = vasmm68k_mot
OPTS =  -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o

all :  $(PROGNAME).slave


$(PROGNAME).slave: $(PROGNAME)HD.s
	wdate.py> datetime
	$(CMD) $(OPTS) $(PROGNAME).slave $(PROGNAME)HD.s

