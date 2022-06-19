;*---------------------------------------------------------------------------
;  :Modul.	deepcorecd.asm
;  :Contents.	slave for "Deep Core CD³²"
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: deepcorecd.asm 1.9 2009/08/10 22:15:39 wepl Exp wepl $
;  :History.	18.06.09 started
;		01.07.09 option menu can be selected with space key
;		31.07.09 support for second (newer!) version 100 added
;		08.08.09 finally fixed 2nd version
;  :Requires.	kick31.s
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	BASM 2.16, ASM-One 1.44, Asm-Pro 1.17, PhxAss 4.38
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"wart:d/deepcore/DeepCoreCD.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimize warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $1d3000
FASTMEMSIZE	= 0	;$19000 problems on game start
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;BOOTBLOCK
BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
;CACHE
;DEBUG
;DISKSONBOOT
DOSASSIGN
;FONTHEIGHT	= 8
HDINIT
;HRTMON
;INITAGA
;INIT_AUDIO
;INIT_GADTOOLS
INIT_LOWLEVEL
;INIT_MATHFFP
IOCACHE		= 1024
JOYPADEMU
MEMFREE	= $200
;NEEDFPU
;NO68020
;POINTERTICKS	= 1
;PROMOTE_DISPLAY
;STACKSIZE	= 6000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $59	;F10

;============================================================================

	INCLUDE	whdload/kick31.s

;============================================================================

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
slv_CurrentDir		dc.b	"data",0
slv_name		dc.b	"Deep Core CD³²",0
slv_copy		dc.b	"1993 ICE",0
slv_info		dc.b	"adapted by Wepl & JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
_cd32		dc.b	"cd32",0
_loader		dc.b	"loader.exe",0
slv_config
	dc.b	"BW;"
	dc.b    "C1:X:infinite lives:0;"
	dc.b    "C1:X:infinite oxygen:1;"
	dc.b    "C2:B:use 2nd button for jump;"
	dc.b	0

	EVEN

;============================================================================

_bootdos	move.l	(_resload,pc),a2	;A2 = resload

	;assigns
		lea	(_cd32,pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		lea	_loader(pc),a0
		lea	$1f000,a1
		move.l	a1,a3
		jsr	(resload_LoadFileDecrunch,a2)

		move.l	a3,a0
		jsr	(resload_CRC16,a2)
		lea	_pl_loader_101(pc),a4
		cmp.w	#$ab39,d0
		beq	.crcok
		lea	_pl_loader_100(pc),a4
		cmp.w	#$bb24,d0
		beq	.crcok
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)
.crcok
		move.l	a3,a0
		sub.l	a1,a1
		jsr	(resload_Relocate,a2)

		move.l	a4,a0
		move.l	a3,a1
		jsr	(resload_Patch,a2)

		jmp	(4,a3)

_pl_loader_101	PL_START
		;PL_S	$ca,6			;skip loaderintro
		;PL_S	$dc,$1a4-$dc		;enter outro
		PL_W	$1a6,$2			;redirect outro load from $120000->$20000
		PL_R	$20c			;skip swap mem
		PL_P	$266,_dosload
		PL_W	$304,$200		;bplcon0.color
		PL_W	$3a4,$200		;bplcon0.color
		PL_END

_pl_loader_100	PL_START
		;PL_S	$57+$5a,6		;skip loaderintro
		;PL_S	$57+$6c,$138-$6c	;enter outro
		PL_W	$57+$13a,$2		;redirect outro load from $120000->$20000
		PL_R	$57+$1a0		;skip swap mem
		PL_P	$57+$1fa,_dosload
		PL_W	$57+$2a0,$200		;bplcon0.color
		PL_W	$57+$340,$200		;bplcon0.color
		PL_END

_dosload	exg.l	a0,a1
_dosload2	movem.l	d0-d2/a0-a2,-(a7)
		addq.l	#5,a0			;skip "CD32:"
		move.l	_resload(pc),a2
		move.w	#$4000,_custom+intena
		jsr	(resload_LoadFileDecrunch,a2)
		move.w	#$C000,_custom+intena

		lea	_pl_loaderintro_101(pc),a0
		cmp.l	#158246,d0
		beq	.patch

		lea	_pl_loaderintro_100(pc),a0
		cmp.l	#158250,d0
		beq	.patch

		lea	_pl_fireintro(pc),a0
		cmp.l	#287792,d0
		beq	.patch

		lea	_pl_option(pc),a0
		cmp.l	#83048,d0
		beq	.patch

		cmp.l	#509144,d0
		bne	.not_game
		move.l	(16,a7),a0
		jsr	(resload_CRC16,a2)
		move.l	d0,d2			;d2 = crc
		move.l	_attnflags(pc),d1
		btst	#AFB_68030,d1
		beq	.no30
		lea	_pl_game_30(pc),a0
		move.l	(16,a7),a1
		jsr	(resload_Patch,a2)
.no30
		lea	_pl_game_101(pc),a0
		cmp.w	#$87ac,d2
		beq	.crcok
		lea	_pl_game_100(pc),a0
		cmp.w	#$2af,d2
		beq	.crcok
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)
.crcok
		move.l	(16,a7),a1
		add.l	#$239b4,a1
		move.w	#($23be8-$239b4)/4-1,d0
.game1		move.l	#$1fe0000,(a1)+		;fix empty clist
		dbf	d0,.game1
		bra	.patch
.not_game
		lea	_pl_outro(pc),a0
		cmp.l	#327680,d0
		beq	.patch
.quit
		movem.l	(a7)+,_MOVEMREGS
		rts

.patch		move.l	(16,a7),a1
		jsr	(resload_Patch,a2)
		clr.l	-(a7)
		move.l	(20,a7),-(a7)
		pea	WHDLTAG_DBGADR_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add.w	#12,a7
		bra	.quit

_pl_loaderintro_101
		PL_START			;1000c0 jmp offset 1f700

		PL_S	$1f7cc,$d6-$cc		;cacr
		PL_PS	$1fdfc,_b3
		PL_PS	$1fe80,_b4
		PL_PS	$1ff4e,_lace3
		PL_S	$1ff5e,8		;cop1lc copjmp1
		PL_P	$1ff8a,.lace1
		PL_PS	$1ff9a,_lace3
		PL_S	$1ffae,8		;cop1lc copjmp1
	;	PL_S	$1ffda,6		;vposw
		PL_S	$1ffda,12		;vposw bplcon0
		PL_P	$2000e,.lace2
		PL_L	$2038a,-2		;clist_coplc
		PL_P	$2227a,_dosload
		PL_PS	$22674,_b1
		PL_PS	$22c30,_b2
		PL_PS	$25b52,_lace3		;copper dma off
		PL_S	$25b66,8		;cop1lc copjmp1
		PL_P	$25bdc,.lace4
		PL_END

.lace1		move.b	#$f4,$1000c0+$20248	;original
		move.l	a0,(cop1lc,a6)
		tst.w	(copjmp1,a6)
		rts

.lace2		move.l	#$1000c0+$20242,(cop1lc,a6)
		tst.w	(copjmp1,a6)
		rts

.lace4		move.l	#$1000c0+$25cee,(cop1lc,a6)
		tst.w	(copjmp1,a6)
		rts

_pl_loaderintro_100
		PL_START			;1000c0 jmp offset 1f700
		PL_S	$1f7cc,$d6-$cc		;cacr
	;	PL_S	$1f7e0,6		;beamcon0
	;	PL_BKPT	$1f850
		PL_PS	$1fe00,_b3
		PL_PS	$1fe84,_b4
		PL_PS	$1ff52,_lace3
		PL_S	$1ff62,8		;cop1lc copjmp1
		PL_P	$1ff8e,.lace1
		PL_PS	$1ff9e,_lace3
		PL_S	$1ffb2,8		;cop1lc copjmp1
	;	PL_S	$1ffde,6		;vposw
		PL_S	$1ffde,12		;vposw bplcon0
		PL_P	$20012,.lace2
		PL_L	$2038e,-2		;clist_coplc
		PL_P	$2227e,_dosload
		PL_PS	$22678,_b1
		PL_PS	$22c34,_b2
		PL_PS	$25b56,_lace3		;copper dma off
		PL_S	$25b6a,8		;cop1lc copjmp1
		PL_P	$25be0,.lace4
		PL_END

.lace1		move.b	#$f4,$1000c0+$2024c	;original
		move.l	a0,(cop1lc,a6)
		tst.w	(copjmp1,a6)
		rts

.lace2		move.l	#$1000c0+$20246,(cop1lc,a6)
		tst.w	(copjmp1,a6)
		rts

.lace4		move.l	#$1000c0+$25cf2,(cop1lc,a6)
		tst.w	(copjmp1,a6)
		rts

_lace3		lea	_custom,a6		;original
		waitvb	a6
.lace31		tst.w	(vposr,a6)		;lof/sof (in case lace was active already)
		bpl	.lace31
		rts

_pl_fireintro	PL_START			;12f0e0 jmp offset 31844

	;	PL_I	$31844
		PL_P	$317d4,_dosload2
		PL_P	$3180e,_dosload2
		PL_PS	$31dbc,_b5
		PL_PS	$31e74,_b5
		PL_ORW	$31f72,INTF_PORTS	;enable keyboard
		PL_PS	$3219e,.option
		PL_PS	$3207a,_b6
		PL_END

.option		btst	#14,(potinp,a6)		;original
		beq	.rts
		movem.l	d0-d1/a0-a1/a6,-(a7)
		lea	_lowlevelname(pc),a1
		move.l	4,a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6
		jsr	(_LVOGetKey,a6)
		cmp.w	#$40,d0			;space
		movem.l	(a7)+,_MOVEMREGS
.rts		rts

GAME_START = $101b28

_pl_game	PL_START			;101b28 jmp offset 13c58

		PL_P	$13e0e,_dosload
		PL_B	$1f3e9,1		;ReadJoyPort port=1
		PL_PSS	$120f12-GAME_START,_inputhook,4	; note: offset was wrong
		PL_B	$1f583,1		;ReadJoyPort port=1
		PL_B	$1f58f,1		;ReadJoyPort port=1
		PL_B	$1f59d,1		;ReadJoyPort port=1
		PL_ORW	$211a6,INTF_PORTS	;enable keyboard

		PL_IFC1X	0
		PL_NOP		$1214c2-GAME_START,8	; lives
		PL_ENDIF

		PL_IFC1X	1
		PL_NOP		$12162e-GAME_START,6	; oxygen
		PL_ENDIF

		PL_END

_pl_game_101	PL_START			;101b28 jmp offset 13c58

		PL_IFC2
		PL_PSS	$11edde-GAME_START,_readjoy,2
		PL_ENDIF
		
		; access fault
		PL_PS	$120612-GAME_START,_fix_access_fault_101
		PL_PSS	$120638-GAME_START,_fix_access_fault_2,6
		
		PL_PSS	$117830-GAME_START,_door_enter_test_101,2
		


		PL_S	$13eb2,$c6-$b2		;cacr
		PL_ORW	$13fc2,INTF_PORTS	;enable keyboard
		PL_NEXT	_pl_game

_pl_game_100	PL_START			;101b28 jmp offset 13c58

		PL_IFC2
		PL_PSS	$11ede0-GAME_START,_readjoy,2
		PL_ENDIF
		
		; access fault
		PL_PS	$120614-GAME_START,_fix_access_fault_100
		PL_PSS	$12063a-GAME_START,_fix_access_fault_2,6
		
		PL_PSS	$11783c-GAME_START,_door_enter_test_100,2
		
		
		
		PL_S	$13ebe,$c6-$b2		;cacr
		PL_ORW	$13fce,INTF_PORTS	;enable keyboard
		PL_NEXT	_pl_game

_pl_game_30	PL_START
		PL_PS	$1faa2,_b5
		PL_PS	$1fb44,_b5
		PL_PS	$1fcde,_b8
		PL_PS	$20152,_b7
		PL_PS	$2022a,_b9
		PL_PS	$2028a,_b7
		PL_PS	$202b0,_b10
		PL_PS	$2031a,_b5
		PL_PS	$203e8,_b7
		PL_PS	$205a8,_b5

		PL_R	$20e32
		PL_P	$20f70,_bx1
		PL_P	$20fc0,_bx2
		PL_PS	$217de,_b5
		PL_END

_pl_option	PL_START			;108000 jmp offset 2000
		PL_PS	$2078,.chkdown
		PL_PS	$208c,.chkdown
		PL_ORW	$228a,INTF_PORTS	;enable keyboard
		PL_PS	$27be,_b5
		PL_PS	$29b2,_b2
		PL_END

.chkdown	waitvb	a6
		btst	#14,(potinp,a6)		;original
		beq	.rts
		btst	#7,$bfe001
.rts		rts
		

_pl_sectioload	PL_START			;181000 jmp offset 0
		PL_END

_pl_outro	PL_START			;20000 jmp offset 29000
		PL_PS	$2940c,_b5
		PL_END

_b1		bsr	_bw6
		clr.l	($64,a6)
		addq.l	#2,(a7)
		rts

_b2		or.w	d2,d0
		bsr	_bw6
		move.l	d0,($40,a6)
		rts

_b5		bsr	_bw6
		move.l	#$9f00000,($40,a6)
		addq.l	#2,(a7)
		rts

_b6		bsr	_bw6
		move.l	#$ffff0000,($44,a6)
		addq.l	#2,(a7)
		rts

_b8		bsr	_bw6
		move.w	#$26,($66,a6)
		rts

_b9		and.w	#15,d5
		ror.w	#4,d5
		bra	_bw6

_b10		add.l	#$2c,a3
		bra	_bw6

_b7		or.w	d5,d6
		swap	d6
		or.w	d5,d6

_bw6		BLITWAIT a6
		rts
		
_b3		sub.l	#$9c40,a1
		bra	_bw

_b4		move.l	#$16c760,a6

_bw		BLITWAIT
		rts

DELAY	MACRO
		BLITWAIT a6
		;tst.b	$bfe001
	ENDM

_bx1		moveq	#11,d5
.2		moveq	#19,d6
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

_bx2
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


_readjoy
	MOVE.W	(12,A6),D0		;1ee6a: 302e000c

	move.l	d1,-(a7)
	move.l	joy1(pc),d1
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d0
	btst	#9,d0
	beq.b	.noneed
	bset	#8,d0	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BUTTON_BLUE,d1
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d0
	btst	#9,d0
	bne.b	.no_blue
	bset	#8,d0	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
	move.l	(a7)+,d1	
	; original
	BTST	#1,D0			;1ee6e: 08000001
	rts
	
_fix_access_fault_100
	and.l	#$FFFFFF,d0	; 24 bit style access fault I hope...
	TST.W	$11f4ae
	rts

_fix_access_fault_101
	and.l	#$FFFFFF,d0	; 24 bit style access fault I hope...
	TST.W	$11f4ac
	rts
	
_fix_access_fault_2
	cmp.l	#CHIPMEMSIZE,A1
	bcc.b	.out
	; looks like setting chip address in a copperlist
	MOVE.L	D1,(A1)			;12063a: 2281
	MOVE.W	D0,(4,A0)		;12063c: 31400004
	SWAP	D0			;120640: 4840
	MOVE.W	D0,(A0)			;120642: 3080
	SWAP	D0			;120644: 4840
.out
	rts

_door_enter_test_101
	CMPI.B	#$09,$11eeb8
	bne.b	_do_enter
	rts
	
_door_enter_test_100
	CMPI.B	#$09,$11eeba
	beq.b	_de_end
_do_enter
	; alternate method: button 3 / green
	movem.l	d0,-(a7)
	move.l	joy1(pc),d0
	not.l	d0		; inverted logic!
	btst	#JPB_BUTTON_GREEN,d0
	movem.l	(a7)+,d0
_de_end
	rts	

_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

_inputhook	jsr	(_LVOGetKey,a6)
		cmp.b	_keyexit(pc),D0
		beq.b	_quit
		cmp.b	#$19,d0			;p
		beq	.pause
		move.l	a6,-(a7)
		lea	_custom,a6
		cmp.b	#$45,d0			;esc
		bne	.2
		jmp	GAME_START+$1f54e
.2		jsr	GAME_START+$1f5b4
		move.l	(a7)+,a6

.quit		moveq	#1,d0
		jsr	(_LVOReadJoyPort,a6)
		lea	joy1(pc),a0
		move.l	d0,(a0)
		lea	_custom,a6		;original
		rts

.pause		move.w	#DMAF_AUD0|DMAF_AUD1|DMAF_AUD2|DMAF_AUD3|DMAF_AUDIO,(dmacon+_custom)
.p1		jsr	(_LVOGetKey,a6)
		cmp.b	#$ff,d0
		bne	.p1
.p2		jsr	(_LVOGetKey,a6)
		cmp.b	#$19,d0
		bne	.p2
.p3		jsr	(_LVOGetKey,a6)
		cmp.b	#$ff,d0
		bne	.p3
		bra	.quit
		
joy1
	dc.l	0
_lowlevelname
	dc.b	"lowlevel.library",0
;============================================================================

	END

