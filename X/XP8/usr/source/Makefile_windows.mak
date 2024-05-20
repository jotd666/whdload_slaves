include ../../options.mk

PROGNAME = XP8


SOURCE = $(PROGNAME)HD.s

CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  XP8AGA.slave XP8ECS.slave

XP8AGA.slave: $(SOURCE)
	$(WDATE)
	$(CMD) -DAGAVER -o XP8AGA.slave $(SOURCE)
XP8ECS.slave : $(SOURCE)
	$(WDATE)
	$(CMD)  -o XP8ECS.slave $(SOURCE)
