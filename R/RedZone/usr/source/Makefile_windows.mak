#added by python script

PROGNAME = RedZone
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE
WHDLOADER = $(PROGNAME).slave
ISLAVE = $(PROGNAME).islave
SOURCE = $(PROGNAME)HD.s
EXE = data/object

all :  $(WHDLOADER) $(ISLAVE) $(EXE)
ASM = vasmm68k_mot -maxerrors=0 -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o 

$(WHDLOADER) : $(SOURCE) relocated_code.s
	wdate.py> datetime
	$(ASM) $(WHDLOADER) $(SOURCE)
$(ISLAVE) : $(PROGNAME).islave.s
#wdate.py> datetime
	$(ASM) $(ISLAVE) $(PROGNAME).islave.s

$(EXE) : object.s
	vasmm68k_mot -no-opt -maxerrors=0 -nosym -kick1hunks -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe -o $(EXE) object.s

