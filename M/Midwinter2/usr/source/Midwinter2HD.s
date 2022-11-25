;*---------------------------------------------------------------------------
;  :Program.	Midwinter2.asm
;  :Contents.	Slave for "Midwinter2"
;  :Author.	JOTD, from Wepl sources
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"Midwinter2.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $A0000
FASTMEMSIZE	= $80000
NUMDRIVES	= 4
;;WPDRIVES	= %1000	; df3: is not write protected. The others are
WPDRIVES	= %1010	; df0 & df2 are write protected (program & missions)

;BLACKSCREEN
DISKSONBOOT
;HDINIT
;MEMFREE	= $200
;NEEDFPU
;SETPATCH


;HRTMON
; for HRTMon display
; $DFF100 = $4200
; $DFF102 = 0
; $DFF104 = $30
; $DFF108 = $78
; $DFF10A = $78
;
; 3424a
;
;============================================================================

KICKSIZE	= $40000			;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	11			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv|WHDLF_NoDivZero	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_name		dc.b	"Midwinter 2 - Flames of Freedom",0
_copy		dc.b	"1991 Maelstrom Games",0
_info		dc.b	"adapted & fixed by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Set CUSTOM1=4 to 9 to select campaign disk.4-9",10,10
		dc.b	"Version 1.2 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	move.l	a0,a2

	;enable cache
	move.l	a0,-(A7)
	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)
		
	;get tags
	lea	_tag(pc),a0
	jsr	(resload_Control,a2)

	move.l	_custom1(pc),d0
	cmp.b	#3,d0
	bcs.b	.skip		; < 3: invalid
	lea	_trd_disk(pc),a1
	move.b	d0,3(a1)		; set disk
.skip
	move.l	(A7)+,a0

	;initialize kickstart and environment
	bra	_boot


; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	

	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0

	cmp.b	#'m',1(A0)
	bne.b	.skip
	cmp.b	#'w',2(A0)
	bne.b	.skip

	move.l	d1,a3	; segments
	bsr	_fixit

.skip
	rts

_fixit:
	lea	_trd_chg(pc),a0
	move.l	a0,$100.W

	; kickemu bug? 0 should be re-cleared

	clr.l	$0.W

	; patch the keyboard

	bsr	_patchkb

	move.b	_expmem(pc),d0
	btst	#7,d0
	beq.b	.skip
.af_on_purpose
	; expmem has 31-bit set: no way: trigger access fault
	; users will report it
	move.l	$12345678,d0
	move.l	$87654321,d0
.skip

	; lookup for a zeroed bit on expmem MSB to replace
	; the $1E (30) value that the game uses and which is
	; for instance incompatible with my expmem location ($79xxxxxx)

	move.l	#6,d1
.loop
	btst	d1,d0
	dbeq.b	d1,.loop

	tst.b	d1
	bmi.b	.af_on_purpose	; MSB is $7F: would be surprising

	add.b	#24,d1
	lea	_freebit(pc),a0
	move.b	d1,(a0)

	lea	_mask(pc),a0
	move.b	d0,(a0)		; store MSB of fastmem in mask

	bsr	_patch_exe

	rts

PATCH_BITOP:MACRO
	move.l	a1,a3
	add.l	#\1,a3
	move.b	_freebit(pc),5(a3)	
	ENDM

_patch_exe:
	move.l	a3,a1
	add.l	#$B086,a1
	cmp.w	#$84FC,$12(a1)
	beq.b	_patch_exe_uk
	cmp.w	#$66EE,(a1)
	beq.b	_patch_exe_defr
_wrong_ver
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

; german & french versions are VERY similar
	
_patch_exe_defr:
	add.l	#$10000,a1
	cmp.l	#$6B286726,(a1)
	beq.b	_patch_exe_fr
	cmp.l	#$002E6B28,(a1)
	beq.b	_patch_exe_de
	bra.b	_wrong_ver

_patch_exe_de:
	move.l	_resload(pc),a2
	move.l	a3,a1
	
	; swap some variables for the protection

	add.l	#$205E0-$28,a3
	subq.l	#4,(a3)
	addq.l	#4,6(a3)
	subq.l	#4,14(a3)
	addq.l	#4,20(a3)

	; change BSET, BTST #30 to a bit set to zero for expmem MSB
	; (else game will refuse to work with fast memory)

	PATCH_BITOP	$17BF8
	PATCH_BITOP	$17C6E
	PATCH_BITOP	$1BF9C
	PATCH_BITOP	$1C00C
	
	; rest of patch

	addq.l	#4,A1
	lea	_pl_main_de(pc),a0
	jsr	resload_Patch(a2)

	rts

_pl_main_de:
	PL_START

	; patch AND mask -> 32 bit access fault

	PL_PS	$1B094,_and_d1
	PL_PS	$1B10E,_and_d1
 
	PL_PS	$1B6C0,_and_d0
	PL_PS	$1C010,_and_d0
	PL_PS	$1C05A,_and_d0
	PL_PS	$2A4E6,_and_d0_2

	; remove identification protection (adapted from UK crack)

	PL_W	$205E4-$2C,$33C0
	PL_W	$205EA-$2C,$4E71
	PL_W	$205F2-$2C,$33C0
	PL_B	$205F8-$2C,$60

	PL_END

_patch_exe_fr:
	move.l	_resload(pc),a2
	move.l	a3,a1
	
	; swap some variables for the protection

	add.l	#$205DE-$28,a3
	subq.l	#4,(a3)
	addq.l	#4,6(a3)
	subq.l	#4,14(a3)
	addq.l	#4,20(a3)

	; change BSET, BTST #30 to a bit set to zero for expmem MSB
	; (else game will refuse to work with fast memory)

	PATCH_BITOP	$17BF6
	PATCH_BITOP	$17C6C
	PATCH_BITOP	$1BF9A
	PATCH_BITOP	$1C00A
	
	; rest of patch

	addq.l	#4,A1
	lea	_pl_main_fr(pc),a0
	jsr	resload_Patch(a2)

	rts

_pl_main_fr:
	PL_START

	; patch AND mask -> 32 bit access fault

	PL_PS	$1B092,_and_d1
	PL_PS	$1B10C,_and_d1
 
	PL_PS	$1B6BE,_and_d0
	PL_PS	$1C00E,_and_d0
	PL_PS	$1C058,_and_d0
	PL_PS	$2A4E4,_and_d0_2

	; remove identification protection (adapted from UK crack)

	PL_W	$205E2-$2C,$33C0
	PL_W	$205E8-$2C,$4E71
	PL_W	$205F0-$2C,$33C0
	PL_B	$205F6-$2C,$60

	PL_END

_patch_exe_uk:
	move.l	_resload(pc),a2
	move.l	a3,a1
	
	; swap some variables for the protection

	add.l	#$205A4-$28,a3
	subq.l	#4,(a3)
	addq.l	#4,6(a3)
	subq.l	#4,14(a3)
	addq.l	#4,20(a3)

	; change BSET, BTST #30 to a bit set to zero for expmem MSB
	; (else game will refuse to work with fast memory)

	PATCH_BITOP	$17BBC
	PATCH_BITOP	$17C32
	PATCH_BITOP	$1BF60
	PATCH_BITOP	$1BFD0
	
	; rest of patch

	addq.l	#4,A1
	lea	_pl_main_uk(pc),a0
	jsr	resload_Patch(a2)

	rts
	
; offset $4A-$1E = $2C
_pl_main_uk:
	PL_START
	; patch AND mask -> 32 bit access fault

	PL_PS	$1B058,_and_d1
	PL_PS	$1B0D2,_and_d1
 
	PL_PS	$1B684,_and_d0
	PL_PS	$1BFD4,_and_d0
	PL_PS	$1C01E,_and_d0
	PL_PS	$2A4A8,_and_d0_2

	; remove identification protection (Thanks Lockpick / Amigapatchlist)

	PL_W	$205A8-$2C,$33C0
	PL_W	$205AE-$2C,$4E71
	PL_W	$205B6-$2C,$33C0
	PL_B	$205BC-$2C,$60

	PL_END

_and_d0:
	and.l	_mask(pc),d0	; correct D0 value afterwards
	rts

_and_d0_2:
	and.l	_mask(pc),d0	; correct D0 value afterwards
	move.l	d1,-(A7)
	move.l	d0,d1
	rol.l	#8,d1
	cmp.b	_expmem(pc),d1
	beq.b	.ok
	clr.l	(a7)		: D1=0
	addq.l	#6,4(a7)	: skip some code
.ok
	move.l	(a7)+,d1
	rts

_and_d1:
	and.l	_mask(pc),d1	; correct D0 value afterwards
	rts

; MSB mask

_mask:
	dc.l	$FFFFFFFF

; position of a zero bit for expmem MSB

_freebit:
	dc.w	0

_patchkb
	lea	.ackkb(pc),A0
	lea	.oldkb(pc),A1
	move.l	$68.W,(A1)
	move.l	A0,$68.W
	rts

.ackkb:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	move.l	.oldkb(pc),-(A7)
	rts

.oldkb:
	dc.l	0

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	INCLUDE	kick13.s

;============================================================================

	END
