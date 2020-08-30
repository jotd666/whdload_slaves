GAME = FinalFight

all : $(GAME).slave

$(GAME)HD : $(GAME)hd.asm
	phxass $(GAME)hd.asm I=include:

$(GAME).slave: $(GAME)hd.asm
	basm $(GAME)hd.asm
