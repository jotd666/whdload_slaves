
	IFD	BARFLY
	OUTPUT	"XP8AGA.slave"
	ENDC


CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $80000
AGAVER = 1
	include	"XP8HD.asm"

_patch_exe:
	; game not protected

	rts
