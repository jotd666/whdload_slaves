PROGNAME = Wonderdog
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
W\PROJETS\WHDLoad
all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE)\Src\sources\whdload -phxass -nosym -Fhunkexe -o $(WHDLOADER) $(SOURCE)
