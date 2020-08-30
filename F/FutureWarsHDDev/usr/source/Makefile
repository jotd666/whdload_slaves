PROGNAME = FutureWars

all : $(PROGNAME).slave
# $(PROGNAME)HD 

$(PROGNAME)HD : $(PROGNAME)HD.asm
	phxass $(PROGNAME)HD.asm I=include:

$(PROGNAME).slave: $(PROGNAME)HD.asm
	basm $(PROGNAME)HD.asm
