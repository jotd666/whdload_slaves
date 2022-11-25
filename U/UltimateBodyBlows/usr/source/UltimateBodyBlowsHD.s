;*---------------------------------------------------------------------------
;  :Program.	UltimateBodyBlowsHD.asm
;  :Contents.	Slave for "UltimateBodyBlows"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: UltimateBodyBlowsHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
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
	OUTPUT	"UltimateBodyBlows.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $180000
FASTMEMSIZE	= $80000
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;DEBUG
HDINIT
INITAGA
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
CACHE
BOOTDOS
FORCEPAL

;============================================================================

KICKSIZE	= $80000			;40.068
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	15			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ReqAGA|WHDLF_EmulPriv|WHDLF_Examine	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_assign1
	dc.b	"CD0",0

_name		dc.b	"Ultimate Body Blows CD³²",0
_copy		dc.b	"1994 Team 17",0
_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Set CUSTOM1=1 to enable joypad controls",10,10
		dc.b	"Version 1.1 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_data:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"BBCD",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	;initialize kickstart and environment
		bra	_boot

_bootdos
	clr.l	$0.W

	bsr	_patchkb

	move.l	(_resload,pc),a2		;A2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patchexe(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist

CLISTSIZE = $F88A-$D9DE

_patchexe:
	movem.l	d0-a6,-(a7)
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1

	lea	_pl_main(pc),a0
	jsr	resload_Patch(a2)

	move.l	_custom1(pc),d0
	bne.b	.skipjp
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1

	lea	_pl_joy(pc),a0
	jsr	resload_Patch(a2)
.skipjp

	move.l	$4.W,a6
	moveq.l	#MEMF_CHIP,d1
	move.l	#CLISTSIZE,d0
	jsr	_LVOAllocMem(a6)
	move.l	d0,a3

	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1
	
	add.l	#$1D9DE,a1
	move.l	a1,a2

	move.l	#CLISTSIZE/2,d1
.copycl
	move.w	(a2)+,(a3)+
	subq.l	#1,d1
	bne.b	.copycl

	; now, relocate

	move.l	d0,a3		; start of chipmem where copperlist is
	sub.l	a3,a1		; a1: offset to substract

	lea	offsets(pc),a0
	move.l	d7,a2
	add.l	a2,a2
	add.l	a2,a2
	addq.l	#4,a2
.reloc:
	move.l	(a0)+,d0
	bmi.b	.out
	move.l	(a2,d0.l),d1
	sub.l	a1,d1
	move.l	d1,(a2,d0.l)
	bra.b	.reloc
.out
	bsr	_flushcache
	movem.l	(a7)+,d0-a6
	rts

_pl_joy:
	PL_START
	; force joystick controls

	PL_L	$0F82,$4E714E71
	PL_B	$D578,$60
	PL_B	$D646,$60
	PL_P	$D6A2,_joytest
	PL_W	$E142,$0001	; default: joystick controls
	PL_END

_pl_main
	PL_START

	; fix blitter waits

	PL_PS	$6E94,_blit_it
	PL_PS	$6EB4,_blit_it
	PL_PS	$6ED4,_blit_it
	PL_PS	$6EFA,_blit_it
	PL_PS	$6F1E,_wait_2
	PL_PS	$6F46,_wait_2

	IFD	SNOOPCHK
	; colorbit stuff in copperlists
        PL_W $1D9EA,$01FE
        PL_W $1DE66,$01FE
        PL_W $1E1BE,$01FE
        PL_W $1EADA,$01FE
        PL_W $1EAE2,$01FE
        PL_W $1EF3A,$01FE
        PL_W $1F61E,$01FE
        PL_W $1F882,$01FE

	ENDC

	PL_END

_blit_it:
	MOVE	D3,88(A6)		;06EB4: 3D430058	; PTC
	bsr	_waitblit
	LEA	0(A2,D0),A2		;06EB8: 45F20000
	addq.l	#2,(a7)
	rts

_wait_2:
	move.l	$FAC.W,a2	; stolen code
	bsr	_waitblit
	rts

_waitblit:
.wait
	BTST	#6,dmaconr+_custom
	BNE.S	.wait
	rts

; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)

_load_exe:
	movem.l	d0-a6,-(a7)
	move.l	d0,d2
	move.l	a0,a3
	move.l	a1,a4
	move.l	a0,d1
	bsr	_patch_alloc
	jsr	(_LVOLoadSeg,a6)
	bsr	_rem_patch_alloc
	move.l	d0,d7			;D7 = segment
	beq	.end			;file not found

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	jsr	(a5)
.skip
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

	move.l	a4,a0
	move.l	($44,a7),d0		;stacksize
	sub.l	#5*4,d0			;required for MANX stack check
	movem.l	d0/d7/a2/a6,-(a7)
	move.l	d2,d0			; argument string length
	jsr	(4,a1)
	movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)

	movem.l	(a7)+,d0-a6
	rts

.end
	move.l	a3,-(a7)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_patch_alloc:
	movem.l	a0/a1,-(a7)
	move.l	$4.W,A0
	add.w	#_LVOAllocMem+2,a0
	lea	_alloc_save(pc),a1
	move.l	(a0),(a1)
	lea	_my_alloc(pc),a1
	move.l	a1,(a0)
	bsr	_flushcache
	movem.l	(a7)+,a0/a1
	rts

_rem_patch_alloc:
	movem.l	a0,-(a7)
	move.l	$4.W,A0
	add.w	#_LVOAllocMem+2,a0
	move.l	_alloc_save(pc),(A0)
	bsr	_flushcache
	move.l	(a7)+,a0
	rts

_my_alloc:
	btst	#MEMB_CHIP,d1
	beq.b	.out
	cmp.l	#$1F894,d0
	beq.b	.fix
	bra.b	.out
.fix
	bclr	#MEMB_CHIP,d1
.out
	move.l	_alloc_save(pc),-(A7)
	rts

_alloc_save
	dc.l	0

offsets:
	dc.l	$0026E+4
	dc.l	$00276+4
	dc.l	$00296+2
	dc.l	$0029C+2
	dc.l	$002A6+2
	dc.l	$002B6+2
	dc.l	$002CC+4
	dc.l	$002D4+4
	dc.l	$00324+2
	dc.l	$0032A+2
	dc.l	$00334+2
	dc.l	$003D6+2
	dc.l	$00434+2
	dc.l	$0045E+4
	dc.l	$00466+4
	dc.l	$00474+2
	dc.l	$00650+2
	dc.l	$00658+2
	dc.l	$00702+2
	dc.l	$07C0A+2
	dc.l	$07C14+4
	dc.l	$07C1C+4
	dc.l	$07C24+4
	dc.l	$07C2C+4
	dc.l	$07C70+2
	dc.l	$07C7A+4
	dc.l	$07C82+4
	dc.l	$07C8A+4
	dc.l	$07C92+4
	dc.l	$07CCC+4
	dc.l	$07CD4+4
	dc.l	$07CDC+4
	dc.l	$07CE4+4
	dc.l	$07CF6+2
	dc.l	$07D06+4
	dc.l	$07D0E+4
	dc.l	$07D16+4
	dc.l	$07D1E+4
	dc.l	$07D30+2
	dc.l	$07D40+2
	dc.l	$07D4E+2
	dc.l	$07D5C+2
	dc.l	$07D6A+2
	dc.l	$07D78+2
	dc.l	$07D86+2
	dc.l	$07D94+2
	dc.l	$07DA2+2
	dc.l	$07DBA+4
	dc.l	$07DC2+4
	dc.l	$07DCA+4
	dc.l	$07DD2+4
	dc.l	$07E12+4
	dc.l	$07E1A+4
	dc.l	$07E22+4
	dc.l	$07E2A+4
	dc.l	$07E68+2
	dc.l	$07E6E+2
	dc.l	$07E74+2
	dc.l	$07EB4+2
	dc.l	$07ED8+2
	dc.l	$07F3C+2
	dc.l	$07F60+2
	dc.l	$07FC4+2
	dc.l	$07FE8+2
	dc.l	$0834A+2
	dc.l	$08F4C+4
	dc.l	$08FC8+2
	dc.l	$0901C+4
	dc.l	$09090+2
	dc.l	$0911E+2
	dc.l	$09124+2
	dc.l	$09174+2
	dc.l	$0919A+2
	dc.l	$09578+4
	dc.l	$09580+4
	dc.l	$09588+4
	dc.l	$09590+4
	dc.l	$09598+4
	dc.l	$095A0+4
	dc.l	$095A8+4
	dc.l	$095E0+4
	dc.l	$095E8+4
	dc.l	$095F0+4
	dc.l	$095F8+4
	dc.l	$09600+4
	dc.l	$09608+4
	dc.l	$09610+4
	dc.l	$0973A+2
	dc.l	$09750+2
	dc.l	$09796+2
	dc.l	$097AC+2
	dc.l	$097EC+2
	dc.l	$09802+2
	dc.l	$0984C+2
	dc.l	$09852+2
	dc.l	$0985A+2
	dc.l	$09860+2
	dc.l	$09BEA+4
	dc.l	$09C68+4
	dc.l	$0A4FA+2
	dc.l	$0C94E+4
	dc.l	$0D764+4
	dc.l	$0D9F8+4
	dc.l	$0DBD0+4
	dc.l	$0F85A+4
	dc.l	$15734
	dc.l	-1



_joytest:
	movem.l	d1-a6,-(A7)
	TST	D0			;0D6A6: 4A40
	BEQ.S	.LAB_079A		;0D6A8: 670A
	MOVEQ	#6,D6			;0D6AE: 7C06
	MOVEQ	#2,D5			;0D6B0: 7A0A
	BRA.S	.tst
.LAB_079A:
	MOVEQ	#7,D6			;0D6B8: 7C07
	MOVEQ	#6,D5			;0D6BA: 7A0E
.tst
	move.b	_kbvalue(pc),d0

	btst	d6,$bfe001
	bne.b	.nofire
	bset	#6,D0
.nofire
;	btst	D5,$dff000+potinp
;	bne.b	.nofire2
;	move.w	#$CC01,$dff000+potgo	; reset ports
;	bset	#4,D0
;.nofire2
	movem.l	(a7)+,d1-a6
	rts

_patchkb:
	; replace system keyboard scan by ours

	pea	_kbint(pc)
	move.l	(a7)+,$68.W
	rts

_kbint:
	movem.l	D0-D3/A0/A5,-(A7)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ	.out
	MOVE.B	$1C01(A5),D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here
	lea	_kbtable(pc),a0
	bclr	#7,d0
	sne	d2
	move.b	_kbvalue(pc),d3
.loop:
	move.b	(a0)+,d1
	beq.b	.end
	cmp.b	d0,d1
	bne.b	.next
	move.b	(a0)+,d1
	tst.b	d2
	bne.b	.clr
.set
	bset	d1,d3
	bra.b	.end
.clr
	bclr	d1,d3
	bra.b	.end
.next
	addq.l	#1,a0
	bra.b	.loop
.end
	lea	_kbvalue(pc),a0
	move.b	d3,(a0)

	BSET	#$06,$1E01(A5)
	moveq	#2,d0
	bsr	_beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge key

.out
	movem.l	(A7)+,D0-D3/A0/A5
	move.w	#8,$dff09c
	RTE


_kbtable:
;	dc.b	$60,4		; left shift
;	dc.b	99,5		; CTRL
;	dc.b	66,7		; TAB
;	dc.b	100,3		; LEFT ALT
;	dc.b	$40,2		; SPACE
	dc.b	$19,1		; P = pause/play
	dc.w	0

_kbvalue:
	dc.w	0

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

	INCLUDE	kick31.s

;============================================================================

	END
