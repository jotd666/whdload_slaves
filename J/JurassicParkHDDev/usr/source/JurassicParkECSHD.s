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
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	JurassicPark.slave
	OPT	O+ OG+			;enable optimizing
	ENDC
	
;CHIP_ONLY = 1

; supports SPS 48 (ECS)

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
        IFD CHIP_ONLY
		dc.l	$100000		;ws_BaseMemSize
        ELSE
        dc.l    $80000
        ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	Start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
		dc.b	0		;ws_keydebug = F9
_keyexit	dc.b	$59		;ws_keyexit = F10
_expmem		
        IFD CHIP_ONLY
		dc.l	$0
        ELSE
        dc.l    $80000
        ENDC

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
	dc.b	"1.6"
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
_name	dc.b	'Jurassic Park ECS',0
_copy	dc.b	'1994 Ocean',0
_info
    dc.b   'by Mr.Larmer/Wanted Team & JOTD',10,10
	dc.b	"Version "
	DECL_VERSION
	dc.b	0
	
_config
        dc.b    "C1:X:Trainer Infinite Lives & Ammo:0;"
		dc.b	0

	dc.b	'$VER: Jurassic Park ECS HD by Mr.Larmer/Wanted Team/JOTD - '
	DECL_VERSION
	dc.b	0
	CNOP 0,2

; A500 config
; 0000012E 00C00000 00080000

expansion_memory_base = $12E

;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		moveq	#CACRF_EnableI,d1
		move.l	d1,d0
		jsr	resload_SetCACR(a0)

		lea	$FE.w,A0
		move.l	A0,USP

;		move.l	#$1268CCB5,$C0.w	; bootblock checksum

;		move.l	D3,-$FC(A3)		; D3=$11C A3=$100
;		move.l	#$F7,4.w		; this code is used in RNC/2
						; decruncher in bootblock
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
;		cmp.w	#$1268,-$3FC(A0)
;		bne.b	next
;		jsr	-$400+$B2(A0)		;jsr	$120B2
;		bra.b	go
;next
		jsr	-$400+$C2(A0)		;jsr	$120C2
;go
		; memory configuration
		
		move.w	_attn(pc),$12C.w	;attn flags
        IFD CHIP_ONLY
		clr.l	expansion_memory_base			; start expansion mem
		move.l	#$100000,$132.w		; expansion mem size
		
        lea _expmem(pc),a0
        move.l  #$80000,(a0)
        ELSE
		; using fast memory
        move.l  _expmem(pc),expansion_memory_base
        move.l  #$80000,$132.W
        ENDC
		

		lea		pl_boot(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr		resload_Patch(a2)
		
		jmp	$100.w

pl_boot:
		PL_START
		PL_PS	$18A,ClearCache
		PL_PSS	$24A,jump_7c00,2
		PL_PS	$6D6,Patch2
		PL_W	$5E2,1	; disk nr

		PL_P	$8CE,Load

		PL_P   $CE2,Decrunch
		PL_END


Name		dc.b	'Jurassic.d'
DiskNr		dc.b	'0',0
		even

jump_7c00
	MOVE.W	A5,$118.W
	bra		Patch1

quit:
		move.l	_resload(pc),a2
		move.l	#TDREASON_OK,-(A7)
		jmp	resload_Abort(a2)

kbint
	not.b	d0
	cmp.b	_keyexit(pc),d0
	beq	quit

	not.b	d0
	bset	#6,($E00,A0)
	rts
	
Tags		dc.l	WHDLTAG_ATTNFLAGS_GET
		dc.w	0
_attn		dc.w	0
		dc.l	WHDLTAG_MONITOR_GET
_monitor
		dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
_trainer
		dc.l	0
		dc.l	0

;--------------------------------
patchkb
	movem.l	d0/a0-a1,-(a7)
	lea	.addrs(pc),a0
.loop
	move.l	(a0)+,d0
	beq.b	.exit
	move.l	d0,a1
	cmp.l	#$08E80006,(a1)
	bne.b	.loop
	; patch kb
	pea	kbint(pc)
	move.w	#$4EB9,(a1)+
	move.l	(a7)+,(a1)
.exit
	movem.l	(a7)+,d0/a0-a1
	rts
	
.addrs
	dc.l	$9662,$9DC0,$9B84,$9E4A,0   ; $807DE in game
	
Patch1
		bsr	patchkb
		
		cmp.l	#$13400009,$B370
		bne.b	.not_intro

		movem.l	d0-d1/a0-a2,-(a7)
		lea		pl_intro(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr		resload_Patch(a2)
		movem.l	(a7)+,d0-d1/a0-a2
	
		bra.w	.exit
.not_intro
		cmp.l	#$13400009,$B0E6
		bne.b	.not_outro

		movem.l	d0-d1/a0-a2,-(a7)
		lea		pl_outro(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr		resload_Patch(a2)
		movem.l	(a7)+,d0-d1/a0-a2


		bra.w	.exit
.not_outro
		cmp.l	#$10,$7C9A.w		; if copylock
		bne.b	.not_menu

		movem.l	d0-d1/a0-a2,-(a7)
		lea		pl_menu(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr		resload_Patch(a2)
		movem.l	(a7)+,d0-d1/a0-a2

		bra.w	.exit
.not_menu
	
		cmp.w	#$4EF9,$7C8A.w	; if jmp ($80000/expansion)
		bne.w	.not_2D

		; relocate 2D part
		
		MOVE.W	D0,-(A7)		;7c00: 3f00
		MOVE.L	expansion_memory_base,D0		;7c02: 20390000012e
		BNE.W	.lb0000		;7c08: 66000008
		; no expansion: 1MB chip, select $80000 as "expansion"
		MOVE.L	#$00080000,D0		;7c0c: 203c00080000
.lb0000:
		; clear this expansion memory
		MOVEA.L	D0,A0			;7c12: 2040
		MOVE.L	#$00020000,D0		;7c14: 203c00020000
.lb0001:
		CLR.L	(A0)+			;7c1a: 4298
		SUBQ.L	#1,D0			;7c1c: 5380
		BNE.W	.lb0001		;7c1e: 6600fffa
		
		; exactly the same code to load expansion OR $80000 in A0
		MOVEA.L	expansion_memory_base,A0		;7c22: 20790000012e
		MOVE.L	A0,D0			;7c28: 2008
		TST.L	D0			;7c2a: 4a80
		BNE.W	.lb0002		;7c2c: 66000008
		LEA	$80000,A0		;7c30: 41f900080000
.lb0002:
		; copy some code there
		LEA	$db94,A1		;7c36: 43f90000
		MOVE.L	#$0000cf32,D1		;7c3c: 223c0000cf32
.lb0003:
		MOVE.L	(A1)+,(A0)+		;7c42: 20d9
		SUBQ.L	#1,D1			;7c44: 5381
		BNE.W	.lb0003		;7c46: 6600fffa
		TST.L	expansion_memory_base		;7c4a: 4ab90000012e
		BEQ.W	.lb0006		;7c50: 67000036
		
		; there is some expansion mem
		MOVE.L	expansion_memory_base,D1		;7c54: 22390000012e
		SUBI.L	#$00080000,D1		;7c5a: 048100080000
		; JOTD: removed this: we relocate with full address
		; not just upper 16 bits
		;SWAP	D1			;7c60: 4841
		MOVEA.L	expansion_memory_base,A0		;7c62: 20790000012e
		; correct addresses (reloc table)
		LEA	$7c90.W,A1		;7c68: 43f900007c90	; reloc table
.lb0004:
		MOVE.L	(A1)+,D0		;7c6e: 2019
		BMI.W	.lb0005		;7c70: 6b00000c
		ADD.L	A0,D0			;7c74: d088
		MOVEA.L	D0,A2			;7c76: 2440
		; JOTD: now reloc with full address, not just upper 16 bit part
		; which allows to use unaligned expansion memory
		ADD.L	D1,(A2)			;7c78: d352
		BRA.W	.lb0004		;7c7a: 6000fff2
.lb0005:
		MOVEA.L	expansion_memory_base,A0		;7c7e: 20790000012e
		MOVE.W	(A7)+,D0		;7c84: 301f
		bra.b	.patch_2d
.lb0006:
		MOVE.W	(A7)+,D0		;7c88: 301f
		lea		$80000,a0
.patch_2d
		movem.l	d0-d1/a0-a2,-(a7)
		move.l  a0,a1			; expansion
		move.l  _resload(pc),a2
		lea pl_2d(pc),a0
		jsr resload_Patch(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		jmp	(a0)
		
		
.not_2D
		cmp.l	#$10,$16546		; if copylock
		bne.w	.not_3D

		move.l	#$4E714EB9,$B788
		pea	CheckCopylock3(pc)
		move.l	(A7)+,$B78C

		move.l	#$4268000E,$CEC2	; clr.w $E -> clr.w $E(A0)
		move.w	#$4E71,$CEC6
		move.l	#$4268000E,$CED8	; clr.w $E -> clr.w $E(A0)
		move.w	#$4E71,$CEDC

		move.b	#$60,$935E		; check clear proc copylock 4
		move.b	#$60,$9496		; check clear proc copylock 4
		move.b	#$60,$A356		; skip check load proc
		move.w	#$4E71,$AA8A		; skip check load proc
		move.b	#$60,$ABAA		; check decode copylock 4 proc
		move.b	#$60,$1CAB0		; check decode copylock 4 proc
		move.w	#$4E71,$1D286		; skip decode copylock 4
		move.w	#$4EF9,$1D29E
		pea	Copylock4a(pc)
		move.l	(A7)+,$1D2A0
		move.w	#$4E71,$1DBC8		; skip clear copylock 4
		move.w	#$4E71,$1DBCE		; skip clear copylock 4

		movem.l	d0,-(a7)
		move.l	_trainer(pc),d0
		beq.b	.skip
		move.w	#$6006,$CF00		; ammo
		move.w	#$6072,$10462		; energy
		move.w	#$4E71,$10484		; lives
.skip
		movem.l	(a7)+,d0

		move.w	#$4EF9,$14996
		pea	Decrunch(pc)
		move.l	(A7)+,$14998

		move.w	#$4EF9,$16540
		pea	Copylock3(pc)
		move.l	(A7)+,$16542

		move.l	#$33400008,$18B72	; correct custom_audio_vol
		move.l	#$33400008,$18B9A
.not_3D
.exit
		jmp	$7C00.w
		


pl_menu
	PL_START
	PL_P	$7C94,Copylock
	PL_PSS	$A034,CheckCopylock,2

	PL_L	$B98C,$33400008	; correct custom_audio_vol
	PL_L	$B9B4,$33400008	
	PL_END
	
pl_intro:
	PL_START
	PL_L	$B370,$33400008	; correct custom_audio_vol
	PL_L	$B398,$33400008
	PL_END
	
pl_outro:
	PL_START
	PL_L	$B0E6,$33400008	; correct custom_audio_vol
	PL_L	$B10E,$33400008
	PL_END
	
pl_2d
    PL_START
	PL_PS	$007DE,kbint
		
    PL_IFC1
	PL_B  $07FDC,$4A		; lives
;	PL_B  $093DC,$4A		; laser
	PL_B  $0B61A,$4A		; energy
	PL_B  $1E9CA,$4A		; energy
	PL_B  $0CA50,$4A		; grenades
	PL_B  $1898C,$4A		; ammo
    PL_ENDIF
    
	PL_R	$19336		; avoid check for mem above C80000
	
    PL_B    $07F20,$60   ; skip check jsr (A0) which run copylock

    PL_PS   $22F32,Copylock4

    PL_L    $30418,$33400008   ; correct custom_audio_vol
    PL_L    $30440,$33400008

    PL_END
    
Copylock
		move.w	#$FFFF,(A2)
		move.l	#$A235617C,D0
		jmp	$8594
CheckCopylock
		move.l	#$487A000A,D3
		sub.l	#$23DF0000,D3
		rts
;Copylock2
;		move.w	#$FFFF,(A2)
;		move.l	#$0D180CD9,D0
;		jmp	$24B84
Copylock3
		move.w	#$FFFF,(A2)
		move.l	#$997C1E1F,D0
		jmp	$16E40
CheckCopylock3
		move.l	#$487A000A,D5
		add.l	#$23DF0000,D5
		add.l	#$00104AFC,D5
		add.l	#$48E7FFFF,D5
		lea	$10(A4),A4
		rts
Copylock4
		move.w	#$FFFF,(A2)
		move.l	#$9926BE13,D0
		rts
Copylock4a
		move.w	#$FFFF,(A2)
		jmp	$1DBC0

;--------------------------------

Patch2
		clr.w	$FE.w		; in game this area was clear by code used in copylock 1
					; move.l USP,A6
					; clr.w (A6)

		move.l	#$600008C4,$71082	; skip copylock

		jmp	$71000

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
		move.w	$5E2.w,D2
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
