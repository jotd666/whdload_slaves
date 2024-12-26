;*---------------------------------------------------------------------------
;  :Program.	xenon2.asm
;  :Contents.	Slave for "Xenon 2"
;  :Author.	Wepl
;  :Version.	$Id: xenon2.asm 1.9 2005/05/11 17:47:20 wepl Exp wepl $
;  :History.	31.03.97 initial
;		12.04.97 adaptation from J.F.Fabre's (JOTD) Installer
;		20.12.98 work on CDTV version started
;		24.12.98 work on disk version started
;		25.12.98 disk version finished
;		07.01.98 support for second disk version started
;		03.06.99 support for third disk version added
;		17.06.00 highscores fixed
;		18.06.00 trainer fixed
;		16.08.00 crash on not entering highscores fixed
;		06.05.03 snoop bugs fixed
;		11.05.03 keyboard fixed
;		11.08.04 support for v4/v5 added, UAE fix
;		11.03.05 support for v6 added
;		04.05.05 support for v6 continuing
;		11.05.05 autofire fix added
;       24.12.17 (JOTD) adapted to WHDLoad v17
;       25.02.18 (JOTD) added intro skip in floppy version,
;                added cache flushes, 68000 quitkey
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9, Vasm
;  :To Do.
;---------------------------------------------------------------------------*

;CDTV		;if defined Slave for CDTV version will be created

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	IFD CDTV
	OUTPUT	"wart:x-y/xenon2/Xenon2CDTV.Slave"
	ELSE
	OUTPUT	"wart:x-y/xenon2/Xenon2.Slave"
	ENDC
	BOPT	O+			;enable optimizing
	BOPT	OG+			;enable optimizing
	BOPT	ODd-			;disable mul optimizing
	BOPT	ODe-			;disable mul optimizing
	BOPT	w4-			;disable 64k warnings
	SUPER
	ENDC
	
	STRUCTURE	globals,$100
		LONG	RESLOAD

;======================================================================


_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError		;ws_flags
	IFD CDTV
		dc.l	$c6000			;ws_BaseMemSize
	ELSE
		dc.l	$80000			;ws_BaseMemSize (was $81000 but why??)
	ENDC
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
	IFD CDTV
		dc.w	_data-_base		;ws_CurrentDir
	ELSE
		dc.w	0			;ws_CurrentDir
	ENDC
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

_config
        dc.b    "C1:X:Trainer 9 lives/continues 100000 cash:0;"
	IFD CDTV
        dc.b    "C2:X:left mouse button emulates B CDTV button:0;"
	ELSE
        dc.b    "C2:X:Skip introduction:0;"	
	ENDC
		dc.b	0
;============================================================================


	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC
		
DECL_DATE:MACRO
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		incbin	datetime
	ENDC
	ENDM
		
	IFND CDTV
_name		dc.b	"Xenon 2 - Megablast",0
_copy		dc.b	"1988 The Bitmap Brothers",0
_info		dc.b	"installed & fixed by Wepl & JOTD",10
		dc.b	"Version 1.12 Floppy "
		DECL_DATE
		dc.b	0
	ELSE
_data		dc.b	"data",0
_name		dc.b	"Xenon 2 - Megablast",0
_copy		dc.b	"1991 The Bitmap Brothers",0
_info		dc.b	"installed & fixed by Wepl & JOTD",10
		dc.b	"Version 1.7 CDTV "
		DECL_DATE
		dc.b	0
	ENDC
	EVEN

;======================================================================
_start	;	A0 = resident loader
;======================================================================

		move.l	a0,(RESLOAD)
		move.l	a0,a5			;A5 = resload
		lea	(_custom),a6		;A6 = _custom

	;get tags
		lea	(_control,pc),a0
		jsr	(resload_Control,a5)

	IFD CDTV

	;install keyboard quitter
		bsr	_SetupKeyboard
	;load exe
		lea	(_x2,pc),a0
		lea	($400),a1
		move.l	a1,a4			;A4 = address
		jsr	(resload_LoadFileDecrunch,a5)
		move.l	a4,a0
		sub.l	a1,a1
		jsr	(resload_Relocate,a5)

		lea	_px2(pc),a0
		sub.l	a1,a1
		jsr	(resload_Patch,a5)

		move.l	#NTSC_MONITOR_ID,d0
		cmp.l	(_monitor,pc),d0
		bne	.1
		move.w	#4,($12,a4)		;3=pal 4=ntsc
.1
		lea	(_gametrainer,pc),a0
		move.l	(_custom1,pc),d0
		bne	.trained
		lea	(_notrainer,pc),a0
		patch	$3c54a,_savehighs
.trained	lea	$3a296,a1
		move.l	#$4e714eb9,(a1)+
		move.l	a0,(a1)

		lea	(_highs,pc),a0
		jsr	(resload_GetFileSize,a5)
		cmp.l	#$fc-$66+$28,d0
		bne	.nohighs
		lea	(_highs,pc),a0
		lea	$3c366-$28,a1
		pea	(a1)
		jsr	(resload_LoadFileDecrunch,a5)
		move.l	(a7)+,a0
		bsr	_crypt
.nohighs
		move.l	(_custom2,pc),d0
		beq	.nolmb
		move.l	#$bfe001,$35092+4	;second fire button -> LMB
.nolmb
		lea	(_vbi,pc),a0
		move.l	a0,($6c)
		move.w	#INTF_SETCLR|INTF_INTEN|INTF_VERTB,(intena,a6)
		move.w	#INTF_VERTB,(intreq,a6)

		
		jmp	(a4)

_vbi		move.w	#INTF_VERTB,(_custom+intreq)
		rte


_px2	PL_START
	PL_P	$33930,_load_level
	PL_P	$37a98,_32bit
	PL_S	$3a742,12			;cash clear before each level
	PL_R	$3a924				;cdtv.device stuff
	PL_R	$3a9ba				;cdtv.device stuff
	PL_S	$3aa4a,$3aae8-$3aa4a		;os stuff
	PL_S	$3ab2c,$3ab40-$3ab2c		;asking exec.VBlankFrequency
	PL_PS	$3c07e+$400,_waitautofire
	PL_P	$3c7de,_load_speech
	PL_P	$3d2a4,_load_level2
	PL_P	$3d86e,_load_intro
	PL_P	$3e09a,_load_intro2
	;PL_P	$410b2,$34fb2			;strange sound problem (does not help)
	PL_P	$411a8,_load_speech2
	PL_P	$4fd28,_load_sounds2
	PL_P	$4fd78,_load_sounds
	PL_P	$50f68,_load_pics
	PL_P	$50fce,_load_piccode
	PL_END

_load_sounds
_load_sounds2	lea	($88a48),a1		;186900 bytes

_load		move.l	d1,a0
		addq.l	#4,a0
		move.l	(RESLOAD),a2
		jmp	(resload_LoadFileDecrunch,a2)

_load_speech	move.l	($411e4),a1		;107800 bytes
		pea	($3c80c)
		bra	_load

_load_level	lea	($4e26),a1		;180000 bytes
		pea	($3395e)
		bra	_load

_load_intro	lea	($4e26),a1
		pea	($3d89c)
		bra	_load

_load_speech2	move.l	($411e4),a1		;107800 bytes
		pea	($411d6)
		bra	_load

_load_piccode	lea	($4e26),a1
		pea	($3d2ee)
		bra	_load

_load_pics	move.l	($4e42),a1
		pea	($50f96)
		bra	_load

_load_intro2	lea	($4e26),a1
		pea	($3e0c8)
		bra	_load

_load_level2	lea	($4e26),a1		;180000 bytes
		pea	($3d2d2)
		bra	_load

_savehighs	addq.l	#2,a7			;original
		jsr	$3ca02			;original
		move.l	#$fc-$66+$28,d0
		lea	$3c366-$28,a0
		movem.l	d0/a0,-(a7)
		bsr	_crypt
		move.l	a0,a1
		lea	(_highs,pc),a0
		move.l	(RESLOAD),a2
		jsr	(resload_SaveFile,a2)
		movem.l	(a7)+,d0/a0

_crypt		movem.l	d0/a0,-(a7)
		subq.w	#1,d0
.lp		eor.b	d0,(a0)+
		dbf	d0,.lp
		movem.l	(a7)+,d0/a0
		rts

		; CDTV parameters
_notrainer	move.w	#3,($cd0)		;ships
		move.l	#0,($ca0)		;cash
		rts

_gametrainer	move.w	#9,($cd0)		;ships
		move.l	#100000,($ca0)		;cash
		rts

_x2		dc.b	"X2",0
	EVEN

_resload = RESLOAD

	IFD	BARFLY
	INCLUDE	Sources:whdload/keyboard.s147
	ELSE
	INCLUDE	whdload/keyboard.s
	ENDC
	
;======================================================================

	ELSE
	
;======================================================================

	;bootblock
		move.l	#0,d0			;offset
		move.l	#$400,d1		;size
		moveq	#1,d2			;disk
		lea	$1000,a0		;address
		movem.l	d1/a0,-(a7)
		jsr	(resload_DiskLoad,a5)
		movem.l	(a7)+,d0/a0
		jsr	(resload_CRC16,a5)

		;sub.l	a3,a3

		cmp.w	#$7f8f,d0
		beq	_v1			; intro, Imageworks slow zoom
		cmp.w	#$7ea7,d0
		beq	_v3			; intro, Imageworks slow zoom
		cmp.w	#$7e53,d0
		beq	_v4			; no intro
		cmp.w	#$bdce,d0
	;	cmp.w	#$e08d,d0		;without first std track in image
		beq	_v5			; intro, Bitmap Brothers slow zoom
		cmp.w	#$6827,d0
		beq	_v6			; intro, Imageworks slow zoom
		cmp.w	#$c0fb,d0	; version 2
		bne	_wrongver

;============== version 2: 			; intro, Imageworks fast zoom

_v2		move.b	#-1,$1055		;snoop ciab.prb
		patch	$10ac,_v2_1
		bsr	_flushcache
		jmp	($1018)

_v2_1		move.l	#$2c00,d0		;offset
		move.l	#$6b6c0,d1		;size
		moveq	#1,d2			;disk
		lea	$400.W,a0			;address
		jsr	(resload_DiskLoad,a5)
		lea	_pl_intro_v2(pc),a0
		sub.l	a1,a1
		jsr	(resload_Patch,a5)
		move.l	#$636,_custom+cop1lc	;snoop copper dma before list		
		jmp	$400.W

_pl_intro_v2
	PL_START
	PL_P	$63f62,_v2_2
	PL_B	$44f,$FF		;snoop ciab.prb
	PL_W	$45e,$4200,		;snoop custom.bplcon0
	PL_PS	$5f4,_keyboard
	PL_IFC2
	PL_S	$548,$FCA-$548	; skip intro
	PL_ENDIF
	PL_END
_v2_2		move.l	#$52*$1600,d0		;offset
		move.l	#$40000,d1		;size
		moveq	#1,d2			;disk
		lea	$400.W,a0			;address
		move.l  (RESLOAD),a5
		jsr	(resload_DiskLoad,a5)

		patchs	$fd4,_keyboard
		skip	($7058-$7046),$7046	;vector init
		move.b	#-1,$70ab		;snoop ciab.prb
		patch	$47d8,_32bit
		patch	$9012,_load
		skip	8,$6f86			;cash clear before each level
		patchs	$847a,_waitautofire

		lea	(_gametrainer,pc),a0
		move.l	(_custom1,pc),d0
		bne	.trained
		lea	(_notrainer,pc),a0
		patch	$853a,_v2_savehighs
.trained	move.w	#$4eb9,$6bae
		move.l	a0,$6bae+2

		lea	(_highs,pc),a0
		move.l	(RESLOAD),a5
		jsr	(resload_GetFileSize,a5)
		cmp.l	#$fc-$66+$28,d0
		bne	.nohighs
		lea	(_highs,pc),a0
		lea	$8368-$28,a1
		pea	(a1)
		jsr	(resload_LoadFileDecrunch,a5)
		move.l	(a7)+,a0
		bsr	_crypt
.nohighs
		move.l	#$e841c3fc,d0
		move.l	d0,$2d10		;access fault (lsr->asr,mulu->muls)
		move.l	d0,$2d42		;access fault (lsr->asr,mulu->muls)
		move.l	d0,$2f8e		;access fault (lsr->asr,mulu->muls)
		move.l	d0,$34d6		;access fault (lsr->asr,mulu->muls)

		bsr	_flushcache
		jmp	$400

_v2_savehighs	addq.l	#2,a7			;original
		jsr	$86aa			;original
		move.l	#$fc-$66+$28,d0
		lea	$8368-$28,a0
		bra	_savehighs

;============== version 3

_v3		move.b	#-1,$1051		;snoop ciab.prb
		patch	$10a8,.1
		bsr	_flushcache
		jmp	$1016.W

.1		move.l	#$2c00,d0		;offset
		move.l	#$6b6c0,d1		;size
		moveq	#1,d2			;disk
		lea	$400,a0			;address
		jsr	(resload_DiskLoad,a5)

		lea	$64e52,a7		;$410
		move.l	#$7670CF6B,d0		;CopyLock
		rol.l	#8,d0			;$a1a
		eor.l	#$400,d0		;$a20
		ror.l	#8,d0			;$a22
		skip	4,$64bc8		;prefetching problem on UAE
		patch	$64bf2,.2
		bsr	_flushcache
		jmp	$64bb6			;$a24

.2		move.b	#-1,$467		;snoop ciab.prb
		move.w	#$4200,$476		;snoop custom.bplcon0
		patchs	$bc2,_keyboard
		move.l	#$c02,_custom+cop1lc	;snoop copper dma before list
		patch	$63e,.3			;second copylock
		bsr	_flushcache
		jmp	$400

.3
		movem.l	d1/A0-A2,-(A7)
		move.l	RESLOAD,A2
		sub.l	a1,a1
		lea	.pl_intro(pc),a0
		jsr	(resload_Patch,a2)
		movem.l	(a7)+,d1/A0-A2
		
		bra	_common_game_v1_v3

.pl_intro:
	PL_START
	PL_P	$641D4,.4
	PL_IFC2
	PL_S	$125E,$1492-$125E
	PL_ENDIF
	PL_END
	;after intro
.4		move.l	#$70c00,d0		;offset
		move.l	#$3fc00,d1		;size
		moveq	#1,d2			;disk
		lea	$400,a0			;address
		move.l	(RESLOAD),a2
		jsr	(resload_DiskLoad,a2)
		patch	$64276,_v13_5
		bsr	_flushcache
		jmp	$64252

;============== version 1

_v1:
		move.b	#-1,$104d		;snoop ciab.prb
		patch	$10b0,.1
		bsr	_flushcache
		jmp	$1016.W

.1		move.l	#$2c00,d0		;offset
		move.l	#$6b6c0,d1		;size
		moveq	#1,d2			;disk
		lea	$400.W,a0			;address
		jsr	(resload_DiskLoad,a5)

		lea	$64de4,a7		;$410
		move.l	#$7670CF6B,d0		;CopyLock
		rol.l	#8,d0			;$a1a
		eor.l	#$400,d0		;$a20
		ror.l	#8,d0			;$a22
		;prefetching problem on UAE/non 68000?
		;skips some code that writes ILLEGAL in $64B5E
		;which is the instruction just after the current instruction
		;intended to destroy the code after it's executed??
		skip	4,$64b5a		
		patch	$64b84,.2
		
		
		bsr	_flushcache
		jmp	$64b48			;$a24

.2		move.b	#-1,$467		;snoop ciab.prb
		move.w	#$4200,$476		;snoop custom.bplcon0
		patchs	$bc2,_keyboard
		move.l	#$c02,_custom+cop1lc	;snoop copper dma before list
		patch	$63e,.3			;second copylock
		bsr	_flushcache
		jmp	$400.W

.3
		movem.l	d1/A0-A2,-(A7)
		move.l	RESLOAD,A2
		sub.l	a1,a1
		lea	.pl_intro(pc),a0
		jsr	(resload_Patch,a2)
		movem.l	(a7)+,d1/A0-A2
	
	bra	_common_game_v1_v3
	
.pl_intro:
	PL_START
	PL_P	$641D2,.4

	PL_IFC2
	PL_S	$125E,$1492-$125E
	PL_ENDIF
	PL_END
	
	;after intro
.4		move.l	#$70c00,d0		;offset
		move.l	#$3fc00,d1		;size
		moveq	#1,d2			;disk
		lea	$400,a0			;address
		move.l	(RESLOAD),a2
		jsr	(resload_DiskLoad,a2)
		patch	$64260,_v13_5
		jmp	$6423c

_common_game_v1_v3
	; but there's another strange thing that happens on WinUAE without "more compatible"
	; let's fix it (copylock key overwrites some code)
	move.l	#$7670CF6B,d0		;CopyLock
	MOVE.L #$7670cb6b,D1		; 00000B82 223c 7670 cb6b (not exactly same value)
	MOVE.L D1,(A0)				; 00000B88 2081   this overwrites the next instruction
    MOVE.L (A0),$0024 ;  00000B8A 21d0 0024  possible that this code is required for protection
	jmp	$b8e.W		; instead of jumping to $B82, no prefetch issue, and protection code is executed

	;main loaded and decrypted
_v13_5		
		patchs	$fd4,_keyboard
		move.l	#$4ef8763a,$70f6	;third copylock
		skip	($7654-$7642),$7642		;vector init
		move.b	#-1,$76d1		;snoop ciab.prb
		move.w	#$4200,$76e0		;snoop custom.bplcon0
		patch	$47ce,_32bit
		patch	$921a,_load
		skip	8,$6f7c			;cash clear before each level
		patchs	$8a58,_waitautofire
		
		lea	(_gametrainer,pc),a0
		move.l	(_custom1,pc),d0
		bne	.trained
		lea	(_notrainer,pc),a0
;;		skip	6,$7AF0	; no autofire reset when losing a life, seems not sufficent. Damn game code!
		patch	$8b18,_v13_savehighs
.trained	
		move.w	#$4eb9,$6ba4
		move.l	a0,$6ba4+2
.skipsh
		lea	(_highs,pc),a0
		move.l	(RESLOAD),a5
		jsr	(resload_GetFileSize,a5)
		cmp.l	#$fc-$66+$28,d0
		bne	.nohighs
		lea	(_highs,pc),a0
		lea	$8946-$28,a1
		pea	(a1)
		jsr	(resload_LoadFileDecrunch,a5)
		move.l	(a7)+,a0
		bsr	_crypt
.nohighs
		move.l	#$e841c3fc,$2f84	;access fault (lsr->asr,mulu->muls)

		move.l	#$7670CF6B,d0		;CopyLock
	;	move.l	#$5618,d1
		jmp	$400

_v13_savehighs	addq.l	#2,a7			;original
		jsr	$8c88			;original
		move.l	#$fc-$66+$28,d0
		lea	$8946-$28,a0
_savehighs	movem.l	d0/a0,-(a7)
		bsr	_crypt
		move.l	a0,a1
		lea	(_highs,pc),a0
		move.l	(RESLOAD),a2
		jsr	(resload_SaveFile,a2)
		movem.l	(a7)+,d0/a0

_crypt		movem.l	d0/a0,-(a7)
		subq.w	#1,d0
.lp		eor.b	d0,(a0)+
		dbf	d0,.lp
		movem.l	(a7)+,d0/a0
		rts

;============== version 4

_v4		move.l	#$400,d0		;offset
		move.l	#$28400,d1		;size
		moveq	#1,d2			;disk
		lea	$14000,a0		;address
		jsr	(resload_DiskLoad,a5)

		pea	$14000+$281b6
		pea	_v4_load(pc)
		bra	_v45_2
		
;============== version 5

_v5		moveq	#12,d1			;offset
		move.w	#$2b9,d2		;size
		lea	$18000,a0		;address
		bsr	_v5_load1

		lea	$18006,a0
		lea	$400,a1
		jsr	(resload_Decrunch,a5)
		tst.l	d0
		beq	_wrongver
		
		lea	.pl1(pc),a0
		lea	$400,a1
		jsr	(resload_Patch,a5)
		
		move.l	#$850,_custom+cop1lc	;snoop copper dma before list
		lea	$78000,a0
		move.w	#$7d00/4-1,d0
.clr		clr.l	(a0)+
		dbf	d0,.clr
		waitvb
		jmp	$400

.pl1		PL_START
		PL_S	$52,$7e-$52		;aga stuff
		PL_B	$a7,-1			;snoop ciab.prb
		PL_W	$b6,$4200		;snoop custom.bplcon0
		PL_PS	$410,_keyboard
		PL_P	$63a3e,_v5_2
		PL_IFC2
		;PL_S	$16E,$10F2-$56E
		PL_PS	$154,_shutdma_setsr
		PL_S	$15A,$10F2-$55A
		PL_ENDIF
		PL_END

	
_v5_2		bsr	_v5_load1

	;load filetable
		move.l	#$400+$50a,d0		;offset
		move.l	#$16*4,d1		;size
		moveq	#1,d2			;disk
		lea	$380,a0			;address
		move.l	RESLOAD,a5
		jsr	(resload_DiskLoad,a5)

		pea	$400
		pea	_v5_load2(pc)
		
_v45_2		lea	$14006,a0
		lea	$400,a1
		jsr	(resload_Decrunch,a5)
		tst.l	d0
		beq	_wrongver
		
		lea	.pl(pc),a0
		lea	$400,a1
		jsr	(resload_Patch,a5)
		
		lea	$400+$90e2,a0
		move.w	#$4ef9,(a0)+
		move.l	(a7)+,(a0)+
		
		lea	(_gametrainer,pc),a0
		move.l	(_custom1,pc),d0
		bne	.trained
		lea	(_notrainer,pc),a0
		patch	$400+$85f2,_v45_savehighs
.trained	move.l	#$4e714eb9,$400+$6a34
		move.l	a0,$400+$6a34+4

		lea	(_highs,pc),a0
		move.l	(RESLOAD),a5
		jsr	(resload_GetFileSize,a5)
		cmp.l	#$fc-$66+$28,d0
		bne	.nohighs
		lea	(_highs,pc),a0
		lea	$400+$840e-$28,a1
		pea	(a1)
		jsr	(resload_LoadFileDecrunch,a5)
		move.l	(a7)+,a0
		bsr	_crypt
.nohighs
		move.l	#$400+$c0e,_custom+cop1lc	;snoop copper dma before list

		rts

.pl		PL_START
		PL_PS	$ba6,_keyboard
		PL_L	$2714,$e841c3fc		;access fault (lsr->asr,mulu->muls)
		PL_L	$2744,$e841c3fc		;access fault (lsr->asr,mulu->muls)
		PL_L	$298e,$e841c3fc		;access fault (lsr->asr,mulu->muls)
		PL_L	$2f12,$e841c3fc		;access fault (lsr->asr,mulu->muls)
		PL_P	$431a,_32bit
		PL_S	$6eae,12		;cash clear before each level
		PL_S	$6f8c,$6fa2-$6f8c	;vector init
		PL_B	$7029,-1		;snoop ciab.prb
		PL_PS	$8526,_waitautofire
		PL_P	$957a,_decrunch
		PL_END

_v45_savehighs	addq.l	#2,a7			;original
		jsr	$400+$8760		;original
		move.l	#$fc-$66+$28,d0
		lea	$400+$840e-$28,a0
		bra	_savehighs

_decrunch	movem.l	d0-d1/a0-a2,-(a7)
		move.l	(RESLOAD),a2
		jsr	(resload_Decrunch,a2)
		tst.l	d0
		beq	_wrongver
		movem.l	(a7)+,d0-d1/a0-a2
		rts

;============== version 6

_v6	;	bra	_v6main

		move.l	#0,d0			;offset
		move.l	#$4b170,d1		;length
		moveq	#1,d2			;disk
		lea	$400,a0			;address
		jsr	(resload_DiskLoad,a5)

		move.l	#$63d9c,d1
		lea	$4b570,a0
		lea	$400,a1
		bsr	_v6decrunch
		lea	.pl(pc),a0
		lea	0,a1
		jsr	(resload_Patch,a5)
		
		move.l	#$c02,$dff080		;copper list
		lea	$78000,a0
		move.w	#$8000/4-1,d0
.clr		clr.l	(a0)+			;clear screen
		dbf	d0,.clr
		jmp	$400

.pl		PL_START
		PL_W	$476,$4200		;snoop custom.bplcon0
		PL_S	$578,$125c-$578		;skip protection
		PL_PS	$bc2,_keyboard
		PL_P	$1498,_v6main
		PL_IFC2
		PL_S	$125E,$1492-$125E
		PL_ENDIF
		PL_END

_v6main		lea	_custom,a6
		waitvb	a6
		move.w	#$7fff,(intena,a6)
		move.w	#$7fff,(dmacon,a6)

		move.l	#($30-3)*$1b00,d0	;offset
		move.l	#$2b120-$e0c,d1		;length
		moveq	#1,d2			;disk
		lea	$e0c,a0			;address
		move.l	(RESLOAD),a5
		jsr	(resload_DiskLoad,a5)

		move.l	#$3f1f4,d1
		lea	$2b120,a0
		lea	$e0c,a1
		bsr	_v6decrunch
		
		lea	.pl(pc),a0
		sub.l	a1,a1
		jsr	(resload_Patch,a5)

		lea	(_gametrainer,pc),a0
		move.l	(_custom1,pc),d0
		bne	.trained
		lea	(_notrainer,pc),a0
		patch	$8b18,.savehighs
.trained	move.w	#$4eb9,$6ba4
		move.l	a0,$6ba4+2

		lea	(_highs,pc),a0
		move.l	(RESLOAD),a5
		jsr	(resload_GetFileSize,a5)
		cmp.l	#$fc-$66+$28,d0
		bne	.nohighs
		lea	(_highs,pc),a0
		lea	$8946-$28,a1
		pea	(a1)
		jsr	(resload_LoadFileDecrunch,a5)
		move.l	(a7)+,a0
		bsr	_crypt
.nohighs
		move.l	#$1038,$dff080		;copper list init
		jmp	$762e

.pl		PL_START
		PL_PS	$fd4,_keyboard
		PL_L	$2d06,$e841c3fc		;access fault (lsr->asr,mulu->muls)
		PL_L	$2d38,$e841c3fc		;access fault (lsr->asr,mulu->muls)
		PL_L	$2f84,$e841c3fc		;access fault (lsr->asr,mulu->muls)
		PL_L	$34cc,$e841c3fc		;access fault (lsr->asr,mulu->muls)
		PL_P	$47ce,_32bit
		PL_S	$6f7c,8			;cash clear before each level
		PL_S	$7642,$7654-$7642	;vector init
		PL_S	$76c6,3*8		;cia access
		PL_W	$76e0,$4200		;bplcon0
		PL_PS	$8a58,_waitautofire
		PL_P	$921a,.loader
		PL_END

.savehighs	addq.l	#2,a7			;original
		jsr	$8c88			;original
		move.l	#$fc-$66+$28,d0
		lea	$8946-$28,a0
		bra	_savehighs

; d0=filenumber (d1=) (a0=address)

.loader		move.w	d0,d4
		lea	$9512,a0		;filetable
		moveq	#0,d0
		moveq	#0,d1
		moveq	#-1,d7
.search		move.w	(a0)+,d2
		move.b	(a0)+,d0		;start track
		move.b	(a0)+,d1		;count tracks
		addq.w	#1,d7
		cmp.w	d4,d2
		bne	.search
		
		sub.w	#3,d0			;diskimage starts at track 3
		mulu	#$1b00,d0		;offset
		mulu	#$1b00,d1		;length
		moveq	#1,d2			;disk
		lea	$54e00,a0
		move.l	(RESLOAD),a5
		jsr	(resload_DiskLoad,a5)
		
		lsl.w	#4,d7
		lea	$94b2,a6		;fileaddresstable
		add.w	d7,a6
		moveq	#0,d5
		lea	$54e00,a0
		move.l	a0,a1			;start
		add.l	(a6)+,a0		;end packed
		move.l	(a6)+,d1		;unpacked length
		lea	(a1,d1.l),a2		;end unpacked
		
	move.l	-(a0),d0
	eor.l	d0,d5
.93C8	lsr.l	#1,d0
	bne.b	.93D0
	bsr.w	.944A
.93D0	bcs.b	.940A
	moveq	#8,d1
	moveq	#1,d3
	lsr.l	#1,d0
	bne.b	.93DE
	bsr.w	.944A
.93DE	bcs.b	.9434
	moveq	#3,d1
	clr.w	d4
.93E4	bsr.w	.9456
	move.w	d2,d3
	add.w	d4,d3
.93EC	moveq	#7,d1
.93EE	lsr.l	#1,d0
	bne.b	.93F6
	bsr.w	.944A
.93F6	roxl.l	#1,d2
	dbra	d1,.93EE
	move.b	d2,-(a2)
	dbra	d3,.93EC
	bra.b	.9442

.9404	moveq	#8,d1
	moveq	#8,d4
	bra.b	.93E4

.940A	moveq	#2,d1
	bsr.w	.9456
	cmp.b	#2,d2
	blt.b	.942A
	cmp.b	#3,d2
	beq.b	.9404
	moveq	#8,d1
	bsr.w	.9456
	move.w	d2,d3
	move.w	#8,d1
	bra.b	.9434

.942A	move.w	#8,d1
	add.w	d2,d1
	addq.w	#2,d2
	move.w	d2,d3
.9434	bsr.w	.9456
.9438	subq.w	#1,a2
	move.b	(a2,d2.w),(a2)
	dbra	d3,.9438
.9442	cmpa.l	a2,a1
	blt.b	.93C8
	tst.l	d5
	bra.b	.9470

.944A	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#$10,ccr
	roxr.l	#1,d0
	rts

.9456	subq.w	#1,d1
	clr.w	d2
.945A	lsr.l	#1,d0
	bne.b	.9468
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#$10,ccr
	roxr.l	#1,d0
.9468	roxl.l	#1,d2
	dbra	d1,.945A
	rts

.9470	lea	($54E00).l,a0	;run length decompressor
	move.b	(a6),d7
	move.l	(a6)+,d0
	andi.l	#$FFFFFF,d0
	lea	(a0,d0.l),a2
	move.l	(a6),d0
	lea	(a0,d0.l),a1
.948A	cmpa.l	a0,a2
	ble.b	.94A4
	move.b	-(a2),d1
	cmp.b	d1,d7
	beq.b	.9498
	move.b	d1,-(a1)
	bra.b	.948A

.9498	move.b	-(a2),d4
	move.b	-(a2),d5
.949C	move.b	d4,-(a1)
	subq.b	#1,d5
	bne.b	.949C
	bra.b	.948A

.94A4	cmp.b	#$10,d6
	bne.b	.94B0
	move.b	#$AA,(3,a0)
.94B0	rts

; d1=unpacked-length a0=end-packed a1=start

_v6decrunch
	lea	(a1,d1.l),a2
	move.l	-(a0),d0
.248	add.l	d0,d0
	bne.b	.254
	move.l	-(a0),d0
	move.w	#$10,ccr
	addx.l	d0,d0
.254	bcs.b	.2AA
	moveq	#8,d1
	moveq	#1,d3
	add.l	d0,d0
	bne.b	.266
	move.l	-(a0),d0
	move.w	#$10,ccr
	addx.l	d0,d0
.266	bcs.w	.2F8
	moveq	#3,d1
	clr.w	d4
.26E	subq.w	#1,d1
	clr.w	d2
.272	add.l	d0,d0
	bne.b	.27E
	move.l	-(a0),d0
	move.w	#$10,ccr
	addx.l	d0,d0
.27E	addx.l	d2,d2
	dbra	d1,.272
	move.w	d2,d3
	add.w	d4,d3
.288	moveq	#7,d1
.28A	add.l	d0,d0
	bne.b	.296
	move.l	-(a0),d0
	move.w	#$10,ccr
	addx.l	d0,d0
.296	addx.l	d2,d2
	dbra	d1,.28A
	move.b	d2,-(a2)
	dbra	d3,.288
	bra.b	.318

.2A4	moveq	#8,d1
	moveq	#8,d4
	bra.b	.26E

.2AA	moveq	#2,d1
	subq.w	#1,d1
	clr.w	d2
.2B0	add.l	d0,d0
	bne.b	.2BC
	move.l	-(a0),d0
	move.w	#$10,ccr
	addx.l	d0,d0
.2BC	addx.l	d2,d2
	dbra	d1,.2B0
	cmpi.b	#2,d2
	blt.b	.2EE
	cmpi.b	#3,d2
	beq.b	.2A4
	moveq	#8,d1
	subq.w	#1,d1
	clr.w	d2
.2D4	add.l	d0,d0
	bne.b	.2E0
	move.l	-(a0),d0
	move.w	#$10,ccr
	addx.l	d0,d0
.2E0	addx.l	d2,d2
	dbra	d1,.2D4
	move.w	d2,d3
	move.w	#8,d1
	bra.b	.2F8

.2EE	move.w	#8,d1
	add.w	d2,d1
	addq.w	#2,d2
	move.w	d2,d3
.2F8	subq.w	#1,d1
	clr.w	d2
.2FC	add.l	d0,d0
	bne.b	.308
	move.l	-(a0),d0
	move.w	#$10,ccr
	addx.l	d0,d0
.308	addx.l	d2,d2
	dbra	d1,.2FC
.30E	subq.w	#1,a2
	move.b	(a2,d2.w),(a2)
	dbra	d3,.30E
.318	cmpa.l	a2,a1
	blt.w	.248
	rts

;============== all floppy versions (not CDTV)
; $C92/$C96 (long): target score/score
; $C9F: speed
; $CF0.W: nb continues: doesn't work
; $C61/$C65: repeat freq/autofire level start 8/1 => 6/3 with 2 autofire
; $CC6 ($C67): health: max $27
; $CA3: nashwan timer: $AA
; V3: 7AF0 (3 NOP): resets autofire, 7B00 (2 NOP): sub life

_notrainer	move.w	#3,($cca)		;ships
		move.l	#0,($c9a)		;cash
		rts

_gametrainer	move.w	#9,$cca.w		;ships
		move.l	#100000,$c9a.w		;cash
		rts
		
		; this part isn't working properly, too hard to debug this bloody game, and its 7 versions
		IFEQ	1
_powerup:
		move.l	d0,-(a7)
		move.l	_custom3(pc),d0
		beq.b	.noenhance
		move.w	#3,$c9e.w		; speed = 3
		move.w	#6,$c60.w		; fire freq = 6 (faster, normal is 8)
		move.w	#3,$c64.w       ; number of autofire items taken: 3 (max)
		;;move.b	#$44,$C85	; if set, picking rear shot doesn't do anything
.noenhance
		move.l	(a7)+,d0
		rts
		ENDC

_v5_load1	move.l	d1,d0
		move.l	d2,d1
_v5_load2	sub.w	#1,d0			;first track only $1600
_v4_load	moveq	#1,d2			;disk
		bra	_load0
_load		moveq	#2,d2			;disk
_load0		mulu	#512,d0			;offset
		mulu	#512,d1			;size
		move.l	a0,-(a7)
		add.l	d1,(a7)
		move.l	(RESLOAD),a2
		jsr	(resload_DiskLoad,a2)
		move.l	(a7)+,a0
		moveq	#0,d0
		rts

	ENDC

;======================================================================

; wait a specific time the fire button hasn't been pressed
; to avoid filling the highscore name with autofire

_waitautofire	move.b	#$3a,(12,a1)		;original

		movem.l	d0-d2,-(a7)
.reset		moveq	#50,d0
		btst	#0,(_custom+vposr+1)
		seq	d1

.test		btst	#7,$bfe001
		beq	.reset
		btst	#0,(_custom+vposr+1)
		seq	d2
		cmp.b	d1,d2
		beq	.test
		move.b	d2,d1
		dbf	d0,.test

		movem.l	(a7)+,d0-d2
		rts

_flushcache:
	move.l	a2,-(a7)
	move.l	RESLOAD,a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

; useful to shut DMA and set SR when skipping intro
_shutdma_setsr:
	move.w	#$2000,SR
	move.w	#$4000,$DFF096
	rts
	
_keyboard	move.l	d1,-(a7)
		cmp.b	_keyexit(pc),d0
		bne.b	.noquit
		; JOTD added quitkey for 68000 (floppy version)		
		pea	TDREASON_OK
		move.l	RESLOAD,-(a7)
		addq.l	#resload_Abort,(a7)
		rts
.noquit
		moveq	#3-1,d1
.wait1		move.b	(_custom+vhposr),d0
.wait2		cmp.b	(_custom+vhposr),d0
		beq	.wait2
		dbf	d1,.wait1
		move.l	(a7)+,d1
		rts

_32bit		move.l	a0,-(a7)
		exg.l	d1,a1
		and.l	#$00ffffff,d1
		exg.l	d1,a1
		jsr	(a1)
		move.l	(a7)+,a0
		rts

_wrongver	pea	TDREASON_WRONGVER
		bra	_end
_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
_end		move.l	(RESLOAD),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================

_control	dc.l	WHDLTAG_MONITOR_GET
_monitor	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
_custom3	dc.l	0
		dc.l	TAG_DONE
_highs		dc.b	"highs",0

;======================================================================

	END

