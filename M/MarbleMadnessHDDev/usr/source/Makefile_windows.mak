#added by python script

PROGNAME = MarbleMadness
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(WHDLOADER) $(PROGNAME)Image.slave

$(WHDLOADER) : $(SOURCE)
	wdate.py> datetime
	$(CMD) -o $(WHDLOADER) $(SOURCE)
$(PROGNAME)Image.slave : $(SOURCE)
	wdate.py> datetime
	$(CMD) -DDISKIMAGE -o $(PROGNAME)Image.slave $(SOURCE)
