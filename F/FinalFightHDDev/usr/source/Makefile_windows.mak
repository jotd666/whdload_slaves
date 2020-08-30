PROGNAME = FinalFight

SOURCE = $(PROGNAME)HD.s

all :  $(PROGNAME).slave  $(PROGNAME)_512.slave

$(PROGNAME).slave : $(SOURCE) $(PROGNAME)_512.slave
	wdate.py> datetime
	vasmm68k_mot -DONEMEG -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -IK:/jff\AmigaHD\PROJETS\HDInstall\DONE\WHDLoad -devpac -nosym -Fhunkexe -o  $(PROGNAME).slave $(SOURCE)
$(PROGNAME)_512.slave : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -IK:/jff\AmigaHD\PROJETS\HDInstall\DONE\WHDLoad -devpac -nosym -Fhunkexe -o  $(PROGNAME)_512.slave $(SOURCE)
