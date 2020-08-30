all : Blastar.slave

BlastarHD : blastarhd.asm
	phxass blastarhd.asm I=include:

Blastar.slave: blastarhd.asm
	basm blastarhd.asm
