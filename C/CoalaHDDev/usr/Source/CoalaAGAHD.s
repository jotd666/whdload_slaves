; enable AGA at bootearly time
INITAGA
;;DEBUG
CHIPMEMSIZE	= $200000
	IFD	DEBUG
FASTMEMSIZE	= $0
	ELSE
FASTMEMSIZE	= $80000
BLACKSCREEN
	ENDC
	
	include	"CoalaHD.s"

	IFD	BARFLY
	OUTPUT	"CoalaAGA.slave"
	ENDC
