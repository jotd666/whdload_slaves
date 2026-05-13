;*---------------------------------------------------------------------------
;  :Program.	CoolSpot.asm
;  :Contents.	Slave for "Cool Spot" from Virgin
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	26.02.98
;				24.04.29 Arisefromdecay: Added trainer, virgin logo skip
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i

	IFD BARFLY
	OUTPUT	HD2:util/dev/whdload/coolspot/CoolSpot.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;======================================================================
basemem	=$80000


	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM
	
_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_EmulTrap|WHDLF_NoError	;ws_flags
		dc.l	basemem
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5F		;ws_keyexit = Help
_expmem	dc.l	$80000
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_crc
		dc.w	_config-_base		;ws_config

_name		dc.b	"Cool Spot"
		dc.b	0
_copy		dc.b	"1990 Virgin",0
_info		dc.b	"adapted by Mr.Larmer/Wanted Team & JOTD",10,10
			dc.b	"Trainer added by Arise from Decay",10,10
            dc.b	"Version "
			DECL_VERSION
			dc.b	10,10
			dc.b	"Ingame keys:",10
			dc.b	"L: Toggle Lives",10
			dc.b	"E: Toggle Energy",10
			dc.b	"T: Toggle Time",10
			dc.b	"I: Toggle Invulnerability",10
;			 dc.b	 "O: Open Exit",10
			dc.b	"HELP: Complete Level",10
			dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
		dc.b	$A,$D,0
		
_config
	dc.b	"C1:B:Ingame Keys;"
	dc.b	"C2:X:Unlimited Time:0;"
	dc.b	"C2:X:Unlimited Energy:1;"
	dc.b	"C2:X:Unlimited Lives:2;"
	dc.b	"C5:B:Skip Virgin logo;"
	dc.b	0
	
	even



;======================================================================
start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		Lea	$40000,A0
		MOVE.l	#2*512,D0
		MOVE.l	#9*512,D1
		moveq	#1,d2
		bsr.w	_LoadDisk
		
		move.l	_expmem(pc),-4(A0)			; ext mem
		
		move.w	#$601E,$30(A0)			; skip drive on

		move.w	#$4EF9,$17E(A0)
		pea	Load(pc)
		move.l	(A7)+,$180(A0)

		move.l	#$4E714EF9,$E16(A0)
		pea	Patch1(pc)
		move.l	(A7)+,$E1A(A0)

		moveq	#1,D4
		
		bsr	_flushcache
		
		jmp	(A0)

;--------------------------------

Patch1
		
		jsr	$1282.w

		move.w	#$600C,$1CA8.w		; skip set int. vectors
		move.w	#$6016,$1CC6.w

		move.l	#$600008C8,$2E04.w	; skip copylock

		move.w	#$7A00,$36DA.w		; set copylock ID = 0
		move.w	#$6002,$36DC.w

		move.w	#$6002,$B98C		; access fault (bset #$1F,D0)

		move.w	#$4EF9,$AE7C
		pea	mask_int_6(pc)
		move.l	(A7)+,$AE7E

		move.l	#$4E714EB9,$7A34
		pea	kb_routine(pc)
		move.l	(A7)+,$7A38

;		 move.w	 #$4ef9,$17ac 		 ;skip virgin
;		 move.w	 #$17b2,$17b0
		
;		move.w	#-1,$390B8	; cheat on (keys)
		bsr.w	_Patchgame
		bsr	_flushcache

		jmp	$1500.w

; avoids crashes on CD32
mask_int_6
	move.w	#$2000,$DFF09C
	btst.b	#0,$BFDD00		; acknowledge CIA-B Timer A interrupt
	RTE

kb_routine:
	not.b	d0
	move.b	d0,($11A,A5)	; stolen
	cmp.b	_keyexit(pc),d0
	bne.b	.noquit

	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit
	tst.b	$c0
	beq		.notrainerkeys
	cmp.b	#$14,d0			;check t key
	bne	.noT
	eor.b  #$19,$d754 		;subq <-> tst

.noT
	cmp.b	#$12,d0 		;check e key
	bne	.noE
	eori.b	#$db,$108a4 	;subq <-> tst

.noE	
	cmp.b	#$28,d0			;check l key
	bne	.noL
	eor.b  #$19,$7868		;subq <-> tst
	eor.b  #$19,$7912

.noL
	cmp.b  #$17,d0			;check i key
	bne	.noI
	eori.b	#6,$10850		;subq <-> tst
	eori.b	#6,$10886



.noI
	cmp.b	#$5f,d0			;check help key (code stolen from Stingrays 100% trainer. RIP Stingray)
	bne	.noHELP
;	 move.w	 #$0ff,$dff180
	move.w	#$64,($3911a)	;100% cool
	move.w	($390d0),d0
	addq.w	#1,d0
	cmpi.w	#$11,d0
	bcs.b	.1
	moveq	#0,d0
	move.w	#$ffff,$3912a
.1	move.w	d0,($390d0)
	move.w	#$ffff,$39034   ;FFFF -> lvl done


.noHELP
;	 cmp.b	 #$18,d0		 ;check o key
;	 bne .noO
;	 move.w #$f0f,$dff180
;	 move.w #$ffff,$390ca	 ;FFFF -> enough collected

.noO	rts

.notrainerkeys rts

;--------------------------------
pl_trainer
	PL_START
	PL_IFC1
	PL_B		$C0,$FF
	PL_ELSE
	PL_B		$C0,$00
	PL_ENDIF
	PL_IFC2X 0
	PL_NOPS		$d754,2		;Unlimited Time
	PL_ENDIF
	PL_IFC2X 1
	PL_NOPS		$108a4,2	;Unlimited Energy
	PL_ENDIF
	PL_IFC2X 2
	PL_NOPS		$7868,2		;Unlimited Lives
	PL_NOPS		$7012,2
	PL_ENDIF
	PL_NEXT		pl_skiplogo
	PL_END

pl_skiplogo
	PL_START
	PL_IFC5
	PL_S	$17ac,2
;	 PL_W	 $17ac,$4ef9
;	 PL_W	 $17b0,$17b2
	PL_ENDIF
	PL_END

Load
		movem.l	d0-a6,-(a7)

		moveq	#0,D0
		move.w	D1,D0
		mulu	#512,D0

		moveq	#0,D1
		move.w	D2,D1
		mulu	#512,D1

		moveq	#0,D2
		move.b	D4,D2

		cmp.b	#4,D2
		bne.b	.skip1

		moveq	#3,D2
.skip1
		bsr.w	_LoadDisk

		btst	#4,D3			; if must be decrunch
		beq.b	.skip

		move.l	A0,A1

		btst	#5,D3
		beq.b	.skip2

		move.l	A2,A1
.skip2
		jsr	$10A8.w			; decrunch
.skip
		movem.l	(A7)+,d0-a6

		moveq	#0,D0
		rts

;--------------------------------

_resload	dc.l	0		;address of resident loader

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts
_Patchgame  movem.l	d0-d1/a0-a2,-(a7)
		move.l _resload(pc),a2

		lea	pl_trainer(pc),a0
		lea $0,a1
		jsr	resload_Patch(a2)

		movem.l	(a7)+,d0-d1/a0-a2

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

;======================================================================

	END
