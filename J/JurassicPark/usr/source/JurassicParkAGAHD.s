;*---------------------------------------------------------------------------
;  :Program.	JurassicPark.asm
;  :Contents.	Slave for "Jurassic Park" from Ocean
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	05.07.98
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i

	IFD	BARFLY
	OUTPUT	JurassicPark.slave
	OPT	O+ OG+			;enable optimizing
	ENDC
	
;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ReqAGA|WHDLF_Req68020	;ws_flags
		dc.l	$200000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$58		;ws_keydebug = F9
_keyexit	dc.b	$59		;ws_keyexit = F10
_expmem		
	dc.l	0			;ws_ExpMem

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
		
_data   dc.b    0
_name	dc.b	'Jurassic Park AGA',0
_copy	dc.b	'1994 Ocean',0
_info
    dc.b   'by Mr.Larmer/Wanted Team/Psygore/JOTD',10,10
	dc.b	"Version "
	DECL_VERSION
	dc.b	0
	
_config
        dc.b    "C1:X:Trainer Infinite Lives & Ammo:0;"
		dc.b	0

	dc.b	'$VER: Jurassic Park AGA HD by Mr.Larmer/Wanted Team/JOTD - '
	DECL_VERSION
	dc.b	0
	CNOP 0,2

;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

;		move.l	a0,a2
;		moveq	#CACRF_EnableI,d1
;		move.l	d0,d1
;		jsr	(resload_SetCACR,a2)

		lea	$FE.w,A0
		move.l	A0,USP

;		move.l	#$1268CCB5,$C0.w	; bootblock checksum

;		move.l	D3,-$FC(A3)		; D3=$11C A3=$100
;		move.l	#$11C,4.w		; this code is used in RNC/2
						; decruncher in bootblock
						
		; enable caches, ripped from Psygore slave
;		MOVE.L	#$0000393e,D0		;086: 203c0000393e
;		MOVE.L	#$00007f3f,D1		;08c: 223c00007f3f
;		MOVEA.L	(_resload,PC),A2	;092: 247a0368
;		jsr	resload_SetCPU(a2)

		; enable cache in chipmem, damn game only uses chip...
		move.l  #WCPUF_Base_WT|WCPUF_IC|WCPUF_DC,d0
		move.l  #WCPUF_Base|WCPUF_IC|WCPUF_DC,d1
		move.l  (_resload,pc),a2
		jsr     (resload_SetCPU,a2)
		

		lea	Tags(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)

		
		move.l	_monitor(pc),D0
		cmp.l	#PAL_MONITOR_ID,D0
		beq.b	.skip

		clr.l	-(A7)
		clr.l	-(A7)
		move.l	#TDREASON_MUSTPAL,-(A7)
		jmp	resload_Abort(a2)
.skip
		lea	Name(pc),A0
		lea	$12000,A1
		move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)

		lea	$12400,A0
		lea	$100.w,A1
		cmp.w	#$1268,-$3FC(A0)
		bne.b	next
		jsr	-$400+$B2(A0)		;jsr	$120B2
		bra.b	go
next
		jsr	-$400+$BA(A0)		;jsr	$120BA
go
		move.w	_attn(pc),$12C.w	;attn flags

		move.w	#$4EB9,$15E.w
		pea	ClearCache(pc)
		move.l	(A7)+,$160.w

		pea	Patch1(pc)
		move.l	(A7)+,$212.w

		move.w	#1,$61E.w		; disk nr

		pea	Patch2(pc)
		move.l	(A7)+,$738.w

		move.w	#$4EB9,$7F6.w
		pea	ClearCache(pc)
		move.l	(A7)+,$7F8.w

		move.w	#$4EF9,$926.w
		pea	Load(pc)
		move.l	(A7)+,$928.w

		move.w	#$4EF9,$D3A.w
		pea	Decrunch(pc)
		move.l	(A7)+,$D3C.w

		bsr	ClearCache
		jmp	$100.w

Name		dc.b	'disk.'
DiskNr		dc.b	'0',0
		even

Tags		dc.l	WHDLTAG_ATTNFLAGS_GET
		dc.w	0
_attn		dc.w	0
		dc.l	WHDLTAG_MONITOR_GET
_monitor
		dc.l	0
		dc.l	0

;--------------------------------

Patch1
		cmp.l	#$13400009,$15BD0
		bne.b	.not_intro

		move.l	#$33400008,$15BD0	; correct custom_audio_vol
		move.l	#$33400008,$15BF8

		bsr	ClearCache
		bra.w	.exit
.not_intro
		cmp.l	#$13400009,$15F28
		bne.b	.not_outro

		move.l	#$33400008,$15F28	; correct custom_audio_vol
		move.l	#$33400008,$15F50

		bsr	ClearCache
		bra.w	.exit
.not_outro
		cmp.l	#$10,$1208E		; if copylock
		bne.b	.not_menu

		move.w	#$4EF9,$12088
		pea	Copylock(pc)
		move.l	(A7)+,$1208A

		move.l	#$4E714EB9,$15A3C
		pea	CheckCopylock(pc)
		move.l	(A7)+,$15A40

		move.l	#$33400008,$1738A	; correct custom_audio_vol
		move.l	#$33400008,$173B2

		bsr	ClearCache
		bra.w	.exit
.not_menu
		cmp.l	#$10,$2428A		; if copylock
		bne.w	.not_2D


		movem.l	d0-d1/a0-a2,-(a7)
		lea	pl_2d(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr	(resload_Patch,a2)
		movem.l	(a7)+,d0-d1/a0-a2

		bra.w	.exit


.not_2D
		cmp.l	#$10,$27CA8		; if copylock
		bne.w	.not_3D

		movem.l	d0-d1/a0-a2,-(a7)
		lea	pl_3d(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr	(resload_Patch,a2)
		movem.l	(a7)+,d0-d1/a0-a2

.not_3D
.exit
		jmp	$12000
		
pl_2d:
	PL_START
	PL_IFC1
	PL_B	$1BB26,$4A		; lives
	;PL_B	$1D2FE,$4A		; laser
	PL_B	$1F514,$4A		; energy
	PL_B	$34018,$4A		; energy
	PL_B	$20912,$4A		; grenades
	PL_B	$37CA6,$4A		; ammo
	PL_ENDIF
	
	PL_W	$4AE86,$4E71	; skip memory clear
	PL_P	$24284,Copylock2
	PL_PS	$37BC6,AccessFault
	PL_L	$47728,$33400008	; correct custom_audio_vol
	PL_L	$47750,$33400008
	PL_END

pl_3d:
	PL_START
	PL_PSS	$1BB28,CheckCopylock3,2
	
	PL_L	$1DFAE,$4268000E	; clr.w $E -> clr.w $E(A0)
	PL_W	$1DFB2,$4E71
	PL_L	$1DFC4,$4268000E,	; clr.w $E -> clr.w $E(A0)
	PL_W	$1DFC8,$4E71

;		move.w	#$6002,$130F2		; check $4.w if <> $11C
	PL_B	$13744,$60		; check clear proc copylock 4
	PL_B	$1387C,$60,		; check clear proc copylock 4
;		move.b	#$60,$1A638		; check encoded copylock 4
;		move.w	#$4E71,$1AB6C		; check end of copylock 3
;		move.b	#$60,$1AF04		; check encoded copylock 4
	PL_B	$1AFCE,$60		; check decode copylock 4 proc
;		move.w	#$4E71,$1B032		; check $4.w if <> $11C
;		move.w	#$4E71,$1DFA4		; check end of copylock 3
	PL_B	$2DF66,$60	; check decode copylock 4 proc
;		move.w	#$6002,$2DF94		; check $4.w if <> $11C
	PL_W	$2E73E,$4E71		; skip decode copylock 4
	PL_P	$2E756,Copylock4
	PL_W	$2F080,$4E71		; skip clear copylock 4
	PL_W	$2F086,$4E71		; skip clear copylock 4
;		move.b	#$,$302AC		; check end of copylock 4
	PL_IFC1
	PL_W	$1DFEC,$6006  ; ammo
	PL_W	$22774,$6074		; energy
	PL_W	$22798,$4E71		; lives
	PL_ENDIF

	PL_P	$26138,Decrunch
	PL_P	$27CA2,Copylock3
	PL_L	$2A040,$33400008,	; correct custom_audio_vol
	PL_L	$2A068,$33400008
	PL_END
	
Copylock
		move.w	#$FFFF,(A2)
		move.l	#$A235617C,D0
		jmp	$12988
CheckCopylock
		move.l	#$487A000A,D3
		sub.l	#$23DF0000,D3
		rts
Copylock2
		move.w	#$FFFF,(A2)
		move.l	#$0D180CD9,D0
		jmp	$24B84
AccessFault
		lea	$1FF780,A0
		and.w	#$FF,D0
		rts
Copylock3
		move.w	#$FFFF,(A2)
		move.l	#$997C1E1F,D0
		jmp	$285A2
CheckCopylock3
		move.l	#$487A000A,D5
		add.l	#$23DF0000,D5
		add.l	#$00104AFC,D5
		add.l	#$48E7FFFF,D5
		lea	$10(A4),A4
		rts
Copylock4
		move.w	#$FFFF,(A2)
;		move.l	#$9926BE13,D0
;		jmp	$2F056
		jmp	$2F078

;--------------------------------

Patch2
		clr.w	$FE.w		; in game this area was clear by code used in copylock 1
					; move.l USP,A6
					; clr.w (A6)

		move.l	#$600008B0,$1E0082	; skip copylock
		bsr	ClearCache
		jmp	$1E0000

;--------------------------------

ClearCache
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_FlushCache(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

;--------------------------------

Decrunch
		movem.l	d1/a0-a2,-(a7)

		moveq	#0,D0
		cmp.l	#'RNC'<<8+1,(A0)
		bne.b	.skip

		move.l	_resload(pc),a2
		jsr	resload_Decrunch(a2)

;		tst.l	d0
;		bne.b	.skip

;.m	move.w	$DFF006,$DFF180
;	bra.b	.m
.skip
		movem.l	(a7)+,d1/a0-a2
		rts

;--------------------------------

Load
		movem.l	d0-d2/a0-a1,-(a7)

		move.l	A0,A1

		sub.w	#$18,D1
		mulu	#512,D1

		moveq	#0,D0
		move.w	D2,D0
		mulu	#512,D0

		lea	DiskNr(pc),A0
		moveq	#0,D2
		move.w	$61E.w,D2
		add.b	#$30,D2
		move.b	D2,(A0)

		lea	Name(pc),A0

		bsr.b	_LoadDisk

		movem.l	(A7)+,d0-d2/a0-a1

		moveq	#0,D0
		rts

;--------------------------------

_resload	dc.l	0		;address of resident loader

;--------------------------------
; IN:	d0=size d1=offset a0=name a1=address
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_LoadFileOffset(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

;======================================================================

	END
