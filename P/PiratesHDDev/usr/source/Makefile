PROGNAME = Pirates
ECSSOURCE = $(PROGNAME)ECSHD.asm
ECSWHDLOADER = $(PROGNAME)ECS.slave
AGASOURCE = $(PROGNAME)CD32HD.asm
AGAWHDLOADER = $(PROGNAME)CD32.slave

all :  $(ECSWHDLOADER) $(AGAWHDLOADER)

$(ECSWHDLOADER) : $(ECSSOURCE)
	basm $?

$(AGAWHDLOADER) : $(AGASOURCE)
	basm $?

