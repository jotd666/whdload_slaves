PROGNAME = TowerOfSouls

all : $(PROGNAME).slave install_hack

$(PROGNAME).slave : $(PROGNAME)HD.asm
	basm $?

install_hack: install_hack.asm
	phxass OPT 0 $?
