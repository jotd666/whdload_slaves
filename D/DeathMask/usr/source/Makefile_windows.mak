include ../../options.mk

PROGNAME = DeathMask


 
SOURCE = $(PROGNAME)HD.s
OPTS = -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)/Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(PROGNAME)ECS.slave $(PROGNAME)CD32.slave

$(PROGNAME)ECS.slave : $(SOURCE)
	$(WDATE)
	vasmm68k_mot $(OPTS) -o $(PROGNAME)ECS.slave $(SOURCE)
	vasmm68k_mot -DAGA $(OPTS) -o $(PROGNAME)AGA.slave $(SOURCE)
$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.s
	$(WDATE)
	vasmm68k_mot $(OPTS) -o $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
