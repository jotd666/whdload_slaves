#added by python script

PROGNAME = Dune
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE\WHDLoad
WHDLOADER = $(PROGNAME).slave
WHDLOADERFLOP = $(PROGNAME)_floppy.slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER) $(WHDLOADERFLOP)

$(WHDLOADERFLOP) : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot -DFLOPPY_VERSION -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(WHDLOADERFLOP) $(SOURCE)
$(WHDLOADER) : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(WHDLOADER) $(SOURCE)
