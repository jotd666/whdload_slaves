PROGNAME = Badlands
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -IK:\jff\AmigaHD\PROJETS\WHDLoad\Include -phxass -nosym -Fhunkexe -o $(WHDLOADER) $(SOURCE)
