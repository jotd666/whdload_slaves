PROGNAME = BodyBlowsGalactic

all: $(PROGNAME)ECS.slave $(PROGNAME)AGA.slave $(PROGNAME).islave

$(PROGNAME)ECS.slave: BBGalacticECSHD.asm BBUtil.asm
	basm BBGalacticECSHD.asm

$(PROGNAME)AGA.slave: BBGalacticAGAHD.asm BBUtil.asm
	basm BBGalacticAGAHD.asm

$(PROGNAME).islave: BBGalactic.islave.s
	basm $?
