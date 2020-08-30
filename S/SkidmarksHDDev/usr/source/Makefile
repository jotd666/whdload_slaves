PROJECT = Skidmarks

all : $(PROJECT).islave $(PROJECT)AGA.slave $(PROJECT)ECS.slave 

$(PROJECT)AGA.slave: $(PROJECT)AGAHD.asm $(PROJECT)XXXHD.asm
	basm $(PROJECT)AGAHD.asm 
$(PROJECT)ECS.slave: $(PROJECT)ECSHD.asm $(PROJECT)XXXHD.asm
	basm $(PROJECT)ECSHD.asm 

$(PROJECT).islave: $(PROJECT).islave.s
	basm $?

