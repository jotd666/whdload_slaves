; Body Blows Galactic loader by Jff
;
; Assembled with Barfly

	INCDIR	Include:
	INCLUDE	exec/execbase.i
	INCLUDE	devices/trackdisk.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	BodyBlowsGalacticAGA.slave
	ENDC

; USE_FASTMEM does not work because main program
; relies on expansion memory being at $180000
; even with some reloc efforts I could not fix it damn!

;;USE_FASTMEM

	IFD	USE_FASTMEM
CHIPMEMSIZE = $1FF000
FASTMEMSIZE = $80000
	ELSE
CHIPMEMSIZE = $1FF000
FASTMEMSIZE = $0
	ENDC

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
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem|WHDLF_ReqAGA
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

_name		dc.b	"Body Blows Galactic AGA",0
_copy		dc.b	"1994 Team 17",0
_info		dc.b	"installed  by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

		even


BASE_ADDRESS = $10000

_Start	
	lea	CHIPMEMSIZE-$100,A7

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
	move.l	a0,a2			;A2 = resload


	; sets cache in chip memory to speedup the game

	IFND	USE_FASTMEM
	move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)
	ENDC

	bsr	_loadboot
	lea	$dff000,a6
	jmp	BASE_ADDRESS



_loadboot:
	; version check & load the boot in BASE_ADDRESS

	lea	BASE_ADDRESS,a0
	move.l	#$e0c00,D0
	move.l	#$400,d1
	moveq.l	#1,d2
	jsr	(resload_DiskLoad,a2)

	lea	BASE_ADDRESS,A0
	move.l	#$400,D0
	jsr	(resload_CRC16,a2)
	cmp.w	#$4ADB,D0	; CAPS ID 440
	bne	_wrongver

	lea	BASE_ADDRESS,a0
	move.l	#$1800,D0
	move.l	#$400,d1	; length
	moveq.l	#1,d2
	jsr	(resload_DiskLoad,a2)

	lea	BASE_ADDRESS,A0
	move.l	#$400,D0
	jsr	(resload_CRC16,a2)
	cmp.w	#$9D26,D0	; AGA v1 & v2
	bne	_wrongver

	lea	BASE_ADDRESS,a1
	lea	pl_boot(pc),a0
	jsr	(resload_Patch,a2)

	rts

version
	dc.l	0

_patch_2b000:
	movem.l	d0-d1/a0-a2,-(a7)
	lea	$2B000,a1
	lea	pl_2b000(pc),a0
	move.l	_resload(pc),a2

	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	$2B000


_patch_70000:
	movem.l	d0-a6,-(a7)

	lea	$70000,A0
	move.l	#$400,D0	; offset
	move.l	#$1C00,D1	; length
	moveq.l	#1,D2		; disk 1

	move.l	_resload(pc),a2
	jsr	(resload_DiskLoad,a2)

	pea	_patch_main(pc)
	move.l	(a7)+,$BC.W

	lea	$70000,a1
	lea	pl_70000(pc),a0
	jsr	resload_Patch(a2)
	
	movem.l	(a7)+,d0-a6
	JMP	$70020

_patch_main:
	movem.l	d0-a6,-(a7)

	IFD	USE_FASTMEM
	move.l	a0,a1
	lea	$180000,a2

	move.l	a0,d0
	sub.l	a2,d0
.loop
	move.l	(a1)+,(a2)+
	cmp.l	#$1FF000,a2
	bne.b	.loop

	; copperlist relocation in chipmem

	sub.l	d0,$6DD2(a0)
	sub.l	d0,$6E08(a0)
	ENDC


	; *** A0 normally = $180000

	move.l	A0,A1
	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	movem.l	(a7)+,d0-a6
	jmp	(A0)

_jmp_7e000:
	IFD	USE_FASTMEM
	move.l	_expmem(pc),$7e024	; $180000 -> expmem
	ENDC

	bsr	_flushcache
	jmp	$7e000

get_expmem
	clr.l	$3F8	; useless anyway, game forces expmem at $180000 (argh!)
	add.l	#$22+$12,(A7)
	rts
	
; -----------------------------------------

pl_boot:
	PL_START
	PL_PS	$20,get_expmem
	PL_P	$A2,_patch_2b000
	PL_P	$26A,_decrunch
	PL_P	$3CA,_read_sectors
	PL_END

pl_2b000:
	PL_START
	PL_P	$1B96,_read_sectors
	PL_P	$1630,_read_nothing
	PL_P	$14A2,_decrunch
	PL_P	$162A,_patch_70000
	PL_END


pl_70000:
	PL_START
	PL_P	$286,_read_sectors
	PL_P	$10E,_decrunch
	PL_P	$50,_jmp_7e000
	PL_W	$F6,$4E4F
	PL_END

pl_main:
	PL_START
	PL_P	$FAAA,_read_sectors
	PL_PS	$BA,_kbint
	PL_P	$6F5C,_decrunch	
	PL_END

	include	"BBUtil.asm"
