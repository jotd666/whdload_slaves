include ../../options.mk

PROGNAME = OnTheBallWCE



CMD = vasmm68k_mot -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)\WHDLoad\Include -I$(WHDBASE) -devpac -nosym -Fhunkexe 

all :  $(PROGNAME)ECS.slave $(PROGNAME)AGA.slave

$(PROGNAME)ECS.slave : $(PROGNAME)HD.s
	$(WDATE)
	$(CMD) -o $(PROGNAME)ECS.slave $(PROGNAME)HD.s
    
$(PROGNAME)AGA.slave : $(PROGNAME)HD.s
	$(WDATE)
	$(CMD) -DAGA -o $(PROGNAME)AGA.slave $(PROGNAME)HD.s
