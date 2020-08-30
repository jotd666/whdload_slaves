PROJECT = PrinceOfPersia

all : $(PROJECT).slave $(PROJECT).islave

$(PROJECT).slave: $(PROJECT)HD.asm
	basm $?

$(PROJECT).islave: $(PROJECT).islave.s
	basm $?

