PROGNAME = QuestForGlory
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

ROOT = K:/jff/AmigaHD
all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) sierra_hdinit.s
	$(WDATE)
	vasmm68k_mot -DDATETIME -I$(ROOT)/amiga39_JFF_OS/include -I$(ROOT)\PROJETS\HDInstall\DONE\WHDLoad -I$(ROOT)\PROJETS\HDInstall\DONE\generic -devpac -nosym -Fhunkexe -o $(WHDLOADER) $(SOURCE)
