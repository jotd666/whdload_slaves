PROGNAME = Coala

all : $(PROGNAME)AGA.slave $(PROGNAME)ECS.slave 

$(PROGNAME)AGA.slave : $(PROGNAME)HD.asm $(PROGNAME)AGAHD.asm 
	basm $(PROGNAME)AGAHD.asm

$(PROGNAME)ECS.slave : $(PROGNAME)HD.asm $(PROGNAME)ECSHD.asm 
	basm $(PROGNAME)ECSHD.asm 
