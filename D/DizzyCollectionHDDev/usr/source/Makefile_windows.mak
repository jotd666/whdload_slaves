#added by python script

PROGNAME = Disk
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE

OPTS = -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)/WHDload/Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(PROGNAME)1.slave $(PROGNAME)2.slave 

$(PROGNAME)1.slave : $(PROGNAME)1HD.s
	wdate.py> datetime
	vasmm68k_mot $(OPTS) -o $(PROGNAME)1.slave $(PROGNAME)1HD.s
$(PROGNAME)2.slave : $(PROGNAME)2HD.s
	wdate.py> datetime
	vasmm68k_mot $(OPTS) -o $(PROGNAME)2.slave $(PROGNAME)2HD.s
