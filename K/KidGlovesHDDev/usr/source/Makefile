GAMENAME = KidGloves

all : $(GAMENAME).slave $(GAMENAME).islave


$(GAMENAME).slave: $(GAMENAME)HD.asm
	basm $?

$(GAMENAME).islave: $(GAMENAME).islave.s
	basm $?

clean:; rm -f *.slave *.islave
