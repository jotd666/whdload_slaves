PROGNAME = BeyondDarkCastle
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
WHDBASE = K:\jff\AmigaHD\PROJETS\WHDLoad
all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -I$(WHDBASE)\Include -phxass -nosym -Fhunkexe -o $(WHDLOADER) $(SOURCE)
