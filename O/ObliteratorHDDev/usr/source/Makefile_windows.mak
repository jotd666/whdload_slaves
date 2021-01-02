#added by python script

PROGNAME = Obliterator
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
OPTS = -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)/Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(WHDLOADER) $(PROGNAME).islave

$(WHDLOADER) : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot $(OPTS) -o $(WHDLOADER) $(SOURCE)
$(PROGNAME).islave: $(PROGNAME).islave.s
	wdate.py> datetime
	vasmm68k_mot $(OPTS) -o $(PROGNAME).islave $(PROGNAME).islave.s
