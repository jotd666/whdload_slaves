;*---------------------------------------------------------------------------
;  :Program.	FA18InterceptorHD.asm
;  :Contents.	Slave for "FA18Interceptor" from 
;  :Author.	JOTD
;  :Original	
;  :Version.	$Id: battleisle.asm 0.5 2000/11/26 21:13:41 jah Exp $
;  :History.	23.05.01 started
;		23.05.01 finished
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"F-18Interceptor.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

; number of floppy drives:
;	sets the number of floppy drives, valid values are 0-4.
;	0 means that the number is specified via option Custom1/N
NUMDRIVES=1

; protection state for floppy disks:
;	0 means 'write protected', 1 means 'read/write'
;	bit 0 means drive DF0:, bit 3 means drive DF3:
WPDRIVES=%1111

; enable SetPatch
;	include all patches (nearly all) done by the SetPatch program, usually
;	that is not neccessary and disabling that option makes the Slave
;	around 400 bytes shorter
SETPATCH

; enable debug support for hrtmon:
;	hrtmon reads to much from the stackframe if entered, if the ssp is at
;	the end hrtmon will create a access fault.
;	for better compatibility this option should be disabled
;HRTMON

; calculate minimal amount of free memory
;	if the symbol MEMFREE is defined after each call to exec.AllocMem the
;	size of the largest free memory chunk will be calculated and saved at
;	the specified address if lower than the previous saved value (chipmem
;	at MEMFREE, fastmem at MEMFREE+4)
;MEMFREE=$100

HDINIT
DOSASSIGN
BLACKSCREEN
BOOTDOS
CACHE
IOCACHE = 10000

;CHIP_ONLY
; amount of memory available for the system
	IFD	CHIP_ONLY
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $50000
	ENDC
	
; protection removal: offset  1ce70 : 13fc00ff -> 13fc0001
; 40A54 end of line

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'


;============================================================================

	INCLUDE	whdload/kick13.s
IGNORE_JOY_DIRECTIONS
IGNORE_JOY_PORT0
	include	ReadJoyPad.s
	
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
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

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,0

slv_CurrentDir		dc.b	"data",0
slv_name		dc.b	"F/A-18 Interceptor"
			IFD		CHIP_ONLY
			dc.B	" (debug/chip mode)"
			ENDC
			
			dc.b	0
slv_copy		dc.b	"1988 Intellisoft/Electronic Arts",0
slv_info		dc.b	"Adapted by JOTD",10,10
			dc.b	"Thanks to paraj for speed regulation fix",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

_assign1:
	dc.b	"DF0",0
_assign2:
	dc.b	"F18",0

slv_config:
	dc.b	"BW;"
    dc.b    "C3:B:disable speed regulation;"

	dc.b	0

_program:
	dc.b	"f-18 interceptor",0
_args:
	dc.b	10
_args_end:
	dc.b	0
	even

;============================================================================

	;initialize kickstart and environment

_bootdos
		move.l	(_resload,pc),a2	;a2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
		
	; detect joypads, with interrupts disabled
	move.l	(4),a6
	jsr	_LVODisable(a6)
	bsr	_detect_controller_types
	jsr	_LVOEnable(a6)

	; stores most significant quadbit for later

	move.b	_expmem(pc),d0
	and.b	#$F0,D0
	lea	_msq(pc),A0
	move.b	D0,(A0)

	;open gfxlib
		lea	(_gfxname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		lea	GraphicsBase(pc),a0
		move.l	d0,(a0)			;A6 = dosbase
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patchexe(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)




; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)


load_exe:
	movem.l	d0-a6,-(a7)
	move.l	d0,d2
	move.l	a0,a3
	move.l	a1,a4
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)
	move.l	d0,d7			;D7 = segment
	beq	.end			;file not found
        lea     _seglist(pc),a0
        move.l  d7,(a0)

        moveq   #71,d0
        bsr     _getseg
        add.l   #357,d0
        lea     _ingamevaraddr(pc),a0
        move.l  d0,(a0)

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	d2/d7/a4,-(a7)
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3

	move.l	a4,a0

	movem.l	d7/a6,-(a7)

	move.l	d2,d0			; argument string length
	move.l	_stacksize(pc),-(a7)	; original stack format
	movem.l	(_saveregs,pc),d1-d7/a1-a2/a4-a6	; original registers (BCPL stuff)
	jsr	(4,a3)		; call program
	addq.l	#4,a7

	movem.l	(a7)+,d7/a6

	;remove exe

	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)

	movem.l	(a7)+,d0-a6
	rts

.end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

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

_patchexe
	move.l	d7,a1		; seglist

	; remain compatible with unit-a crack, well spread

	pea	_unita_trap0(pc)
	move.l	(a7)+,$80.W
	
	patch	$100,_fix_af_1

	move.l	_resload(pc),a2
	lea		pl_main(pc),a0
	jsr		resload_PatchSeg(a2)
	
	rts

	
pl_main
	PL_START
	; section 1: cpu dependent loop

	PL_PS	$8E2,_emulate_empty_loop
	
	; section 20: protection

	; flag telling that protection was passed
	PL_B	$19737,1
	PL_B	$3a964,1
	PL_NOP	$01a78,6
	
	; section 8: access fault #1
	PL_L	$fd7c,$4EB80100
	
	; section 9: access fault #2

	PL_PSS	$11468,_fix_af_2,2

	; sound
	
	PL_P	$451c8,sound_delay
	
	PL_PSS	$01590,keyboard_test,2
	
	
	PL_IFBW
	PL_PS	$006b4,wait_pic
	PL_ENDIF
	
	PL_IFC3
	PL_PS	$092e6,vbl_hook_no_regulation
	PL_ELSE
	PL_PS	$08286,speed_regulation
	PL_PS	$092e6,vbl_hook
	PL_ENDIF
	PL_END

wait_bovp
	; wait but maybe several times (speed regulation)
	MOVE.L	A6,-(A7)		;48f64: 2f0e
	MOVEA.L	8+4(A7),A0		;48f66: 206f0008
	MOVEA.L	GraphicsBase(pc),A6		;48f6a: 2c790000a77a
	JSR	(_LVOWaitBOVP,A6)	;48f70: 4eaefe6e graphics.library (off=-402)
	MOVEA.L	(A7)+,A6		;48f74: 2c5f
	RTS				;48f76: 4e75
	
speed_regulation
        ; Determine frame interval (d0)

        move.l _ingamevaraddr(pc),a0
        moveq   #4,d0 ; In game minimum frame interval
        tst.b   (a0)
        bne.b   .notext
        ; Displaying text, don't want to wait one frame
        ; every time (too slow)
        moveq   #0,d0
        lea     text_counter(pc),a0
        subq.w  #1,(a0)
        bpl.b   .notext
        move.w  #4,(a0)
        moveq   #1,d0
.notext
	
        lea     vbl_counter(pc),a0
.wait
        cmp.w   (a0),d0
        bhi.b   .wait
        clr.w   (a0)
        bsr.b   wait_bovp
	rts

wait_pic:
.loop1
	btst	#7,$BFE001
	beq.b	.loop1
	btst	#6,$BFE001
	beq.b	.loop1
.loop2
	btst	#6,$BFE001
	beq.b	.out
	btst	#7,$BFE001
	bne.b	.loop2
.out
	MOVE.L	A6,-(A7)		;48c60: 2f0e
	MOVEA.L	$4,A6		;48c62: 2c790000a378
	MOVEA.L	8(A7),A1		;48c68: 226f0008
	JSR	(_LVOCloseLibrary,A6)	;48c6c: 4eaefe62 exec.library (off=-414)
	MOVEA.L	(A7)+,A6		;48c70: 2c5f

	rts
	
vbl_hook
	; add to counter
	move.l	a0,-(a7)
    lea vbl_counter(pc),a0
    addq.w  #1,(a0)
	move.l	(a7)+,a0
vbl_hook_no_regulation
	bsr		_joystick
	move.w	_custom+joy0dat,d0
	rts
	
; d1 & d2: current & previous joystates

TESTKEY:MACRO
	btst	#JPB_BTN_\1,d1
	beq.b	.no_\1
	; play pressed, was it the first time
	btst	#JPB_BTN_\1,d2
	bne.b	.out_\1	; already pressed

	move.b    #\2,d0	; play pressed
	bra.b	.out_\1
.no_\1
	; blue not pressed, was it the first time
	btst	#JPB_BTN_\1,d2
	beq.b	.out_\1
	move.b    #\2+$80,d0	; play released
.out_\1
    ENDM
	
keyboard_test
	movem.l	a0/d1/d2,-(a7)
	move.l	joy1(pc),d1
	lea		prev_joy1(pc),a0
	move.l	(a0),d2		; d2: previous
	move.l	d1,(a0)		; store current
	
	TESTKEY	PLAY,$19
	TESTKEY	BLU,$44	; select weapon
	TESTKEY	YEL,$14	; target select
	TESTKEY	GRN,$23	; F flare
	TESTKEY	REVERSE,$0B	; thrust down
	TESTKEY	FORWARD,$0C	; thrust up
	
	movem.l	(a7)+,a0/d1/d2
	
	MOVE.B	D0,-1(A6)		;01590: 1d40ffff
	CMPI.B	#$ff,D0			;01594: 0c0000ff

	rts
	
	
sound_delay
	moveq	#4,d0
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	MOVEM.L	(A7)+,D0-D3/A0-A4	;451d2: 4cdf1f0f
	RTS				;451d6: 4e75
_unita_trap0
	moveq	#0,d0
	RTE

; must be a while(i++<10000); or something like that in C
; happens a few times
; - title
; - after the "welcome" message

_emulate_empty_loop:
	move.l	D0,-(a7)
	move.w	#200,d0
	bsr		_beamdelay
	move.l	(a7)+,d0
	add.l	#10,(a7)	; skip rest of active cpu loop
	rts


_fix_af_1
	movem.l	D0,-(A7)
	move.l	(A0)+,d0
	move.l	d0,a1
	rol.l	#8,D0
	tst.b	D0
	beq.b	.ok
	or.b	_msq(pc),d0
	ror.l	#8,D0
	move.l	D0,A1
.ok
	movem.l	(A7)+,D0
	tst.w	(A1)	; stolen code
	rts

_fix_af_2
	move.l	(2,A1),D7
	move.l	D7,a2
	rol.l	#8,D7
	tst.b	D7
	beq.b	.ok
	or.b	_msq(pc),D7
	ror.l	#8,D7
	move.l	D7,A2
.ok
	MOVE.L	4(A2),D7
	rts

_wrong_version
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

_getseg:
        move.l  _seglist(pc),a0
        bra.b   .iter
.loop:  add.l   a0,a0
        add.l   a0,a0
        move.l  (a0),a0
.iter:  dbf     d0,.loop
        move.l  a0,d0
        lsl.l   #2,d0
        addq.l  #4,d0
        rts

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
_custom5	dc.l	0
		dc.l	0
_seglist:
	dc.l	0
_msq:
	dc.w	0
_saveregs
		ds.l	16,0
_stacksize
		dc.l	0
prev_joy1
	dc.l	0
GraphicsBase
	dc.l	0
vbl_counter
	dc.w	0
text_counter
        dc.w    0

_ingamevaraddr
        dc.l    0

_gfxname
	dc.b	"graphics.library",0
	even
;============================================================================


;============================================================================

	END
