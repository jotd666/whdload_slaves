PROGNAME = CurseOfRa
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s


all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -phxass -nosym -Fhunkexe -o $(WHDLOADER) $(SOURCE)
