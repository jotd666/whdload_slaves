PROGNAME = MixedUpMotherGoose
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) sierra_hdinit.s
	$(WDATE)
	vasmm68k_mot -DDATETIME -IK:/jff/AmigaHD/amiga39_JFF_OS/include -IK:\jff\AmigaHD\PROJETS\HDInstall\DONE\WHDLoad -IK:\jff\AmigaHD\PROJETS\HDInstall\DONE\generic -devpac -nosym -Fhunkexe -o $(WHDLOADER) $(SOURCE)
