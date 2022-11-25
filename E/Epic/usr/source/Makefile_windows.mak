#added by python script

PROGNAME = Epic
HDBASE = K:\jff\AmigaHD
WHDBASE = $(HDBASE)\PROJETS\HDInstall\DONE
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
OPTS = -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(WHDLOADER) 
#Epic_Kick.slave

$(WHDLOADER) : $(SOURCE)
	wdate.py> datetime
	vasmm68k_mot $(OPTS) -o $(WHDLOADER) $(SOURCE)
	vasmm68k_mot -DONEMEG_CHIP $(OPTS) -o Epic_1MB.slave $(SOURCE)

Epic_Kick.slave : Epic_Kick_hd.s
	wdate.py> datetime
	vasmm68k_mot $(OPTS) -o Epic_Kick.slave Epic_Kick_hd.s

