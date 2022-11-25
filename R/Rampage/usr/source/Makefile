all : Rampage.slave

rampagehd : rampagehd.asm
	phxass rampagehd.asm I=include:

Rampage.slave: rampagehd.asm
	basm rampagehd.asm
