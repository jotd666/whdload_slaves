;*---------------------------------------------------------------------------
;  :Program.	Lotus2.asm
;  :Contents.	Slave for "Lotus 2" from Gremlin
;  :Author.	Wepl, StingRay, JOTD
;  :Original.	v1 original 1	harry
;		v2 Amiga Fun	ungi
;		v3 Trilogy	Juergen Urbanek <J.Urbanek@t-online.de>
;		v4 original 2	Jan Vieten <JanusI@gmx.de>
;		v5 NTSC ReCrack	Christopher Lakatos <ljc@sympatico.ca>
;				Chris Vella
;  :Version.	$Id: Lotus2.asm 1.12 2010/03/09 21:07:36 wepl Exp wepl $
;  :History.	12.10.1998
;		21.07.1999 compatibility with whdload v10
;		21.09.1999 version 1.2 finished
;		16.09.1999 support for v3 (lotus trilogy) added
;		29.09.1999 caches disabled because csppc
;		22.06.2000 support for v4 added
;		15.01.2001 snoop and highscores fixed
;		18.02.2001 one cache bug fixed
;		08.05.2001 clist bug in v2 fixed
;		14.07.2001 remaining snoop bugs removed
;		07.08.2003 bitter int acknowledge bug fixed
;		22.02.2007 support for v5 added
;		27.02.2007 waitvb hang on Elan spec screen fixed on NTSC
;		17.02.2010 call _highinit* also if custom2 is not set and
;			 with that half the scores too
;		15.08.2016 StingRay: source made 100% pc-relative and compatible
;			 with ASM-One/Pro, minor code optimising
;			 68000 quitkey support for v1 added
;		16.08.2016 68000 quitkey support for the 4 other versions added
;			 more code optimising, still nothing major
;			 WHDLoad v17+ features used (config)
;		30.05.2022 another Lotus Trilogy version supported
;		12.06.2024 keyboard remap for A1200 keyboard, slave refactored
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9, Asm-Pro 1.16d
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	"wart:li/lotus2/Lotus2.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC


;CHIP_ONLY
	IFD	CHIP_ONLY
CHIPMEMSIZE = $80000+$77000+$b000
EXPMEMSIZE = 0
	ELSE
CHIPMEMSIZE = $80000
EXPMEMSIZE = $77000+$b000	
	ENDC
	
	STRUCTURE globals,$120
		LONG	_resload
		LONG	_code1
		LONG	_code2
		LONG	_len2
		LONG	_clen
		LONG	_hlen
		WORD	_cfgsum

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError;ws_flags
		dc.l	CHIPMEMSIZE			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
		dc.b	0			;ws_keydebug
		dc.b	$5F			;ws_keyexit = Help
_expmem		dc.l	EXPMEMSIZE		;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-_base	; ws_config


.config	dc.b	"BW;"
	dc.b	"C1:B:Save Game Configuration;"
	dc.b	"C2:B:Save Highscores;"
	dc.b	"C3:B:change 2P keys ZX to AS;"
	dc.b	0
	CNOP	0,2

;============================================================================

	IFD	BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.13"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	
_name		dc.b	"Lotus Turbo Challenge 2"
			IFD		CHIP_ONLY
			dc.b	" (CHIP/DEBUG mode)"
			ENDC
			dc.b	0
_copy		dc.b	"1991 Magnetic Fields Ltd., Gremlin Ltd.",0
_info		dc.b	"Installed and fixed by Wepl & StingRay",10
			dc.b	"A1200 Keyboard fix by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	-1
		dc.b	"Greetings to Mr.Larmer,",10
		dc.b	"Harry and Wolfgang Unger",0
_cfg		dc.b	"config",0
_highs		dc.b	"highs",0
_hightext	dc.b	"  all time best scores  "

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	10,0	
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

		move.l	a0,(_resload)			;save for later use
		move.l	a0,a2

		IFD	CHIP_ONLY
		lea		_expmem(pc),a0
		move.l	#$80000,(a0)
		ENDC
	
		lea	(_tags,pc),a0
		jsr	(resload_Control,a2)

		move.l	#WCPUF_Base_WT!WCPUF_Exp_CB!WCPUF_Slave_CB!WCPUF_IC|WCPUF_BC!WCPUF_SS|WCPUF_SB!WCPUF_NWA,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)
		
		move.l	(_c1,pc),d0
		beq.b	.noc1
		lea	(_cfg,pc),a0
		jsr	(resload_GetFileSize,a2)
.noc1		move.l	d0,(_clen)
		move.l	(_c2,pc),d0
		beq.b	.noc2
		lea	(_highs,pc),a0
		jsr	(resload_GetFileSize,a2)
.noc2		move.l	d0,(_hlen)

		lea	$70000,A0			;destination
		move.l	a0,a3				;A3 = loader
		moveq	#0,D0				;offset
		move.l	#$400,D1			;length
		moveq	#1,d2				;disk
		movem.l	d1/a0,-(a7)
		jsr	(resload_DiskLoad,a2)
		movem.l	(a7)+,d0/a0
		jsr	(resload_CRC16,a2)

		cmp.w	#$e369,D0			;original release
		beq.b	_v14
		cmp.w	#$5D26,D0			;Amiga Fun
		beq.w	_v2
		cmp.w	#$aa93,D0			;Lotus Trilogy
		beq.w	_v3
		cmp.w	#$418e,d0			; Lotus Triloy, V2
		beq.w	_v3_no_boot_code
		cmp.w	#$1d99,D0			;NTSC ReCrack
		beq.w	_v5

		pea	(TDREASON_WRONGVER).w
		jmp	(resload_Abort,a2)

;--------------------------------

_tags		dc.l	WHDLTAG_CUSTOM1_GET
_c1		dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_c2		dc.l	0
		dc.l	0

;============================================================================

adr1	= $a00
len1	= $dc8
;adr20	= $731ec	;v1 if no exp mem (and on loading time)
;adr20	= $731fa	;v4 if no exp mem (and on loading time)
adr21	= $8d27e	;v1 if 1mb chip ($8c86a exe start)
;adr22	= $8		;v1 if 512k fast
len2	= $9df8		;v1
;len2	= $9dea		;v4

_v14		move.l	(_expmem,pc),d0
		add.l	#$77000,d0
		move.l	d0,(_code1)
		add.l	#len1,d0
		move.l	d0,(_code2)

		lea	$a00.w,a7
		move.l	a7,a0				;destination
		move.l	#$400,D0			;offset
		move.l	#$1000,D1			;length
		moveq	#1,d2				;disk
		jsr	(resload_DiskLoad,a2)

		lea	$a00.w,a0
		move.l	(_code1),a1
		move.w	#len1/4-1,d0
.cpy		move.l	(a0)+,(a1)+
		dbf	d0,.cpy

		lea		pl_v14(pc),a0
		sub.l	a1,a1
		jsr	(resload_Patch,a2)
		
	
		jmp	$a1c.w

pl_v14:
	PL_START
	PL_P	$bb6,_load
	PL_P	$1138,_gfx1			;gfx einschlag
	PL_R	$16bc				;protection
	PL_CB	$1188				;bad clist

	PL_R	$AD6			;track0
	PL_R	$AFE			;motoron
	PL_R	$B2E			;motoroff

	PL_P	$11BC,Decrunch

	PL_B	$16A8,$60			;skip check display mode
	PL_END


;--------------------------------

_gfx1		bsr	_waitvb
		move.w	#$8380,($96,a6)
		rts

;--------------------------------

		;d0=offset d1=size a0=dest
_load		movem.l	d0-d1/a0,-(a7)
		sub.l	#$400,d0			;1st+2nd track have a size of $1600
		moveq	#1,d2				;disk
		move.l	(_resload),a1
		jsr	(resload_DiskLoad,a1)
		movem.l	(a7),d0/d7/a0			;d7 = size = return value

		tst.w	($818,a4)			;encrypted?
		beq.w	.done

	IFD DEBUG
		cmp.l	#adr21,($7ec,a4)
		bne	_ill
		cmp.l	#len2,($7f0,a4)
		bne	_ill
		cmp.l	#adr1,($7f4,a4)
		bne	_ill
		cmp.l	#len1,($7f8,a4)
		bne	_ill
	ENDC

		move.l	(_len2),d4
		move.l	d0,d6
		divu	d4,d6
		lsr.l	#8,d6
		lsr.l	#8,d6				;d6 = 81a
		move.l	#len1,d4
		move.l	d0,d5
		divu	d4,d5
		lsr.l	#8,d5
		lsr.l	#8,d5				;d5 = 81c
		
		moveq	#0,d3				;d3 = 81e
		
		move.l	(_code2),a1
		add.l	d6,a1
		neg.l	d6
		add.l	(_len2),d6
		
		move.l	(_code1),a2
		add.l	d5,a2
		neg.l	d5
		add.l	#len1,d5
		
.loop		move.w	(a1)+,d1
		move.w	(a2)+,d2
		eor.w	d1,d3
		eor.w	d2,d3
		eor.w	d3,(a0)+
		
		subq.l	#2,d6
		beq.b	.1
		subq.l	#2,d5
		beq.b	.2
		subq.l	#2,d7
		bne.b	.loop
		bra.b	.done

.1		move.l	(_len2),d6
		move.l	(_code2),a1
		subq.l	#2,d5
		beq.b	.2
		subq.l	#2,d7
		bne.b	.loop
		bra.b	.done

.2		move.l	#len1,d5
		move.l	(_code1),a2
		subq.l	#2,d7
		bne.b	.loop

.done		movem.l	(a7)+,d0/d7/a0			;d7 = size = return value
		cmp.l	#$727D8,a0		; SPS 497
		beq.b	_v1_main
		cmp.l	#$727b4,a0
		beq.w	_v4_main
		rts

	IFD DEBUG
_ill		illegal
	ENDC

;--------------------------------

_savecode	move.l	(2,a0),a2
		move.l	(_code2),a1
		move.l	(6,a0),d0
		move.l	d0,(_len2)
.cpy		move.l	(a2)+,(a1)+
		sub.l	#4,d0
		bcc.b	.cpy
		rts

; + F7A2: compare to space cmp.w #$0040,(a3,$2fb4) == $0008afb4 [ffe0]

;--------------------------------

_v1_main	bsr.b	_savecode
		
		move.l	a0,a1

		
	;	skip	$132-$d4,$728d4			;exp mem check (no exp mem)
	;	move.w	#$604A,$728DE			;ext mem check (1mb chip)
		move.l	(_expmem,pc),($fe,a1)		;exp mem check (512k fast)
		
		lea	.pl(pc),a0
		move.l	_resload,a2
		jmp	(resload_Patch,a2)

.pl	PL_START
	PL_IFBW
	PL_PS	$1d40,_buttonwait
	PL_ENDIF
	PL_IFC2
	PL_PS	$1ab0,_cfgsave
	PL_ENDIF
	PL_IFC1
	PL_PS	$2a2a,_highsave
	PL_ENDIF
	PL_S	$102,$158-$102				;exp mem check (512k fast)
	PL_PS	$26e,_init
	PL_P	$2ba,_jump_exp_v1
	PL_S	$165c,$1706-$165c			;skip protection check
	PL_PS	$18a0,_specswait
	PL_PA	$1c06,SubGame
	PL_PS	$2c56,_highfix
	PL_P	$b184,_intack

; stingray, v1.11
	PL_PS	$2e12,CheckQuit
	PL_END

CheckQuit
	not.b	d0
	ror.b	d0
	cmp.b	_base+ws_keyexit(pc),d0
	bne.b	.noquit

	pea	(TDREASON_OK).w
	move.l	_resload.w,-(a7)
	addq.l	#resload_Abort,(a7)

.noquit	rts
	


;--------------------------------

_v4_main	
	
		bsr	_savecode

		move.l	a0,a1
		move.l	(_expmem,pc),($fe,a1)		;exp mem check (512k fast)
		
		lea	.pl(pc),a0
		move.l	_resload,a2
		jmp	(resload_Patch,a2)

.pl	PL_START
	PL_IFBW
	PL_PS	$1d64,_buttonwait
	PL_ENDIF
	PL_IFC2
	PL_PS	$1ad4,_cfgsave
	PL_ENDIF
	PL_IFC1
	PL_PS	$2a4e,_highsave
	PL_ENDIF

	PL_S	$102,$158-$102				;exp mem check (512k fast)
	PL_PS	$26e,_init
	PL_P	$a6e-$7b4,_jump_exp_v4
	PL_S	$168e,$1738-$168e			;skip protection check
	PL_PS	$18d2,_specswait
	PL_PA	$1c2a,SubGame
	PL_PS	$2c7a,_highfix
	PL_P	$b1a8,_intack

; stingray, v1.11
	PL_PS	$2e36,CheckQuit
	PL_END

;--------------------------------

SubGame		move.w	#$0,$40010			;preserve ints (ports)
		jmp	$40000

;--------------------------------

_init		bsr	_cfginit
		bsr	_highinit

_initq		lea	($28ec,a3),a1			;original
		move.w	#$8f,d7				;original
		addq.l	#2,(a7)
		rts

_init2		bsr	_cfginit2
		bsr	_highinit2
		bra.b	_initq

;--------------------------------
; $28b0..$28d4	pwd,ply1,ply2
; 2c,2e,30	write cursor
; 3a,4a		gear
; 3c,4c		acc
; 42		2player
; 44		link
; 4e		control

_cfginit	movem.l	d0-d2/a0-a2,-(a7)
	;check file
		move.l	(_clen),d2
		beq	.calc
	;load file
		sub.l	d2,a7
		lea	(_cfg,pc),a0
		move.l	a7,a1
		move.l	(_resload),a2
		jsr	(resload_LoadFile,a2)
	;set
		lea	($28b0,a3),a0
		lea	($28d4,a3),a1
.cp4		move.w	(a7)+,(a0)+
		cmp.l	a0,a1
		bne	.cp4
		lea	($2b2c,a3),a0
		lea	($2b50,a3),a1
.cp3		move.w	(a7)+,(a0)+
		cmp.l	a0,a1
		bne.b	.cp3
	;copy data
.calc		move.l	a7,d2
		lea	($2b2c,a3),a0
		lea	($2b50,a3),a1
.cp1		move.w	-(a1),-(a7)
		cmp.l	a0,a1
		bne	.cp1
		lea	($28b0,a3),a0
		lea	($28d4,a3),a1
.cp2		move.w	-(a1),-(a7)
		cmp.l	a0,a1
		bne.b	.cp2
		sub.l	a7,d2
	;sum
		move.l	d2,d0
		move.l	a7,a0
		move.l	(_resload),a2
		jsr	(resload_CRC16,a2)
		move.w	d0,(_cfgsum)
		add.l	d2,a7
		movem.l	(a7)+,d0-d2/a0-a2	; _MOVEMREGS
		rts

_cfginit2	movem.l	d0-d2/a0-a2,-(a7)
	;check file
		move.l	(_clen),d2
		beq.b	.calc
	;load file
		sub.l	d2,a7
		lea	(_cfg,pc),a0
		move.l	a7,a1
		move.l	(_resload),a2
		jsr	(resload_LoadFile,a2)
	;set
		lea	($28b0,a3),a0
		lea	($28d4,a3),a1
.cp4		move.w	(a7)+,(a0)+
		cmp.l	a0,a1
		bne.b	.cp4
		lea	($2b42,a3),a0
		lea	($2b66,a3),a1
.cp3		move.w	(a7)+,(a0)+
		cmp.l	a0,a1
		bne.b	.cp3
	;copy data
.calc		move.l	a7,d2
		lea	($2b42,a3),a0
		lea	($2b66,a3),a1
.cp1		move.w	-(a1),-(a7)
		cmp.l	a0,a1
		bne.b	.cp1
		lea	($28b0,a3),a0
		lea	($28d4,a3),a1
.cp2		move.w	-(a1),-(a7)
		cmp.l	a0,a1
		bne.b	.cp2
		sub.l	a7,d2
	;sum
		move.l	d2,d0
		move.l	a7,a0
		move.l	(_resload),a2
		jsr	(resload_CRC16,a2)
		move.w	d0,(_cfgsum)
		add.l	d2,a7
		movem.l	(a7)+,d0-d2/a0-a2	; _MOVEMREGS
		rts

_cfgsave	movem.l	d0-d2/a0-a2,-(a7)
	;copy data
		move.l	a7,d2
		lea	($2b2c,a3),a0
		lea	($2b50,a3),a1
.cp1		move.w	-(a1),-(a7)
		cmp.l	a0,a1
		bne	.cp1
		lea	($28b0,a3),a0
		lea	($28d4,a3),a1
.cp2		move.w	-(a1),-(a7)
		cmp.l	a0,a1
		bne.b	.cp2
		sub.l	a7,d2
	;check sum
		move.l	d2,d0
		move.l	a7,a0
		move.l	(_resload),a2
		jsr	(resload_CRC16,a2)
		cmp.w	(_cfgsum),d0
		beq.b	.skip
	;save
		move.w	d0,(_cfgsum)
		move.l	d2,d0
		lea	(_cfg,pc),a0
		move.l	a7,a1
		jsr	(resload_SaveFile,a2)
.skip		add.l	d2,a7
		movem.l	(a7)+,d0-d2/a0-a2	; _MOVEMREGS
		lea	($2b38,a3),a0			;original
		move.w	(a0)+,d0			;original
		rts

_cfgsave2	movem.l	d0-d2/a0-a2,-(a7)
	;copy data
		move.l	a7,d2
		lea	($2b42,a3),a0
		lea	($2b66,a3),a1
.cp1		move.w	-(a1),-(a7)
		cmp.l	a0,a1
		bne	.cp1
		lea	($28b0,a3),a0
		lea	($28d4,a3),a1
.cp2		move.w	-(a1),-(a7)
		cmp.l	a0,a1
		bne	.cp2
		sub.l	a7,d2
	;check sum
		move.l	d2,d0
		move.l	a7,a0
		move.l	(_resload),a2
		jsr	(resload_CRC16,a2)
		cmp.w	(_cfgsum),d0
		beq	.skip
	;save
		move.w	d0,(_cfgsum)
		move.l	d2,d0
		lea	(_cfg,pc),a0
		move.l	a7,a1
		jsr	(resload_SaveFile,a2)
.skip		add.l	d2,a7
		movem.l	(a7)+,d0-d2/a0-a2	; _MOVEMREGS
		lea	($2b4e,a3),a0			;original
		move.w	(a0)+,d0			;original
		rts

;--------------------------------
; $2b54..+$84*2	scores
; each entry 19 byte (10 name + 1 fill + 8 score)
; current scores at $306c and $3140

_highfix	lsr.l	#1,d0				;half scores
		divu	#10000,d0			;original
		move.l	d0,d1				;original
		rts

_highinit	movem.l	d0-d2/a0-a2,-(a7)
	;check file
		tst.l	(_hlen)
		bne	.load
	;set title
		lea	(_hightext,pc),a0
		lea	($2b54,a3),a1
		moveq	#23,d0
.cpy		move.b	(a0)+,(a1)+
		dbf	d0,.cpy
		bsr.b	_convert1
		bra.b	.end
	;load file
.load		lea	(_highs,pc),a0
		lea	($2b54,a3),a1
		move.l	(_resload),a2
		jsr	(resload_LoadFile,a2)
	;crypt
		bsr	_crypt
	;check for old scores
		cmp.l	#$84*2+1,(_hlen)
		beq.b	.end
		bsr.b	_convert1
	;end
.end		movem.l	(a7)+,d0-d2/a0-a2		; _MOVEMREGS
		rts

_convert1	lea	($2b54+$28,a3),a0
		bra.b	_convert
_convert2	lea	($2b6a+$28,a3),a0

	;convert old scores
_convert	moveq	#9,d0
.c1		moveq	#7,d1
.c2		move.b	(a0),d2
		cmp.b	#" ",d2
		beq.b	.c4
		sub.b	#"0",d2
		lsr.b	#1,d2
		bcc.b	.c3
		add.b	#10,(1,a0)
.c3		tst.b	d2
		bne.b	.c5
		tst.l	d1
		bmi.b	.c5
		moveq	#" ",d2
		bra.b	.c4
.c5		bset	#31,d1
		add.b	#"0",d2
.c4		move.b	d2,(a0)+
		dbf	d1,.c2
		add.w	#$10,a0
		dbf	d0,.c1
		rts

_highsave	sf	d6
		lea	($2838,a3),a0
		bsr	.enter
		lea	($2850,a3),a0
		bsr	.enter
		lea	($2868,a3),a0
		bsr	.enter
		lea	($2880,a3),a0
		bsr	.enter
		tst.b	d6
		beq.b	.end
	;crypt
		bsr	_crypt
	;save file
		move.l	#$84*2+1,d0
		lea	(_highs,pc),a0
		lea	($2b54,a3),a1
		move.l	(_resload),a2
		jsr	(resload_SaveFile,a2)
	;crypt
		bsr	_crypt
	;return
.end		addq.l	#4,a7
		rts

.enter		moveq	#9,d7
		move.l	(4,a7),a1
		jsr	($14,a1)
		cmp.w	#9,d7			;is changed if score is entered
		beq	.s
		st	d6
.s		rts

_crypt		lea	($2b54,a3),a0
		move.w	#$84*2-1,d0
.1		eor.b	d0,(a0)+
		dbf	d0,.1
		rts

_highinit2	movem.l	d0-d2/a0-a2,-(a7)
	;check file
		tst.l	(_hlen)
		bne.b	.load
	;set title
		lea	(_hightext,pc),a0
		lea	($2b6a,a3),a1
		moveq	#23,d0
.cpy		move.b	(a0)+,(a1)+
		dbf	d0,.cpy
		bsr.w	_convert2
		bra.b	.end
	;load file
.load		lea	(_highs,pc),a0
		lea	($2b6a,a3),a1
		move.l	(_resload),a2
		jsr	(resload_LoadFile,a2)
	;crypt
		bsr.b	_crypt2
	;check for old scores
		cmp.l	#$84*2+1,(_hlen)
		beq.b	.end
		bsr.w	_convert2
	;end
.end		movem.l	(a7)+,d0-d2/a0-a2	; _MOVEMREGS
		rts

_highsave2	sf	d6
		lea	($2838,a3),a0
		bsr.b	.enter
		lea	($2850,a3),a0
		bsr.b	.enter
		lea	($2868,a3),a0
		bsr.b	.enter
		lea	($2880,a3),a0
		bsr.b	.enter
		tst.b	d6
		beq.b	.end
	;crypt
		bsr.b	_crypt2
	;save file
		move.l	#$84*2+1,d0
		lea	(_highs,pc),a0
		lea	($2b6a,a3),a1
		move.l	(_resload),a2
		jsr	(resload_SaveFile,a2)
	;crypt
		bsr.b	_crypt2
	;return
.end		addq.l	#4,a7
		rts

.enter		moveq	#9,d7
		move.l	(4,a7),a1
		jsr	($14,a1)
		cmp.w	#9,d7			;is changed if score is entered
		beq.b	.s
		st	d6
.s		rts

_crypt2		lea	($2b6a,a3),a0
		move.w	#$84*2-1,d0
.1		eor.b	d0,(a0)+
		dbf	d0,.1
		rts

;--------------------------------

_buttonwait
.1		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)
		bne.b	.1
		move.w	#-1,($2fc8,a3)		;original
		rts

_specswait	move.w	#4*50,d0
.wait		tst.w	($2fda,a3)		;fire button
		bne.b	.fire
		bsr	_waitvb
		dbf	d0,.wait
		move.w	#-1,($2fc8,a3)		;original
		rts

.fire		sub.l	#14,(a7)
		rts

_buttonwait2
.1		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)
		bne.b	.1
		move.w	#-1,($2fde,a3)		;original
		rts

_specswait2	move.w	#4*50,d0
.wait		tst.w	($2ff0,a3)		;fire button
		bne.b	.fire
		bsr	_waitvb
		dbf	d0,.wait
		move.w	#-1,($2fde,a3)		;original
		rts

.fire		sub.l	#14,(a7)
		rts

_waitvb		;waitvbs	a6
		movem.l	d0-d2,-(sp)
		bsr.b	.wait
.loop		move.w	d0,d2
		bsr.b	.wait
		cmp.w	d0,d2
		bls.b	.loop
		bra.b	.exit

.wait		move.w	(4,a6),d0
		move.b	(6,a6),d1
		cmp.w	(4,a6),d0
		bne.b	.wait
		and.w	#1,d0
		lsl.w	#8,d0
		move.b	d1,d0
		rts

.exit		movem.l	(sp)+,d0-d2
		rts

;--------------------------------

Decrunch
	clr.w	$7FC(A4)
	move.l	D0,$828(A4)
	movea.l	D1,A5
	move.w	(A0),D0
	cmp.w	#$5341,D0
	beq.s	_SAP
	cmp.w	#$5350,D0
	beq.s	_SAP
	cmp.w	#$5343,D0
	beq.s	_SC
	cmp.w	#$5346,D0
	beq.w	_SF
	move.l	$828(A4),D7
	beq.s	lbC000032
lbC00002C:
	move.b	(A0)+,(A1)+
	subq.l	#1,D7
	bne.s	lbC00002C
lbC000032:
	move.l	$828(A4),D0
	rts

lbC000038:
	move.w	$820(A4),D1
	moveq	#0,D7
lbC00003E:
	add.l	D0,D0
	bne.s	lbC00004A
	move.l	-(A0),D0
	move.w	#$FFFF,CCR
	addx.l	D0,D0
lbC00004A:
	roxr.b	#1,D7
	dbra	D1,lbC00003E
	rts

lbB000052:
	dc.b	7
	dc.b	5
	dc.b	4
	dc.b	4
	dc.b	4
	dc.b	4
	dc.b	3
	dc.b	3

_SAP
	clr.w	$822(A4)
	bra.s	lbC000066

_SC
	move.w	#1,$822(A4)
lbC000066:
	movem.l	D1-D7/A0-A6,-(SP)
	movea.l	D1,A5
	movea.l	A1,A3
	moveq	#0,D7
	cmpi.w	#$5341,(A0)+
	bne.s	lbC000078
	moveq	#-1,D7
lbC000078:
	move.w	(A0)+,$820(A4)
	move.l	(A0)+,$82C(A4)
	move.w	$820(A4),D0
	lea	lbB000052(PC),A1
	move.b	#0,$824(A4)
	move.b	#0,$826(A4)
	move.b	-3(A1,D0.W),$825(A4)
	move.b	1(A1,D0.W),$827(A4)
	move.l	(A0)+,D0
	tst.w	$822(A4)
	beq.s	lbC0000B8
	moveq	#0,D1
	move.w	$820(A4),D2
	bset	D2,D1
	subq.w	#1,D1
lbC0000B2:
	move.w	(A0)+,(A5)+
	dbra	D1,lbC0000B2
lbC0000B8:
	adda.l	D0,A0
	clr.l	$830(A4)
	tst.l	D7
	beq.s	lbC0000D4
	movea.l	A0,A1
	move.l	8(A1),D0
	addq.l	#8,D0
	move.l	D0,$830(A4)
lbC0000CE:
	move.b	(A1)+,(A3)+
	subq.l	#1,D0
	bne.s	lbC0000CE
lbC0000D4:
	movea.l	A3,A1
	adda.l	$82C(A4),A3
	move.w	$820(A4),D7
	moveq	#0,D0
lbC0000E0:
	add.l	$82C(A4),D0
	subq.w	#1,D7
	bne.s	lbC0000E0
	add.l	D0,$830(A4)
	subq.w	#1,$820(A4)
	move.w	$820(A4),D7
	add.w	D7,D7
	add.w	D7,D7
	lea	lbC00027A(PC),A6
	adda.l	0(A6,D7.W),A6
	addq.l	#8,A6
	moveq	#0,D2
	move.w	#$4000,D4
	move.w	#$4000,D5
	move.l	-(A0),D0
lbC00010E:
	tst.w	$7FC(A4)
	bne.w	lbC0004B6
	moveq	#4,D1
	bsr.s	lbC000194
	add.w	D7,D7
	add.w	D7,D7
	move.l	A1,-(SP)
	lea	lbL000154(PC),A1
	adda.l	0(A1,D7.W),A1
	jsr	(A1)
	movea.l	(SP)+,A1
lbC00012C:
	cmpa.l	A3,A1
	beq.s	lbC00014A
	cmp.w	#$10,D2
	bcs.s	lbC00010E
	subi.w	#$10,D5
	andi.w	#$3FF0,D5
	lea	0(A2,D5.W),A5
	subi.w	#$10,D2
	jsr	(A6)
	bra.s	lbC00012C

lbC00014A:
	movem.l	(SP)+,D1-D7/A0-A6
	move.l	$830(A4),D0
	rts

lbL000154:
	dc.l	lbC0001AC-lbL000154
	dc.l	lbC0001B0-lbL000154
	dc.l	lbC0001B4-lbL000154
	dc.l	lbC0001B8-lbL000154
	dc.l	lbC0001BC-lbL000154
	dc.l	lbC0001C0-lbL000154
	dc.l	lbC0001C4-lbL000154
	dc.l	lbC0001CE-lbL000154
	dc.l	lbC0001D8-lbL000154
	dc.l	lbC0001E2-lbL000154
	dc.l	lbC0001EC-lbL000154
	dc.l	lbC0001F6-lbL000154
	dc.l	lbC00022C-lbL000154
	dc.l	lbC000236-lbL000154
	dc.l	lbC00025C-lbL000154
	dc.l	lbC000260-lbL000154

lbC000194:
	subq.w	#1,D1
	moveq	#0,D7
lbC000198:
	add.l	D0,D0
	bne.s	lbC0001A4
	move.l	-(A0),D0
	move.w	#$FFFF,CCR
	addx.l	D0,D0
lbC0001A4:
	addx.w	D7,D7
	dbra	D1,lbC000198
	rts
lbC0001AC:
	moveq	#0,D6
	bra.s	lbC0001FE
lbC0001B0:
	moveq	#1,D6
	bra.s	lbC0001FE
lbC0001B4:
	moveq	#2,D6
	bra.s	lbC0001FE
lbC0001B8:
	moveq	#3,D6
	bra.s	lbC0001FE
lbC0001BC:
	moveq	#4,D6
	bra.s	lbC0001FE
lbC0001C0:
	moveq	#5,D6
	bra.s	lbC0001FE
lbC0001C4:
	moveq	#1,D1
	bsr.s	lbC000194
	moveq	#6,D6
	add.w	D7,D6
	bra.s	lbC0001FE
lbC0001CE:
	moveq	#1,D1
	bsr.s	lbC000194
	moveq	#8,D6
	add.w	D7,D6
	bra.s	lbC0001FE
lbC0001D8:
	moveq	#2,D1
	bsr.s	lbC000194
	moveq	#10,D6
	add.w	D7,D6
	bra.s	lbC0001FE
lbC0001E2:
	moveq	#3,D1
	bsr.s	lbC000194
	moveq	#14,D6
	add.w	D7,D6
	bra.s	lbC0001FE
lbC0001EC:
	moveq	#5,D1
	bsr.s	lbC000194
	moveq	#$16,D6
	add.w	D7,D6
	bra.s	lbC0001FE
lbC0001F6:
	moveq	#8,D1
	bsr.s	lbC000194
	moveq	#$36,D6
	add.w	D7,D6
lbC0001FE:
	add.w	$824(A4),D6
	moveq	#14,D1
	bsr.s	lbC000194
	add.w	D4,D7
	move.w	D7,D3
	andi.w	#$3FFF,D3
	subq.w	#1,D6
lbC000210:
	subq.w	#1,D3
	andi.w	#$3FFF,D3
	move.b	0(A2,D3.W),D7
	subq.w	#1,D4
	andi.w	#$3FFF,D4
	move.b	D7,0(A2,D4.W)
	addq.l	#1,D2
	dbra	D6,lbC000210
	rts
lbC00022C:
	moveq	#4,D1
	bsr.w	lbC000194
	move.w	D7,D6
	bra.s	lbC000240
lbC000236:
	moveq	#8,D1
	bsr.w	lbC000194
	moveq	#$10,D6
	add.w	D7,D6
lbC000240:
	add.w	$826(A4),D6
	bsr.w	lbC000038
	subq.w	#1,D6
lbC00024A:
	subq.w	#1,D4
	andi.w	#$3FFF,D4
	move.b	D7,0(A2,D4.W)
	addq.l	#1,D2
	dbra	D6,lbC00024A
	rts
lbC00025C:
	moveq	#1,D6
	bra.s	lbC00026A
lbC000260:
	moveq	#3,D1
	bsr.w	lbC000194
	moveq	#2,D6
	add.w	D7,D6
lbC00026A:
	subq.w	#1,D6
lbC00026C:
	bsr.w	lbC000038
	subq.w	#1,D4
	andi.w	#$3FFF,D4
	move.b	D7,0(A2,D4.W)
lbC00027A:
	addq.l	#1,D2
	dbra	D6,lbC00026C
	rts
lbC000282:
	dc.l	lbC00035E-lbC000282
	dc.l	lbC000324-lbC000282
	dc.l	lbC0002E0-lbC000282
	dc.l	lbC000292-lbC000282
lbC000292:
	movem.l	D0/D2/D4/D5,-(SP)
	moveq	#15,D0
lbC000298:
	move.b	(A5)+,D1
	add.b	D1,D1
	addx.w	D2,D2
	add.b	D1,D1
	addx.w	D3,D3
	add.b	D1,D1
	addx.w	D4,D4
	add.b	D1,D1
	addx.w	D5,D5
	add.b	D1,D1
	addx.w	D6,D6
	add.b	D1,D1
	addx.w	D7,D7
	dbra	D0,lbC000298
	move.l	$82C(A4),D1
	move.w	D2,-(A3)
	adda.l	D1,A3
	move.w	D3,(A3)
	adda.l	D1,A3
	move.w	D4,(A3)
	adda.l	D1,A3
	move.w	D5,(A3)
	adda.l	D1,A3
	move.w	D6,(A3)
	adda.l	D1,A3
	move.w	D7,(A3)
	suba.l	D1,A3
	suba.l	D1,A3
	suba.l	D1,A3
	suba.l	D1,A3
	suba.l	D1,A3
	movem.l	(SP)+,D0/D2/D4/D5
	rts
lbC0002E0:
	movem.l	D0/D2/D4/D5,-(SP)
	moveq	#15,D0
lbC0002E6:
	move.b	(A5)+,D1
	add.b	D1,D1
	addx.w	D2,D2
	add.b	D1,D1
	addx.w	D3,D3
	add.b	D1,D1
	addx.w	D4,D4
	add.b	D1,D1
	addx.w	D5,D5
	add.b	D1,D1
	addx.w	D6,D6
	dbra	D0,lbC0002E6
	move.l	$82C(A4),D1
	move.w	D2,-(A3)
	adda.l	D1,A3
	move.w	D3,(A3)
	adda.l	D1,A3
	move.w	D4,(A3)
	adda.l	D1,A3
	move.w	D5,(A3)
	adda.l	D1,A3
	move.w	D6,(A3)
	suba.l	D1,A3
	suba.l	D1,A3
	suba.l	D1,A3
	suba.l	D1,A3
	movem.l	(SP)+,D0/D2/D4/D5
	rts
lbC000324:
	movem.l	D0/D2/D4/D5,-(SP)
	moveq	#15,D0
lbC00032A:
	move.b	(A5)+,D1
	add.b	D1,D1
	addx.w	D2,D2
	add.b	D1,D1
	addx.w	D3,D3
	add.b	D1,D1
	addx.w	D4,D4
	add.b	D1,D1
	addx.w	D5,D5
	dbra	D0,lbC00032A
	move.l	$82C(A4),D1
	move.w	D2,-(A3)
	adda.l	D1,A3
	move.w	D3,(A3)
	adda.l	D1,A3
	move.w	D4,(A3)
	adda.l	D1,A3
	move.w	D5,(A3)
	suba.l	D1,A3
	suba.l	D1,A3
	suba.l	D1,A3
	movem.l	(SP)+,D0/D2/D4/D5
	rts
lbC00035E:
	movem.l	D0/D2/D4,-(SP)
	moveq	#15,D0
lbC000364:
	move.b	(A5)+,D1
	add.b	D1,D1
	addx.w	D2,D2
	add.b	D1,D1
	addx.w	D3,D3
	add.b	D1,D1
	addx.w	D4,D4
	dbra	D0,lbC000364
	move.l	$82C(A4),D1
	move.w	D2,-(A3)
	adda.l	D1,A3
	move.w	D3,(A3)
	adda.l	D1,A3
	move.w	D4,(A3)
	suba.l	D1,A3
	suba.l	D1,A3
	movem.l	(SP)+,D0/D2/D4
	rts

_SF
	movem.l	D1-D7/A0-A6,-(SP)
	movea.l	A1,A3
	movea.l	A0,A2
	lea	10(A2),A1
	movea.l	A3,A5
	move.l	2(A0),D0
	movea.l	D0,A6
	adda.l	D0,A3
	move.l	6(A0),D2
	adda.l	D2,A0
	move.l	D2,D7
	addq.l	#3,D7
	lsr.l	#2,D7
	subq.l	#1,D7
lbC0003B2:
	move.l	(A1)+,(A2)+
	dbra	D7,lbC0003B2
	move.b	-(A0),D0
lbC0003BA:
	tst.w	$7FC(A4)
	bne.w	lbC0004B6
	add.b	D0,D0
	bne.s	lbC0003CE
	move.b	-(A0),D0
	move.w	#$FFFF,CCR
	addx.b	D0,D0
lbC0003CE:
	bcc.w	lbC000474
	add.b	D0,D0
	bne.s	lbC0003DE
	move.b	-(A0),D0
	move.w	#$FFFF,CCR
	addx.b	D0,D0
lbC0003DE:
	bcc.s	lbC000440
	add.b	D0,D0
	bne.s	lbC0003EC
	move.b	-(A0),D0
	move.w	#$FFFF,CCR
	addx.b	D0,D0
lbC0003EC:
	bcc.s	lbC000446
	add.b	D0,D0
	bne.s	lbC0003FA
	move.b	-(A0),D0
	move.w	#$FFFF,CCR
	addx.b	D0,D0
lbC0003FA:
	bcc.s	lbC00044C
	add.b	D0,D0
	bne.s	lbC000408
	move.b	-(A0),D0
	move.w	#$FFFF,CCR
	addx.b	D0,D0
lbC000408:
	bcc.s	lbC00040E
	moveq	#9,D4
	bra.s	lbC000410

lbC00040E:
	moveq	#14,D4
lbC000410:
	moveq	#1,D2
	moveq	#1,D3
	moveq	#5,D5
lbC000416:
	move.w	D2,D1
	subq.w	#1,D1
	moveq	#0,D7
lbC00041C:
	add.b	D0,D0
	bne.s	lbC000428
	move.b	-(A0),D0
	move.w	#$FFFF,CCR
	addx.b	D0,D0
lbC000428:
	addx.w	D7,D7
	dbra	D1,lbC00041C
	add.w	D7,D5
	cmp.w	D3,D7
	bne.s	lbC00043C
	addq.w	#1,D2
	add.w	D3,D3
	addq.w	#1,D3
	bra.s	lbC000416

lbC00043C:
	move.w	D4,D1
	bra.s	lbC000450

lbC000440:
	moveq	#9,D1
	moveq	#2,D5
	bra.s	lbC000450

lbC000446:
	moveq	#10,D1
	moveq	#3,D5
	bra.s	lbC000450

lbC00044C:
	moveq	#12,D1
	moveq	#4,D5
lbC000450:
	subq.w	#1,D1
	moveq	#0,D7
lbC000454:
	add.b	D0,D0
	bne.s	lbC000460
	move.b	-(A0),D0
	move.w	#$FFFF,CCR
	addx.b	D0,D0
lbC000460:
	addx.w	D7,D7
	dbra	D1,lbC000454
	lea	0(A3,D7.W),A2
	subq.w	#1,D5
lbC00046C:
	move.b	-(A2),-(A3)
	dbra	D5,lbC00046C
	bra.s	lbC0004A8

lbC000474:
	moveq	#1,D2
	moveq	#1,D3
	moveq	#1,D6
lbC00047A:
	move.w	D2,D1
	subq.w	#1,D1
	moveq	#0,D7
lbC000480:
	add.b	D0,D0
	bne.s	lbC00048C
	move.b	-(A0),D0
	move.w	#$FFFF,CCR
	addx.b	D0,D0
lbC00048C:
	addx.w	D7,D7
	dbra	D1,lbC000480
	add.w	D7,D6
	cmp.w	D3,D7
	bne.s	lbC0004A0
	addq.w	#1,D2
	add.w	D3,D3
	addq.w	#1,D3
	bra.s	lbC00047A

lbC0004A0:
	subq.w	#1,D6
lbC0004A2:
	move.b	-(A0),-(A3)
	dbra	D6,lbC0004A2
lbC0004A8:
	cmpa.l	A5,A3
	bne.w	lbC0003BA
	move.l	A6,D0

		bsr	_flushcache

_dec2	movem.l	(SP)+,D1-D7/A0-A6

		cmp.l	#"Trac",(16,a1)
		beq	_protracker

	rts

lbC0004B6:
	movem.l	(SP)+,D1-D7/A0-A6
	moveq	#0,D0
	rts

;--------------------------------

_protracker	movem.l	d0-d1/a0-a2,-(a7)
		move.w	#$3228,($964,a1)	;address $634a4
		move.w	#$4e71,($968,a1)	;move.w ($14),d1 -> move.w ($14,a0),d1
		move.l	a1,a0
		add.l	d0,a1
		bsr	_dbffix
		movem.l	(a7)+,d0-d1/a0-a2	; _MOVEMREGS
		bra	_flushcache

;--------------------------------

_v2		lea	$200,a0				;destination
		move.l	a0,a7
		move.l	#$400,D0			;offset
		move.l	#$1000,D1			;length
		moveq	#1,d2				;disk
		jsr	(resload_DiskLoad,a2)
		
		patch	$3ee+$200,.load
		patch	$822+$200,_gfx1			;gfx einschlag
		clr.b	$a72				;bad clist
		
		patch	$15e(a3),.main

		jmp	($8a,a3)

.load		move.l	D5,D0				;offset
		move.l	D6,D1				;length
		moveq	#1,d2				;disk
		move.l	(_resload),a2
		jsr	(resload_DiskLoad,a2)
		moveq	#0,d0
		rts

.main		movem.l	(a7)+,d0-a6
_v23		move.l	(a7),a1
		
		move.l	(_expmem,pc),($fe,a1)

		lea	.pl(pc),a0
		move.l	_resload,a2
		jmp	(resload_Patch,a2)

.pl	PL_START
	PL_IFBW
	PL_PS	$1cbe,_buttonwait
	PL_ENDIF
	PL_IFC2
	PL_PS	$1a2e,_cfgsave
	PL_ENDIF
	PL_IFC1
	PL_PS	$29a8,_highsave
	PL_ENDIF

	PL_W	$fc,$207c				;movea.l #,a0
	PL_S	$102,$15c-$102				;exp mem check
	PL_PS	$272,_init2
	PL_P	$2be,_jump_exp_v2
	PL_PS	$182c,_specswait2
	PL_PA	$1b84,SubGame
	PL_PS	$2bd4,_highfix
	PL_P	$b100,_intack
	PL_P	$b89c,_dec2				;soundtracker fix

; stingray, v1.11
	PL_PS	$2d90,CheckQuit
	PL_END

_jump_exp_v1
_jump_exp_v5
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	a4,a1
	move.l	_resload.w,a2	
	lea		pl_prog_v1(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	(a4)
_jump_exp_v2
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	a4,a1
	move.l	_resload.w,a2	
	lea		pl_prog_v2(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	(a4)
_jump_exp_v4
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	a4,a1
	move.l	_resload.w,a2	
	lea		pl_prog_v4(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	(a4)


_intack		move.w	#$40,($9c,a6)
		tst.w	(2,a6)
		rte

key_left = $20
key_right = $21

; V1 and V5
pl_prog_v1:
	PL_START
	PL_IFC3
	PL_B	$f69e-$d27e+3,key_left	; Z => A
	PL_B	$f6a4-$d27e+3,key_right	; X => S
	PL_B	$f6bc-$d27e+3,key_left+$80	; Z => A (release)
	PL_B	$f6c2-$d27e+3,key_right+$80	; X => S (release)
	PL_ENDIF
	PL_END
	
pl_prog_v2:
	PL_START
	PL_IFC3
	PL_B	$f5fc-$d294+3,key_left	; Z => A
	PL_B	$f602-$d294+3,key_right	; X => S
	PL_B	$f61a-$d294+3,key_left+$80	; Z => A (release)
	PL_B	$f620-$d294+3,key_right+$80	; X => S (release)
	PL_ENDIF
	PL_END
	
pl_prog_v4:
	PL_START
	PL_IFC3
	PL_B	$f690-$d27e+3,key_left	; Z => A
	PL_B	$f696-$d27e+3,key_right	; X => S
	PL_B	$f6ae-$d27e+3,key_left+$80	; Z => A (release)
	PL_B	$f6b4-$d27e+3,key_right+$80	; X => S (release)
	PL_ENDIF
	PL_END
	

;--------------------------------

_v3		lea	$200.w,a0			;destination
		move.l	a0,a7
		move.l	#$400,D0			;offset
		move.l	#$1000,D1			;length
		moveq	#1,d2				;disk
		jsr	(resload_DiskLoad,a2)

		patch	$2b8+$200.w,.load
		patch	$822+$200.w,_gfx1		;gfx einschlag
		ret	$1cc+$200.w			;track0
		ret	$1fa+$200.w			;motoron
		ret	$238+$200.w			;motoroff
		clr.b	$a72.w				;bad clist


		skip	($390-$310),$310.w		;drive access
		skip	($a8-$9c),$9c(a3)		;disk check on lmb
		patch	$ba(a3),.main

		jmp	($8a,a3)

		;d0=offset d1=size a0=dest
.load		sub.l	#$400,d0			;1st+2nd track have a size of $1600
		move.l	d1,d7				;return value
		moveq	#1,d2				;disk
		move.l	(_resload),a1
		jsr	(resload_DiskLoad,a1)
		moveq	#0,d0
		rts

.main		jsr	$208.w				;load main
		bra.w	_v23

;--------------------------------
; stingray: lotus trilogy version which lacks the boot code on disk
; (it's embedded in the menu code)

_v3_no_boot_code
	lea	.boot_code(pc),a0
	lea	$200.w,a1
	move.l	a1,a7
	move.l	(_resload),a2
	jsr	resload_Decrunch(a2)


	patch	$2b8+$200.w,.load
	patch	$822+$200.w,_gfx1		;gfx einschlag
	ret	$1cc+$200.w			;track0
	ret	$1fa+$200.w			;motoron
	ret	$238+$200.w			;motoroff
	clr.b	$a72.w				;bad clist


	skip	($390-$310),$310.w		;drive access

	;moveq	#0,d0				; unused
	;move.l	#$1400,d1			; MFM buffer
	lea	.Text(pc),a0
	jsr	$200+$1c.w			; write title and load directory

	move.w	#255,d0
	lea	$723b0,a0
	move.l	a0,-(a7)
	bra.b	.main


	;d0=offset d1=size a0=dest
.load	sub.l	#$400,d0			;1st+2nd track have a size of $1600

	sub.l	#512*11*2,d0	; disk lacks the first track

	move.l	d1,d7				;return value
	moveq	#1,d2				;disk
	move.l	(_resload),a1
	jsr	(resload_DiskLoad,a1)
	moveq	#0,d0
	rts

.main	jsr	$208.w				;load main
	bra.w	_v23


.Text	dc.b	"----lotus turbo challenge ii----"
	CNOP	0,2




.boot_code
	DC.L	$524E4302,$00001000,$0000064A,$AB5A33A1
	DC.L	$02010061,$32603C61,$2EE3032A,$8E032638
	DC.L	$0322031E,$E3031A8E,$03163803,$12030EE3
	DC.L	$030A8E03,$06350302,$03C74DF9,$00DFF000
	DC.L	$49FAFFC4,$4E756000,$01B88C03,$F2030263
	DC.L	$3E030474,$8C0B5003,$0573580F,$1C450000
	DC.L	$13380760,$1352E203,$5A401B00,$9A48A7C2
	DC.L	$054A4067,$E11A5340,$322E0006,$0241FF00
	DC.L	$34060742,$0700B441,$67F451C8,$FFEA364C
	DC.L	$9F0F5B17,$2408291C,$410E4E39,$7CFFFF0E
	DC.L	$5441EC08,$A6200843,$058A3133,$401B4840
	DC.L	$C7050214,$139E131B,$2E3E3C66,$D8021705
	DC.L	$50490151,$CFFFF020,$42618612,$E23D7C12
	DC.L	$30002405,$82700066,$96057F0B,$0C9E13FC
	DC.L	$006ABF38,$D3000703,$C607E201,$18DA27BA
	DC.L	$01CB008A,$08F90313,$D1008907,$04930705
	DC.L	$20070607,$30CC6902,$2DFF713E,$0F074417
	DC.L	$B9C92FB9,$932FB93C,$2FB9052F,$0EF11E57
	DC.L	$FEE6C789,$681C0336,$03710803,$9A869561
	DC.L	$28201BC7,$1F00220C,$050508F3,$09764647
	DC.L	$06022948,$0E4E1B36,$202C0D05,$31397C10
	DC.L	$0E52B607,$0107A253,$390163E0,$01670EC7
	DC.L	$55101855,$90030356,$0360E842,$6C0E5688
	DC.L	$97024023,$2D0E720F,$564103F9,$03387D68
	DC.L	$1D07F003,$0F5803B9,$900D03E8,$E30D4A88
	DC.L	$57051E57,$66F60D3D,$5B2A4C13,$0F1AF305
	DC.L	$3D0C0031,$2E008EFC,$18003C1A,$0748470B
	DC.L	$18CD0B30,$2CCE91C0,$00136030,$39400E74
	DC.L	$43C0DB4A,$45EC0D4E,$0C720012,$321DE506
	DC.L	$41E54020,$31076B67,$0287C422,$31100092
	DC.L	$806A0622,$29043A07,$1C156CCB,$76520300
	DC.L	$6448E7FF,$FE613261,$40241322,$486C4181
	DC.L	$28005CD1,$71C012D8,$538166FA,$610E6118
	DC.L	$4CDF7FFF,$2E656C70,$C6F12E73,$010186A0
	DC.L	$538766FC,$B80BCB06,$E8C54302,$CB703100
	DC.L	$620C606C,$DD0E6267,$4E733F93,$8EAFB4CE
	DC.L	$B51C0C07,$DA301F05,$01009C60,$C8BE4367
	DC.L	$1252CE75,$70280360,$2B600E67,$2660B220
	DC.L	$1B40C5B0,$C3155C67,$06820DC2,$6090C16F
	DC.L	$70016070,$0A700260,$06700360,$0270044A
	DC.L	$C3215466,$0205153D,$7C000F40,$89FF009A
	DC.L	$0741FA00,$2E0663DC,$114033F2,$430B4286
	DC.L	$4974020B,$1C0F1171,$91401F0D,$E848A30B
	DC.L	$1E0B5904,$18608EFE,$6469736B,$20657272
	DC.L	$6F72206E,$756D6209,$1420782D,$00176669
	DC.L	$6C2E652D,$78783031,$32333435,$36373839
	DC.L	$61626364,$6566378F,$9A696512,$9CA60523
	DC.L	$FF060544,$89007E05,$71950B20,$80954E41
	DC.L	$E8003A2D,$18480020,$11980C84,$233B0570
	DC.L	$9F365381,$0D671830,$2E7DB193,$0C67F227
	DC.L	$49125362,$61DD0376,$0022C33F,$43E94C3F
	DC.L	$47201C30,$19B05DB8,$F467F83E,$3C0BFF34
	DC.L	$3C555561,$1230C1D6,$41808DF8,$61083E01
	DC.L	$6104733C,$35002332,$19C042C2,$42D21941
	DC.L	$D2400D78,$843C3C17,$FEF04358,$66046438
	DC.L	$095A6C4D,$093AC009,$5E9A44E2,$4DB15B26
	DC.L	$840764D0,$C4005936,$D851CDFF,$FC34294B
	DC.L	$0F4589A0,$D30801E8,$2D740852,$850D0651
	DC.L	$39410300,$E248E249,$92406726,$396B0A27
	DC.L	$521F6072,$0A238009,$44415341,$61073A30
	DC.L	$3C1F4054,$75FE511F,$C9FFF402,$2F455203
	DC.L	$982D3B4B,$08168667,$0A055D60,$0261021F
	DC.L	$2B000207,$F1FB283C,$2F040F18,$E52D8E0F
	DC.L	$323E0F08,$0662414D,$A5DD000B,$29AFC709
	DC.L	$67F6461B,$5D769C21,$AD73AC0B,$1196BDDD
	DC.L	$1709F168,$EE0D0E53,$1BFF32C7,$6130C11C
	DC.L	$BBFC4354,$03E7F318,$C6E706EB,$91E402E5
	DC.L	$00B2E5DC,$901D0527,$61968EBF,$00387549
	DC.L	$C7451B32,$C460ABFC,$32FC4479,$890103C4
	DC.L	$C13D6876,$00187732,$183AD641,$AE95980E
	DC.L	$23F63203,$15098E32,$262D0086,$29DE3F04
	DC.L	$03F7018F,$54C9FF16,$F50A9184,$772D4908
	DC.L	$91D82843,$1D058A2D,$04875D05,$56DD7BF7
	DC.L	$B039D266,$1C847F26,$89390720,$B348660A
	DC.L	$0A87FA70,$ABCB70BA,$2F341D01,$02410071
	DC.L	$0CE24A32,$02A70961,$A13C01DC,$72463001
	DC.L	$E254E250,$80464640,$0240AAAA,$804132C0
	DC.L	$38E885CC,$D07E017F,$007F3E63,$3C036760
	DC.L	$7740630D,$3F7E4363,$0003A53E,$187E7E60
	DC.L	$671A013E,$56A40C12,$60006319,$18036E13
	DC.L	$73460D18,$03006B36,$770F0067,$38073903
	DC.L	$661AB800,$277FC032,$637C7C6F,$7FC0277C
	DC.L	$606B7B63,$367E6B51,$2736367F,$B801366B
	DC.L	$18491E0F,$7E063E3F,$016D4F03,$1C8C4F63
	DC.L	$6F0A6530,$6C030A1C,$7736B866,$1C780073
	DC.L	$18600306,$03630C63,$11002783,$9F60809F
	DC.L	$7E677F63,$67063E60,$3A677E46,$6708371C
	DC.L	$199F3C4D,$06CC5E55,$187618B5,$771FC003
	DC.L	$A645FAFF,$7E103018,$B00D306B,$12E0053A
	DC.L	$6B10E005,$616B06E0,$057B6B0A,$747030F5
	DC.L	$04531460,$04E30560,$A05BFF13,$07720050
	DC.L	$00801B05,$280F9905,$0040C005,$D8002012
	DC.L	$1DF200B0,$9D57B657,$9B0E402F,$803D7C08
	DC.L	$83800096,$9015FFFE,$0120C726,$01221C03
	DC.L	$24037126,$0328C703,$2A1C032C,$03712E03
	DC.L	$30CE03B9,$BB0134C7,$03361C03,$3803733A
	DC.L	$03AEED01,$703E0300,$12C66092,$0055B874
	DC.L	$9400C000,$8E99A100,$909EA101,$9C58010A
	DC.L	$7F71E003,$E2C70B80,$0703820F,$FF1500FE
	DC.L	$7F99F77B,$00F700DE,$F700F700,$F7F70084
	DC.L	$A90002B9,$289C0701,$E2051757,$C10102D1
	DC.L	$48078F6C,$90FBF7B0,$DE8D0000


;--------------------------------

_v5		lea	$60000,a0			;destination
		move.l	a0,a3
		move.l	#$d3200,D0			;offset
		move.l	#$74a8,D1			;length
		moveq	#1,d2				;disk
		jsr	(resload_DiskLoad,a2)

		patch	$104.w,.1

		jmp	(a3)				;decrunch

.1		lea	_pl5_50000(pc),a0
		lea	$50000,a1
		move.l	a1,a3
		move.l	_resload.w,a2
		jsr	(resload_Patch,a2)

		move.l	(_expmem,pc),($18fe,a3)		;exp mem check (512k fast)

		jmp	$5f10c

_pl5_50000	PL_START
		PL_IFBW
		PL_PS	$1800+$1d40,_buttonwait
		PL_ENDIF
		PL_IFC2
		PL_PS	$1800+$1ab0,_cfgsave
		PL_ENDIF
		PL_IFC1
		PL_PS	$1800+$2a2a,_highsave
		PL_ENDIF

		PL_R	$8D6				;track0
		PL_R	$8FE				;motoron
		PL_R	$92E				;motoroff
		PL_P	$9b6,.load
		PL_P	$f38,_gfx1			;gfx einschlag
		PL_CB	$f88				;bad clist
		PL_P	$fBC,Decrunch
		PL_S	$1616,$e-6			;skip trap #0
		;the following is the main at offset $1800
		PL_PS	$1a6e,_init
		PL_P	$1aba,_jump_exp_v5
		PL_S    $2e5c,$1706-$165c	        ;skip protection check
		PL_PS	$30a0,_specswait
		PL_PA	$3406,SubGame
		PL_PS	$4456,_highfix
		PL_P	$c984,_intack


; stingray, v1.11
		PL_PS	$1800+$2e12,CheckQuit
		PL_END

		;d0=offset d1=size a0=dest
.load		movem.l	d1-d2/a0-a1,-(a7)
		sub.l	#$10964,d0			;offset
		moveq	#1,d2				;disk
		move.l	(_resload),a1
		jsr	(resload_DiskLoad,a1)
		movem.l	(a7)+,d1-d2/a0-a1
		move.l	d1,d7				;d7 = size = return value
		moveq	#0,d0
		rts

;--------------------------------

_flushcache	move.l	(_resload),-(a7)
		add.l	#resload_FlushCache,(a7)
		rts

;============================================================================

	INCLUDE	whdload/dbffix.s

;============================================================================

	END

