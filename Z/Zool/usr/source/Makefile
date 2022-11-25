all : ZoolAGA.slave ZoolAF.slave ZoolECS.slave ZoolCD32.slave zool.islave

ZoolAGA.slave: zoolagahd.asm
	basm $?

ZoolAF.slave: zoolafHD.asm
	basm zoolafHD.asm

ZoolECS.slave: ZoolECSHD.asm
	basm $?

ZoolCD32.slave: zoolcd32hd.asm
	basm $?

fungusdec.bin: fungusdec.asm
	phxass  fungusdec.asm TO fungusdec.bin

zool.islave: zool.islave.s
	basm $?
