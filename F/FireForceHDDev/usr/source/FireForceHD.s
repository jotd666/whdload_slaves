		INCDIR	"Include:"
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i
		IFD	BARFLY
		BOPT	O+ OG+			;enable optimizing
		BOPT	ODd- ODe-		;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		SUPER				;disable supervisor warnings

		OUTPUT	FireForce.slave
		ENDC

_base		SLAVE_HEADER
		dc.w	17
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_EmulLineF
		dc.l	$100000
		dc.l	0
		dc.w	_Start-_base
		dc.w	dir-_base
		dc.w	0
_keydebug	dc.b	0
_keyexit	dc.b	$59
		dc.l	0
		dc.w	_name-_base
		dc.w	_copy-_base
		dc.w	_info-_base
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	slv_config-_base		;ws_config
slv_config
        dc.b    "C1:X:infinite energy:0;"
        dc.b    "C2:X:infinite ammo:0;"
        dc.b    "C3:X:infinite time:0;"
		dc.b	"BW;"
		dc.b	0

dir		dc.b	"data",0
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC
DECL_VERSION:MACRO
	dc.b	"1.2-B"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
_name		dc.b	"Fire Force",0
_copy		dc.b	"1992 ICE",0
_info		dc.b	"installed & fixed by Bored Seal & JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

_Start		lea	(_resload,pc),a1
		move.l	a0,(a1)
		move.l	a0,a2
                lea     (_tags,pc),a0
                jsr     (resload_Control,a2)

		lea	$1000,a0
		lea	filename-3(pc),a1
		bsr	LoadFile
		move.l	a0,a5

		lea	_pl_boot(pc),a0
		move.l	a5,a1
		jsr	resload_Patch(a2)

		jmp	$20(a5)

_pl_boot	PL_START
		PL_PS	$2cc+$20,SMC_Fix4	;patch self-modify code
		PL_PS	$322+$20,SMC_Fix4
		PL_PS	$2d8+$20,SMC_Fix5
		PL_PS	$32e+$20,SMC_Fix5
		PL_PA	$94+$20,PatchLauncher	; 10B2
		PL_END

PatchLauncher	lea	_pl_launcher(pc),a0
		bsr	patch_sub
		jmp	$7dd00

_pl_launcher	PL_START
		PL_PS	$7e1ac,LoadFile
		PL_R	$7e42e			;no disk access
		PL_PS	$7e97c,KBDelay		;fix kb handler
		PL_PS	$7de62,PatchIntro
		PL_PA	$7de74,PatchGame
		PL_P	$7ddaa,SMC_Fix1		;patch SMC
		PL_P	$7ddb6,SMC_Fix1
		PL_P	$7ddc2,SMC_Fix2
		PL_P	$7ddcc,SMC_Fix2
		PL_W	$7e40e,$4e71
		PL_PS	$7e410,SMC_Fix3
		PL_PS	$7dd5a,SMC_Fix6		;fix $2c handler SMC
		PL_END

PatchGame	
		bsr	PicWait		;wait with title picture


		bsr	LoadRoster

		lea	_pl_game(pc),a0
		bsr	patch_sub
		jmp	$d01c

check_quit:
	move.b	d1,$84.w
	cmp.b	_keyexit(pc),d1
	bne.b	.noquit

	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
.noquit
	cmp.b	#$60,D1	; original code
	rts
	
_pl_game	PL_START
		PL_PS	$13626,KBDelay		;fix kb handler
		PL_PSS	$13638,check_quit,2
		PL_L	$108a4,$70004e75	;no disk checks
		PL_W	$d0de,$6010		;don't test directory contents
		PL_W	$d126,$6028
		PL_PS	$fa04,SMC_Fix4
		PL_PS	$fa5a,SMC_Fix4
		PL_PS	$fa10,SMC_Fix5
		PL_PS	$fa66,SMC_Fix5
		PL_PS	$fdb6,SMC_Fix7		;fix SMC code in $2c handler
		PL_PS	$fefa,LoadFile
		PL_R	$104c6			;don't access disk
		PL_PS	$1114c,BlitFixD7A4
		PL_W	$138e6,$4e71		;insert delay for sound
		PL_PS	$138e8,BeamDelay
		PL_W	$13926,$4e71
		PL_PS	$13928,BeamDelay
		PL_P	$fa50,BeamDelay2
		PL_PA	$d2f2,PatchSave		;patch save subroutines

		PL_IFC1
		PL_W	$14214,$6002		;unlimited energy
		PL_W	$143fc,$6002
		PL_B	$14400,$60
		PL_W	$17494,$6002
		PL_W	$185d4,$6002
		PL_W	$19084,$6002
		PL_W	$1a3ee,$6002
		PL_W	$1a50a,$6002
		PL_ENDIF
		
		PL_IFC2
		PL_B	$16472,$4a		;unlimited ammo
		PL_B	$153ee,$4a
		PL_B	$1aec2,$4a
		PL_W	$da52,$4e71
		PL_ENDIF
		
		PL_IFC3
		PL_B	$1c55e,$4A
		PL_ENDIF
		
		PL_END

BeamDelay2	move.l	d0,-(sp)
		move.l	d6,d0
		divu	#$22,d0
		bsr	BM_1
		move.l	(sp)+,d0
		rts

PatchSave	jsr	$2fb8a
		move.w	#$4ef9,$7f02
		pea	LoadRoster(pc)
		move.l	(sp)+,$7f04

		move.w	#$4ef9,$80da
		pea	SaveRoster(pc)
		move.l	(sp)+,$80dc

		bsr	FlushCache
		rts

PatchIntro	move.w	#$4ef9,$65fa		;improved delay
		pea	IntroWait(pc)
		move.l	(sp)+,$65fc
		bsr	FlushCache
		jsr	(a1)
		lea	$7deca,a1
		rts

BlitFixD7A4	move.w	d7,$58(a4)
BlitWait	btst	#6,$dff002
		bne	BlitWait
		moveq	#0,d5
		rts

SMC_Fix1	move.w	#$4ef9,(a1)+
		move.l	a0,(a1)+
		bsr	FlushCache
		rts

SMC_Fix2	move.w	#$4e75,(a1)
		bra	FlushCache

SMC_Fix3	move.w	#$4e75,$7e3ee
		bra	FlushCache

SMC_Fix4	move.w	#$3000,2(a2)
		bra	FlushCache

SMC_Fix5	move.w	#$9999,2(a2)
		bra	FlushCache

SMC_Fix6	
			move.l	d0,$7dd68
			bra	FlushCache

SMC_Fix7	move.l	d0,$fdc6
			bra	FlushCache

FlushCache	move.l	a2,-(sp)
		move.l	(_resload,pc),a2
		jsr	(resload_FlushCache,a2)
		move.l	(sp)+,a2
		rts

LoadFile	movem.l	a0-a2/d1,-(sp)
		exg.l	a1,a0
		bsr	Name
		move.l	(_resload,pc),a2
		jsr	(resload_LoadFile,a2)
		movem.l	(sp)+,a0-a2/d1
		rts

Name	
		movem.l	d0,-(a7)
		lea	3(a0),a0		;skip subdirectories
		bsr	getlong
		cmp.l	#'FIRE',d0
		bne	next
		lea	5(a0),a0
next
		bsr	getlong
		cmp.l	#'STIR',D0
		bne	next2
		lea	9(a0),a0
next2	
		movem.l	(a7)+,d0
		rts

getlong
	move.b	(a0),d0
	lsl.l	#8,d0
	move.b	(1,a0),d0
	lsl.l	#8,d0
	move.b	(2,a0),d0
	lsl.l	#8,d0
	move.b	(3,a0),d0
	rts
	
IntroWait	move.l	#$282,d0
		bra	BM_1

BeamDelay	move.l	d0,-(sp)
		moveq	#7,d0
		bsr	BM_1
		move.l	(sp)+,d0
		rts

KBDelay		moveq	#1,d0
BM_1		move.w  d0,-(sp)
		move.b	$dff006,d0
BM_2		cmp.b	$dff006,d0
		beq	BM_2
		move.w	(sp)+,d0
		dbf	d0,BM_1
		rts

PicWait		movem.l	d0-d7/a0-a6,-(sp)
		lea	button(pc),a0
		tst.l	(a0)
		beq	ButtonPressed
		waitbutton
ButtonPressed	movem.l	(sp)+,d0-d7/a0-a6
		rts

LoadRoster	movem.l	d0-d7/a0-a6,-(sp)
		bsr	Params
                jsr     (resload_GetFileSize,a2)
                tst.l   d0
                beq     NoRoster
		bsr	Params
		jsr	(resload_LoadFile,a2)
NoRoster	movem.l	(sp)+,d0-d7/a0-a6
		rts

Params		lea	roster(pc),a0
		lea	$33bd4,a1
		move.l	(_resload,pc),a2
		rts

SaveRoster	movem.l	d0-d7/a0-a6,-(sp)
		bsr	Params
		move.l	#$214,d0
		jsr	(resload_SaveFile,a2)
		movem.l	(sp)+,d0-d7/a0-a6
		rts

patch_sub	movem.l	a0-a2,-(sp)
		suba.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)
		movem.l	(sp)+,a0-a2
		rts

_resload	dc.l	0
_tags		dc.l	WHDLTAG_BUTTONWAIT_GET
button		dc.l    0
		dc.l	0

filename	dc.b	"AMBOOT",0
roster		dc.b	"ROSTER",0
