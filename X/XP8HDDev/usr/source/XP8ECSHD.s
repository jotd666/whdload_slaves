
	IFD	BARFLY
	OUTPUT	"XP8ECS.slave"
	ENDC


CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	include	"XP8HD.asm"

_patch_exe:
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1
	lea	_pl_main(pc),a0
	jsr	resload_Patch(a2)
	rts

_pl_main:
	PL_START
	PL_B	$167E,$60	; manual protection
	PL_B	$A60E,$60	; manual protection
	PL_END	
