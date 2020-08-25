#added by python script

PROGNAME = Deliverance
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
OPTS =  -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe
CMD = vasmm68k_mot
all :  $(WHDLOADER) $(PROGNAME)_512chip.slave

$(WHDLOADER): $(SOURCE)
	wdate.py> datetime
	$(CMD) $(OPTS) -o $(WHDLOADER) $(SOURCE)

$(PROGNAME)_512chip.slave: $(SOURCE)
	$(CMD) -DUSE_FASTMEM $(OPTS) -o $(PROGNAME)_512chip.slave $(SOURCE)
