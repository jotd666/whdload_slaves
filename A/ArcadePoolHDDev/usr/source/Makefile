GAMENAME = ArcadePool


all : $(GAMENAME)AGA.slave $(GAMENAME)CD32.slave $(GAMENAME).islave $(GAMENAME)ECS.slave 


$(GAMENAME)AGA.slave: $(GAMENAME)AGAHD.asm $(GAMENAME)XXXHD.asm
	basm $(GAMENAME)AGAHD.asm

$(GAMENAME)ECS.slave: $(GAMENAME)ECSHD.asm $(GAMENAME)XXXHD.asm
	basm $(GAMENAME)ECSHD.asm

$(GAMENAME).islave: $(GAMENAME).islave.s
	basm $?

$(GAMENAME)CD32.slave: $(GAMENAME)CD32HD.asm
	basm $?

clean:; rm -f *.slave *.islave
