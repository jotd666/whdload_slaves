; Body Blows Galactic loader by Jff
;
; Assembled with Barfly

	INCDIR	Include:
	INCLUDE	exec/execbase.i
	INCLUDE	devices/trackdisk.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	BodyBlowsGalacticECS.slave
	ENDC

CHIPMEMSIZE = $80000
FASTMEMSIZE = $80000

; ----------

	IFD	BARFLY
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER				;disable supervisor warnings

	DOSCMD	"WDate  >T:date"


	ENDC


DECL_VERSION:MACRO
	incbin	slave_version
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	13			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
_expmem
		dc.l	FASTMEMSIZE		;ws_ExpMem

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

_name		dc.b	"Body Blows Galactic ECS",0
_copy		dc.b	"1993 Team 17",0
_info		dc.b	"installed by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

		even


_Start	
	lea	CHIPMEMSIZE-$100,A7

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
	move.l	a0,a2			;A2 = resload

	bsr	_loadboot
	lea	$dff000,a6
	jmp	$10000

_loadboot:
	; load the boot in $10000

	lea	$10000,a0
	move.l	#$1800,D0	; offset
	move.l	#$1000,d1	; length
	moveq.l	#1,d2
	jsr	(resload_DiskLoad,a2)

	lea	$10000,A0
	move.l	#$1000,D0
	jsr	(resload_CRC16,a2)
	cmp.w	#$848D,D0	; ECS
	bne	_wrongver

	lea	$10000,a1
	lea	_pl_boot(pc),a0
	jsr	(resload_Patch,a2)

	rts

STORE_WHDLOAD_REGS:MACRO
	movem.l	d0-d1/a0-a2,-(a7)
	ENDM

RESTORE_WHDLOAD_REGS:MACRO
	movem.l	(a7)+,d0-d1/a0-a2
	ENDM

_patch_2b000:
	STORE_WHDLOAD_REGS

	lea	$2B000,a1
	lea	_pl_2b000(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	RESTORE_WHDLOAD_REGS
	jmp	$2B000


_patch_2C608:
	lea	$9E8.W,A7

	STORE_WHDLOAD_REGS

	move.w	#$7FFF,$dff09a
	move.w	#$7FFF,$dff09c
	move.w	#$7FFF,$dff096

	move.l	_resload(pc),a2

	lea	$7e000-$56,a0
	move.l	#$400,D0	; offset
	move.l	#$1000,d1	; length
	moveq.l	#1,d2		; disk 1
	jsr	(resload_DiskLoad,a2)

	lea	_pl_7e000(pc),a0
	lea	$7e000,a1
	jsr	resload_Patch(a2)

	RESTORE_WHDLOAD_REGS
	jmp	$7e000

_ext_jump:
	STORE_WHDLOAD_REGS

	move.l	_expmem(pc),a1
	lea	_pl_ext(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	RESTORE_WHDLOAD_REGS

	move.l	$7E65C,a0
	jmp	(a0)			; jmp	ExtBase+$43F00

_get_extbase:
	move.l	_expmem(pc),d0
	rts

; -----------------------------------------

_pl_ext:
	PL_START
	PL_P	$52AA8,_read_sectors
	PL_P	$4A6E0,_decrunch
	PL_PS	$43F88,_kbint
	PL_END

_pl_7e000:
	PL_START
	PL_P	$238,_read_sectors
	PL_P	$C0,_decrunch
	PL_P	$A4,_ext_jump
	PL_END

_pl_boot:
	PL_START
	PL_PS	$20,_get_extbase
	PL_W	$26,$602C
	PL_P	$A2,_patch_2b000
	PL_P	$3CA,_read_sectors
	PL_P	$26A,_decrunch
	PL_END

_pl_2b000:
	PL_START
	PL_P	$1B96,_read_sectors
	PL_P	$1630,_read_nothing
	PL_P	$14A2,_decrunch
	PL_P	$1608,_patch_2C608
	PL_END

	include	"BBUtil.asm"
