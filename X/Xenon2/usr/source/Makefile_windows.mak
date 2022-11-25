PROGNAME = Xenon2
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
WHDBASE = K:\jff\AmigaHD\PROJETS\WHDLoad
all :  $(WHDLOADER) $(PROGNAME)CDTV.slave

$(WHDLOADER) : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE)\Src\sources\whdload -phxass -nosym -Fhunkexe -o $(WHDLOADER) $(SOURCE)

$(PROGNAME)CDTV.slave : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot -DCDTV -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE)\Src\sources\whdload -phxass -nosym -Fhunkexe -o $(PROGNAME)CDTV.slave $(SOURCE)
