include ../../options.mk

PROGNAME = ThemePark


WHDLOADER = $(PROGNAME).slave
CMD = $(VASM) -o

all: $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave $(PROGNAME)CD32.slave 
$(PROGNAME)AGA.slave : $(PROGNAME)AGAHD.s
	$(WDATE)
	$(CMD) $(PROGNAME)AGA.slave $(PROGNAME)AGAHD.s
    
$(PROGNAME)ECS.slave : $(PROGNAME)ECSHD.s
	$(WDATE)
	$(CMD) $(PROGNAME)ECS.slave $(PROGNAME)ECSHD.s
$(PROGNAME)CD32.slave : $(PROGNAME)CD32HD.s
	$(WDATE)
	$(CMD) $(PROGNAME)CD32.slave $(PROGNAME)CD32HD.s
