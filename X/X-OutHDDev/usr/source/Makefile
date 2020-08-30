all : X-Out.slave X-OutBudget.slave X-Out.islave

X-Out.slave: XoutHD.asm
	basm XoutHD.asm

X-OutBudget.slave: XoutBHD.asm
	basm XoutBHD.asm


X-Out.islave: X-Out.islave.s
	basm $<
