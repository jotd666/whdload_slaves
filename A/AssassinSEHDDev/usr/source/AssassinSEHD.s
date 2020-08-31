;*---------------------------------------------------------------------------
;  :Program.	AssassinSE.asm
;  :Contents.	Slave for "Assassin Special Edition" from Team 17
;  :Author.	Mr.Larmer of Wanted Team, Bored Seal
;  :History.	06.10.1997 - first release
;               08.10.2000 - slave optimized for WHDLoad V10+
;                          - fixed serious compatibility bug
;                          - RNC decrunchers use internal WHD function now
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

		INCDIR	Include:
		INCLUDE	whdload.i

	IFD BARFLY
	OUTPUT	"AssassinSE.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC


	IFD	DEBUG
CHIPMEMSIZE=$100000
EXPMEMSIZE=$0000
	ELSE
CHIPMEMSIZE=$80000
EXPMEMSIZE=$80000
	ENDC
	
_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem ;memory has to be cleared or game will cause access faults
		dc.l	CHIPMEMSIZE			;ws_BaseMemSize
		dc.l	0
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	0			;ws_keyexit = F10
_expmem		
		dc.l	EXPMEMSIZE			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC
DECL_VERSION:MACRO
	dc.b	"2.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
_name		dc.b	"Assasin (Special Edition)"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
_copy		dc.b	"1993 Team 17",0
_info		dc.b	"installed & fixed by Mr.Larmer/Bored Seal",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
_config:
        dc.b    "C1:X:enable N=levelskip W=weapons power-up:0;"
        dc.b    "C2:X:Trainer Infinite energy and time:0;"
		dc.b	0
	even

_Start		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		moveq.l #0,d0
		move.l	d0,d3

		moveq	#$b,d1
		moveq	#$b,d2
		lea	$78000,a0
		bsr	LoadRNCTracks

		move.w	#$4ef9,d0
		move.w	d0,$2D2(a0)
		pea	LoadRNCTracks
		move.l	(sp)+,$2D4(a0)

		move.w	d0,$A48(a0)
		pea	LoadRNCTracks2
		move.l	(sp)+,$A4A(a0)

		move.l	#$4EF800C0,$C2(a0)
		move.w	d0,$C0
		pea	Patch(pc)
		move.l	(sp)+,$C2

		bsr	get_expmem
		jmp	$30(a0)

Patch		move.l	#$4e714ef9,d0
		move.l	d0,$4154
		pea	Patch2
		move.l	(sp)+,$4158

		move.w	#$6006,$4B7C		;NMI disabled

		move.w	d0,$5484
		pea	LoadRNCTracks
		move.l	(sp)+,$5486

		move.w	d0,$5bfa
		pea	LoadRNCTracks2
		move.l	(sp)+,$5bfc

		move.w	d0,$600e
		pea	Decrunch
		move.l	(sp)+,$6100

		move.w	#$4eb9,$4140
		pea	Decrunch2
		move.l	(sp)+,$4142

		jmp	$4000

get_expmem:

	move.l	_expmem(pc),d0
	bne.b	.exp
	moveq	#8,D0
	swap	D0	
.exp
	rts
	
Patch2		
		movem.l	d0-a2,-(a7)
		bsr	get_expmem
		move.l	d0,a3
		lea	pl_main(pc),a0
		move.l	a3,a1
		move.l	_resload(pc),a2
		jsr	(resload_Patch,a2)
		movem.l	(a7)+,d0-A2
		jmp	(a3)

pl_main:
	PL_START
	PL_W	$234C,$6006		; NMI disabled
	PL_W	$1AFB2,$6002		; display txt
	PL_W	$1Afca,$6002		; wait for joy
	PL_W	$1Affa,$6002		; check save disk
	PL_L	$1B00C,'high'
	PL_W	$1B080,$6002		; display txt
	PL_W	$1B098,$6002		; wait for joy
	PL_L	$1B0A6,$60000086	; skip format save disk
	PL_P	$1BBDA,LoadRNCTracks
	PL_P	$1C356,LoadRNCTracks2
	PL_P	$1C76a,Decrunch
	PL_PSS	$2638,check_quit,2
	PL_IFC1
	PL_NOPS	$1A522,2
	PL_ENDIF
	PL_IFC2
	PL_B	$279A,1	; enables level skip too
	PL_ENDIF
	
	PL_END

check_quit:
	cmp.b	_keyexit(pc),d0
	beq.b	.quit
	btst	#0,$BFED01
	rts
.quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
LoadRNCTracks	movem.l	d0-a6,-(sp)
		move.l	d0,d5		;saveunit
		cmp.l	#'high',D3	;if load_hs command
		beq.w	_loadhighs
		btst	#0,D3		;if save or format
		bne.w	_savehighs
		moveq	#0,D0		;offset
		move.w	D1,D0
		mulu.w	#$200,D0

Load_Sub	moveq	#0,D1		;size
		move.w	D2,D1
		mulu.w	#$200,D1
		add.l	#1,d5		;disknumber
		move.l	d5,d2
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(sp)+,d0-a6
		moveq	#0,D0
		rts

LoadRNCTracks2	movem.l	d0-a6,-(sp)
		move.l	d0,d5			;save unit
		moveq	#0,D0			;offset
		move.w	D1,D0
		mulu.w	#$200,D0
		sub.l	#$400,D0
		bra	Load_Sub

_loadhighs	move.l	a0,-(sp)
		lea	_savename(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		tst.l	d0
		beq	_image
		move.l	(sp)+,a1		;address
		lea	_savename(pc),a0	;filename
		jsr	resload_LoadFile(a2)
		bra	OK

_image		addq.l	#4,sp
		movem.l	(sp)+,d0-a6
		addq.l	#4,sp
		moveq	#0,D0
		jmp	$9B04C

_savehighs	move.l	#$B6,d0			;len
		lea	(A0),a1			;address
		lea	_savename(pc),a0	;filename
		move.l	_resload(pc),a2
		jsr	resload_SaveFile(a2)
OK		movem.l	(sp)+,d0-a6
		moveq	#0,D0
		rts

Decrunch2	move.l	a0,a1
Decrunch	movem.l	a0-a6/d0-d7,-(sp)
		move.l	(_resload,pc),a2
		jsr	(resload_Decrunch,a2)
		movem.l	(sp)+,a0-a6/d0-d7
		rts

_resload	dc.l	0
_savename	dc.b	"highs",0