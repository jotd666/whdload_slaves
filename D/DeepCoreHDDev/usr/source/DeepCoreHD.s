;*---------------------------------------------------------------------------
;  :Program.	DeepCore.asm
;  :Contents.	Slave for "Deep Core" from ICE
;  :Author.	Mr.Larmer of Wanted Team / Wepl
;  :History.	12.03.2000
;		05.05.00 after several weeks hard work fixed for 060 (wepl)
;		18.08.00 now also second level works
;		15.06.09 blithog reenabled #2078
;			 blitter routine (_b2/3) made faster
;		28.06.09 no longer requires registered whdload
;			 blitter routine (_b2/3) not patched on 68020 and below
;			 cpu/video flags init fixed
;		30.07.09 intro sound finally fixed
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*


	IFD BARFLY

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	OUTPUT	"wart:d/deepcore/DeepCore.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER

	ELSE

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	OUTPUT	dh1:demos/DeepCore/DeepCore.slave
	OPT	O+ OG+			;enable optimizing

	ENDC

	IFD	CHIP_ONLY
CHIPMEMSIZE = $FF000
FASTMEMSIZE = $1000
	ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = $81000	
	ENDC
STACKOFFSET = FASTMEMSIZE
	
;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem	;ws_flags
_basemem	dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = none
_keyexit	dc.b	$5F		;ws_keyexit = Help
_expmem
		dc.l	FASTMEMSIZE		;ws_ExpMem
		dc.w	_name-_base	;ws_name
		dc.w	_copy-_base	;ws_copy
		dc.w	_info-_base	;ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
    dc.w    _config-_base
_config
	dc.b	"BW;"
	;dc.b    "C1:X:Boot on expansion disk:0;"
	dc.b    "C3:B:skip introduction;"
	dc.b    "C4:B:disable blitter fixes for slow machines;"
	dc.b	0

	IFD	BARFLY
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

_name	dc.b	'Deep Core'
		IFD		CHIP_ONLY
		dc.b	" (debug/chip mode)"
		ENDC
		
		dc.b	0
_copy	dc.b	'1993 ICE',0
_info	dc.b	'Installed and fixed by Mr.Larmer & Wepl',10
		dc.b	"Version "
		DECL_VERSION
	dc.b	-1,'Greetings to Chris Vella,',10
	dc.b	'Helmut Motzkau',10
	dc.b	'and Carlo Pirri',0
	CNOP 0,2
IGNORE_JOY_DIRECTIONS
IGNORE_JOY_PORT0
	include	ReadJoyPad.s

;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use
		move.l	a0,a2

		IFD		CHIP_ONLY
		lea		_expmem(pc),a0
		move.l	#$80000,(a0)		; fake expansion
		ENDC
		
		lea	_tags(pc),a0
		jsr	(resload_Control,a2)

		lea	$8000,A0
		moveq	#0,D0
		move.l	#$400,D1
		moveq	#1,d2
		bsr	_LoadDisk

		; some decryption
		lea	$52(a0),A1
		move.b	(A1)+,D0
		move.w	#$3B2,D1
loop	
		eor.b	D0,(A1)+
		addq.b	#3,D0
		rol.b	#5,D0
		dbra	D1,loop

		lea	$50000,A0
		move.l	#$400,D0
		move.l	#$1200,D1
		moveq	#1,d2
		bsr.w	_LoadDisk
		; more decryption
		pea	(a0)
		move.w	#$47F,d0
_not		not.l	(a0)+
		dbf	d0,_not

		moveq	#0,d0
		move.l	(_monitor,pc),d1
		cmp.l	#PAL_MONITOR_ID,d1
		beq.b	.setmon
		moveq	#1,d0
.setmon		move.w	d1,$8E.W		;vblank speed, pal=0 or ntsc=1

		move.l	#68000,d0
		move.l	(_attn,pc),d1
		btst	#AFB_68010,d1
		beq	.setcpu
		add.w	#30,d0
		;cpu type, affects blitter routines
		; which is probably not the best as in 2022 there
		; are 28MHz 68000s or equivalent and blitter needs
		; fixing there.
.setcpu		move.l	d0,$90.W		
		
		lea	_pl_50000(pc),a0
		move.l	(a7),a1
		jsr	(resload_Patch,a2)

		move.l	(a7)+,a0
		jmp	(6,a0)

_pl_50000	PL_START
		PL_S	$2e,4		;clr of bplcon0, scandoubler...
		PL_S	$32,8		;bplcon3,fmode
		PL_S	$3a,16		;skip set drive
		PL_P	$4e,.load
	;	PL_P	$cc,Load
		PL_END

.load		addq.l	#1,d1
		mulu	#$1998,d0
		mulu	#$1998,d1
		moveq	#1,d2
		bsr	_LoadDisk

		lea		($c6,a0),a0		; start of packed data
		LEA	$1f7c0,A1		;6000e: 43f9000

		bsr		unpack

		move.l	#-2,$60.W
		move.l	#$60,_custom+cop1lc

		movem.l	d0/a0,-(a7)
		moveq	#9,d0
		lea	$204c8,a0
.l		move.l	#$1800000,(a0)+
		dbf	d0,.l
		movem.l	(a7)+,d0/a0

	IFEQ 1
		movem.l	d0-d1/a1-a2,-(a7)
		move.l	#2,d0
		lea	$22528,a0
		move.l	_resload(pc),a2
		jsr	(resload_ProtectRead,a2)
		movem.l	(a7)+,_MOVEMREGS
	ENDC
	
		
		lea	_pl_1f7c0(pc),a0
		lea	$1f7c0,a1
		move.l	_resload(pc),a2
		jsr	(resload_Patch,a2)
		; skip stack, set stack in fastmem
		move.l	_skip_intro(pc),d0
		bne	_30000
		; jump to intro
		move.l	_expmem(pc),a7
		add.l	#STACKOFFSET,a7
		jmp		$1f876
		
_pl_1f7c0	PL_START
		PL_S	$d4,$16			; skip set drive
		PL_W	$22e,$3330		;wrong loading length (disk loader originally rounds up)
		PL_PS	$282,.f2
		PL_W	$61a,$200		;clr of bplcon0, scandoubler...
		PL_P	$618,_30000		; patch next part
		PL_PS	$868,.f1
		PL_PS	$908,.f6
		PL_W	$c00,color		;bplcon3
		PL_W	$c04,color		;fmode
		PL_R	$d5e			;strange clist modification
		PL_P	$2b92,.load
		PL_CW	$2d68			;copcon
		PL_PS	$301e,.f4
		PL_PS	$35f2,.f3


	;	PL_P	$a72,.fixwait
	;	PL_P	$2c2c,Load
	;	PL_AW	$ec,~DMAF_BLITHOG	;disable blitpri
	;	PL_BKPT	$2aa
	;	PL_S	$2aa,6			;bltcopy
	;	PL_S	$2ba,4			;setup sound
	;	PL_BKPT	$2f2			;decruncher
	;	PL_BKPT	$33a			;decruncher
	;	PL_BELL	$3d8,20

		PL_END

		
.load		movem.l	d0-d2/a0-a2,-(a7)
		mulu	#$1998,d0
		moveq	#1,d2
		bsr	_LoadDisk
		cmp.l	#$2e*$1998,d0
		bne	.load_q
		move.l	_buttonwait(pc),d0
		beq	.load_q
		move.l	#400,d0
		move.l	_resload(pc),a2
		jsr	(resload_Delay,a2)
.load_q		movem.l	(a7)+,_MOVEMREGS
		rts

	ifeq 1
.fixwait	mulu	#15,d0
.1		move.b	($dff006),d7
.2		cmp.b	($dff006),d7
		beq	.2
		dbf	d0,.1
		rts
	endc

.f1		bsr	_blitwait
		move.l	#$9f00000,$dff040
		addq.l	#4,(a7)
		rts
.f2		bsr	_blitwait
		move.l	#$25bc4,$50(a6)
		addq.l	#2,(a7)
		rts
.f3		bsr	_blitwait
		or.w	d2,d0
		move.l	d0,$40(a6)
		rts
.f4		bsr	_blitwait
		move.l	#0,$64(a6)
		addq.l	#2,(a7)
		rts
.f6		bsr	_blitwait
		move.l	#$1000000,$dff040
		addq.l	#4,(a7)
		rts

;--------------------------------

_30000	
		
		move.l	_expmem(pc),a7
		add.l	#STACKOFFSET,a7
		
		move.w	#$7FFF,$DFF09A

		movem.l	d0-d2/a0-a2,-(a7)

		lea	DiskNr(pc),a0
		move.b	#2,(a0)

		lea	$100.w,a0
		moveq	#0,d0
		bsr.w	Load

		movem.l	(a7)+,d0-d2/a0-a2

		lea		$1c6.w,a0
		lea		$7e000,a1
		bsr		unpack
		
		clr.w	-(a7)			; which disk drive
		move.l	a0,-(a7)

		move.l	#$60,_custom+cop1lc
		lea	$7E000,a1
		move.l	_expmem(pc),$97C(a1)
		move.l	a1,-(a7)
		lea		pl_7e000(pc),a0
		move.l	_resload(pc),a2
		jmp		(resload_Patch,a2)
		
pl_7e000
		PL_START
		PL_PS	$CA,Patch6
		PL_PS	$FC,Patch6
		PL_PS	$1D4,Patch6
		PL_PS	$232,Patch6
		
		PL_PS	$12C,Patch5
		PL_PS	$140,Patch5
		PL_PS	$17A,Patch5
		
		PL_R	$2B8		; remove check ext mem

		PL_W	$4BC,$600C	; skip set drive
		PL_W	$4DE,$6008

		PL_P	$55A,Load
		PL_P	$660,ChangeDisk

		PL_W	$9E,$6006	;bplcon3,fmode
		PL_W	$90e,color	;bplcon3
		PL_W    $91a,color	;fmode	

		PL_END

;--------------------------------

Patch5
		movem.l	d0-d1/a0-a2,-(a7)

		blitz
		
		move.w	#($2ca-$96)/4-1,d0
		lea	$25496,a0
.l2		move.l	#$1800000,(a0)+
		dbf	d0,.l2

		move.w	#($8a-$0a)/4-1,d0
		lea	$2570a,a0
.l3		move.l	#$1800000,(a0)+
		dbf	d0,.l3
		
		lea		pl_5(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr		resload_Patch(a2)

		movem.l	(a7)+,d0-d1/a0-a2

		move.l	#$60,$dff080

		jmp	$15780
		
pl_5:
		PL_START
		PL_PS	$17F50,HeadUp
		PL_PS	$17F68,HeadDown
		PL_P	$1E8BC,Head

		; skip calc checksum
		PL_W	$17272,$6002
		PL_B	$1A6F2,$60
		PL_B	$1E18C,$60
		PL_W	$25062,$6002
		PL_B	$25D60,$60

		PL_P	$25976,Load2
		
		; skip set drive
		PL_W	$25AE2,$601C
		PL_W	$25B24,$601A

		PL_P	$25B4A,Load3

	;	and.w	#~DMAF_BLITHOG,$22986 ;disable blitpri
	;	and.w	#~DMAF_BLITHOG,$22bf4 ;disable blitpri
	
		PL_W	$2537e,color
		PL_W	$25382,color

		PL_PS	$21d28,_b1
		PL_W	$15914,$6002			;movec cacr
		
		PL_PS	$21d8c,_f1
		PL_PS	$21bc8,_f2
		PL_PS	$21750,_f3
		PL_PS	$21514,_f1
		PL_PS	$215b6,_f1
		PL_PS	$21c9c,_f4
		PL_PS	$21cfc,_f5
		PL_PS	$23276,_f1
		PL_PS	$2201a,_f1
		PL_PS	$23028,_f6
		PL_PS	$230be,_f1
		PL_PS	$231ca,_f7
		PL_W	$15a6c,$200		;bplcon0
		PL_PS	$21e5a,_f5
		PL_PS	$21f46,_f5
		PL_PS	$21f9c,_f5
		
		PL_IFC4
		; don't patch anything
		PL_ELSE
		PL_R	$228b6			;creates blitter routines
		PL_P	$22a44,_b2
		PL_P	$229f4,_b3
		
		PL_ENDIF
		
		PL_END
		
		
	IFEQ 1
;PATCHCOUNT
;INTBLITCHECK
		lea	$15780,a0
		lea	$80000,a1
		lea	$100,a2
		bsr	_blitfix_dn_58a6
		lea	$15780,a0
		lea	$80000,a1
		bsr	_blitfix_imm_58a6
	ENDC

	;	move.w	#$6004,$15a20
	;	patchs	$15a26,_p1
	;	ill	$15a32
	;	ill	$15a36
	;	patchs	$15a84,_p2
	;	patch	$1ed3c,_p3
	;	patchs	$15aec,_p4


		
	IFEQ 1
	; debug code for checksums??
		movem.l	d0-d1/a1-a2,-(a7)
		move.l	#$94-$74,d0
		lea	$74,a0
		move.l	_resload(pc),a2
		jsr	(resload_ProtectWrite,a2)
		move.l	#$c0-$96,d0
		lea	$96,a0
		move.l	_resload(pc),a2
		jsr	(resload_ProtectWrite,a2)
		movem.l	(a7)+,_MOVEMREGS
	ENDC


_f2		bsr	_blitwait
		or.w	d5,d6
		move.l	d6,$40(a6)
		rts

_f3		bsr	_blitwait
		move.w	#$26,$66(a6)
		rts

_f4		and.w	#15,d5
		ror.w	#4,d5
		bra	_blitwait

_f5		or.w	d5,d6
		swap	d6
		or.w	d5,d6
		bra	_blitwait

_f6		bsr	_blitwait
		move.l	#$ffffffff,$44(a6)
		addq.l	#2,(a7)
		rts

_f7		or.l	#$fca0000,d0

_blitwait	BLITWAIT
		rts


_f1		bsr	_blitwait
		move.l	#$9f00000,$dff040
		addq.l	#2,(a7)
		rts

_b1		bsr	_blitwait
		move.l	(4,a7),(bltcon0,a6)		;snoop on 060
		move.l	(a7)+,(a7)
		addq.l	#6,(a7)
		rts

DELAY	MACRO
		BLITWAIT a6
	ENDM

_b2
.2		moveq	#$12,d6
.1		DELAY
		move.w	(a0)+,(a4)
		movem.w	d0-d1/d4,(a5)
		addq.w	#2,d1
		dbf	d6,.1
		DELAY
		move.w	(a0)+,(a4)
		movem.w	d0-d1/d4,(a5)
		add.w	d2,d1
		dbf	d7,.2
		rts

_b3		moveq	#11,d5
.2		moveq	#$13,d6
.1		DELAY
		move.w	(a0)+,(a4)
		movem.w	d0-d1/d4,(a5)
		addq.w	#2,d1
		dbf	d6,.1
		DELAY
		move.w	(a0)+,(a4)
		movem.w	d0-d1/d4,(a5)
		add.w	d2,d1
		add.l	d3,a0
		dbf	d5,.2
		rts


	IFEQ 1
_p1		waitvb	a6
		move.w	#$c018,intena(a6)
		rts

_p2	;	waitvb	a6
.l		move.l	4(a6),d0
		and.l	#$1ff00,d0
		cmp.l	#$03000,d0
		bne	.l
		clr.w	$22e26
		rts

_p3		clr.w	$22e22
.w		tst.w	$22e22
		beq	.w
		clr.w	$22e22
		rts

_p4
	move.l	d5,-(a7)
	move.l	#10000,d5
.ww	tst.b	$bfe001
	subq.l	#1,d5
	bne	.ww
	move.l	(a7)+,d5

		jmp	$1edc8
	ENDC

;--------------------------------

HeadUp
		move.l	a0,-(a7)
		lea	HeadVal(pc),a0
		sf	(a0)
		move.l	(a7)+,a0
		rts

;--------------------------------

HeadDown
		move.l	a0,-(a7)
		lea	HeadVal(pc),a0
		st	(a0)
		move.l	(a7)+,a0
		rts

;--------------------------------

Head
		move.l	a0,-(a7)
		lea	HeadVal(pc),a0
		sf	(a0)
		cmp.w	#7,-$44C(a1)		; dest $2282C
		bcs.b	.skip
		st	(a0)
.skip
		move.l	(a7)+,a0
		rts

;--------------------------------

Patch6
	;	and.w	#~DMAF_BLITHOG,$608a8	;disable blitpri
	;	and.w	#~DMAF_BLITHOG,$609a8	;disable blitpri
	;	and.w	#~DMAF_BLITHOG,$60fe6	;disable blitpri

		move.w	#$4EF9,$61380
		pea	ChangeDisk(pc)
		move.l	(a7)+,$61382

		move.w	#$6008,$63D46		; skip set drive
		move.w	#$6008,$63D64

		move.w	#$4EF9,$63DE4
		pea	Load(pc)
		move.l	(a7)+,$63DE6

		patchs	$60e26,_f1
		patchs	$60ede,_f1
		patchs	$61138,_f20
		patchs	$60e88,_f1
		patch	$60e66,_f30

		jmp	$60800

_f20		bsr	_blitwait
		move.l	#$ffff0000,$44(a6)
		addq.l	#2,(a7)
		rts

_f30		movem.l	(a7)+,d7/a0/a1
		bra	_blitwait

;--------------------------------

Load:
		movem.l	d0-a6,-(a7)

		lea	DiskNr(pc),a1

		move.l	#$1998,d1
		mulu	d1,d0
		moveq	#0,d2
		move.b	(a1),d2

		bsr.w	_LoadDisk

		movem.l	(a7)+,d0-a6
		lea	$1998(a0),a0
		rts

;--------------------------------

Load2
		movem.l	d0-a6,-(a7)

	IFNE 0
		move.w	d0,d2
		and.w	#1,d2
		add.w	#$4211,d2
		add.w	$25A1A,d2
		cmp.w	#$4212,d2
		beq.b	go
		cmp.w	#$4211,d2
		bne.b	stop
go
	ENDC
		mulu	#$CCC,d0
		lea	HeadVal(pc),a1
		tst.b	(a1)
		beq.b	.skip
		add.l	#$7FF80,d0
.skip
		lsl.l	#2,d1

		moveq	#3,d2
		bsr.b	_LoadDisk

		movem.l	(a7)+,d0-a6
		rts

	IFNE 0
stop
		move.w	$dff006,$dff180
		bra.b	stop
	ENDC

;--------------------------------

Load3
		movem.l	d0-a6,-(a7)

		move.w	d0,d1
		lsr.w	#1,d0
		mulu	#$1998,d0

		btst	#0,d1
		beq.b	.skip

		add.l	#$7FF80,d0
.skip
		moveq	#0,d1
		move.b	-2(a1),d1
		divu	#13,d1
		clr.w	d1
		swap	d1
		mulu	#$1F0,d1
		add.l	d1,d0
		moveq	#0,d1
		move.b	-1(a1),d1
		mulu	#$1F0,d1

		moveq	#3,d2
		bsr.b	_LoadDisk

		movem.l	(a7)+,d0-a6
		rts

;--------------------------------

ChangeDisk
		movem.l	d0/a0,-(a7)

		lea	DiskNr(pc),a0
		and.b	#$f,d0
		move.b	d0,(a0)

		movem.l	(a7)+,d0/a0
		rts

DiskNr		dc.b	1
HeadVal		dc.b	-1

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

;--------------------------------

	
; < A0: source
; < A1: destination	
unpack
		MOVEM.L	D0-D7/A0-A6,-(A7)	;60000: 48e7fffe
		MOVE.L	(A0)+,D0		;60014: 2018
		MOVE.L	(A0)+,D1		;60016: 2218
		MOVE.L	(A0)+,D5		;60018: 2a18
		MOVEA.L	A1,A2			;6001a: 2449
		ADDA.L	D0,A0			;6001c: d1c0
		ADDA.L	D1,A2			;6001e: d5c1
		MOVE.L	-(A0),D0		;60020: 2020
		EOR.L	D0,D5			;60022: b185
.lb_0000:
		LSR.L	#1,D0			;60024: e288
		BNE.S	.lb_0001		;60026: 6602
		BSR.S	.lb_000D		;60028: 6176
.lb_0001:
		BCS.S	.lb_0008		;6002a: 6532
		MOVEQ	#8,D1			;6002c: 7208
		MOVEQ	#1,D3			;6002e: 7601
		LSR.L	#1,D0			;60030: e288
		BNE.S	.lb_0002		;60032: 6602
		BSR.S	.lb_000D		;60034: 616a
.lb_0002:
		BCS.S	.lb_000A		;60036: 654c
		MOVEQ	#3,D1			;60038: 7203
		CLR.W	D4			;6003a: 4244
.lb_0003:
		BSR.S	.lb_000E		;6003c: 616e
		MOVE.W	D2,D3			;6003e: 3602
		ADD.W	D4,D3			;60040: d644
.lb_0004:
		MOVEQ	#7,D1			;60042: 7207
.lb_0005:
		LSR.L	#1,D0			;60044: e288
		BNE.S	.lb_0006		;60046: 6602
		BSR.S	.lb_000D		;60048: 6156
.lb_0006:
		ROXL.L	#1,D2			;6004a: e392
		DBF	D1,.lb_0005		;6004c: 51c9fff6
		MOVE.B	D2,-(A2)		;60050: 1502
		DBF	D3,.lb_0004		;60052: 51cbffee
		BRA.S	.lb_000C		;60056: 6038
.lb_0007:
		MOVEQ	#8,D1			;60058: 7208
		MOVEQ	#8,D4			;6005a: 7808
		BRA.S	.lb_0003		;6005c: 60de
.lb_0008:
		MOVEQ	#2,D1			;6005e: 7202
		BSR.S	.lb_000E		;60060: 614a
		CMP.B	#$02,D2			;60062: b43c0002
		BLT.S	.lb_0009		;60066: 6d12
		CMP.B	#$03,D2			;60068: b43c0003
		BEQ.S	.lb_0007		;6006c: 67ea
		MOVEQ	#8,D1			;6006e: 7208
		BSR.S	.lb_000E		;60070: 613a
		MOVE.W	D2,D3			;60072: 3602
		MOVE.W	#$000c,D1		;60074: 323c000c
		BRA.S	.lb_000A		;60078: 600a
.lb_0009:
		MOVE.W	#$0009,D1		;6007a: 323c0009
		ADD.W	D2,D1			;6007e: d242
		ADDQ.W	#2,D2			;60080: 5442
		MOVE.W	D2,D3			;60082: 3602
.lb_000A:
		BSR.S	.lb_000E		;60084: 6126
.lb_000B:
		SUBQ.W	#1,A2			;60086: 534a
		MOVE.B	0(A2,D2.W),(A2)		;60088: 14b22000
		DBF	D3,.lb_000B		;6008c: 51cbfff8
.lb_000C:
		CMPA.L	A2,A1			;60092: b3ca
		BLT.S	.lb_0000		;60094: 6d8e
		MOVEM.L	(A7)+,D0-D7/A0-A6	;60096: 4cdf7fff
		rts
	
.lb_000D:
		MOVE.L	-(A0),D0		;600a0: 2020
		EOR.L	D0,D5			;600a2: b185
		MOVE	#$0010,CCR		;600a4: 44fc0010
		ROXR.L	#1,D0			;600a8: e290
		RTS				;600aa: 4e75
.lb_000E:
		SUBQ.W	#1,D1			;600ac: 5341
		CLR.W	D2			;600ae: 4242
.lb_000F:
		LSR.L	#1,D0			;600b0: e288
		BNE.S	.lb_0010		;600b2: 660a
		MOVE.L	-(A0),D0		;600b4: 2020
		EOR.L	D0,D5			;600b6: b185
		MOVE	#$0010,CCR		;600b8: 44fc0010
		ROXR.L	#1,D0			;600bc: e290
.lb_0010:
		ROXL.L	#1,D2			;600be: e392
		DBF	D1,.lb_000F		;600c0: 51c9ffee
		RTS				;600c4: 4e75
;--------------------------------

_resload	dc.l	0		;address of resident loader
_tags		dc.l	WHDLTAG_ATTNFLAGS_GET
_attn		dc.l	0
		dc.l	WHDLTAG_MONITOR_GET
_monitor	dc.l	0
		dc.l	WHDLTAG_BUTTONWAIT_GET
_buttonwait	dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
_skip_intro:
		dc.l	0
		dc.l	0

;======================================================================

	END
