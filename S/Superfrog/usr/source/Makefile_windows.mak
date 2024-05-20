PROGNAME = Superfrog
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
CMD = vasmm68k_mot -DDATETIME -I../../WHDLoad -IK:/jff/AmigaHD/amiga39_JFF_OS/include -devpac -nosym -Fhunkexe 

all :  $(PROGNAME).slave $(PROGNAME)CD32.slave

$(PROGNAME).slave : $(PROGNAME)HD.s
	$(WDATE)
	$(CMD) -o $(PROGNAME).slave $(PROGNAME)HD.s
	
$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.s
	$(WDATE)
	$(CMD) -o $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
