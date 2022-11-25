all : BlackTiger.slave

BlackTigerHD : BlackTigerHD.asm
	phxass BlackTigerHD.asm I=include:


BlackTiger.slave: BlackTigerHD.asm
	basm BlackTigerHD.asm
