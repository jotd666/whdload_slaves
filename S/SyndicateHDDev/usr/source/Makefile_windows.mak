#added by python script

PROGNAME = Syndicate
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all : $(PROGNAME)CD32.slave

$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.s
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
