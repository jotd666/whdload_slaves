;*---------------------------------------------------------------------------
;  :Program.	SyndicateHD.asm
;  :Contents.	Slave for "Syndicate"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: SyndicateHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do: find if play+red works at the end of a mission
;          fix nvram buG (Bert)
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"SyndicateCD32.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;CHIP_ONLY
    IFD CHIP_ONLY
CHIPMEMSIZE	= $180000
FASTMEMSIZE	= $0
    ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $100000
    ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;DEBUG	; leave commented (I think because of nonvolatile.library strange packets...)
HDINIT
;INITAGA
;HRTMON
IOCACHE		= 300
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE
NO68020

slv_Version	= 17
; no clearmem: access fault on $CCCCCCCC
; I guess the game reads at some wrong location (game bug), but it doesn't matter much: 
; when it reads 0 it writes in 0 and it works.    
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'


INIT_LOWLEVEL
INIT_NONVOLATILE


;============================================================================

	INCLUDE	whdload/kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC



DECL_VERSION:MACRO
	dc.b	"2.7"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_assign1
	dc.b	"CD0",0
_assign2
	dc.b	"Syndicate",0

slv_name		dc.b	"Syndicate CD��"
        IFD CHIP_ONLY
        dc.b    " (DEBUG/CHIP mode)"
        ENDC
        dc.b    0
slv_copy		dc.b	"1993 Bullfrog",0
slv_info		dc.b	"adapted by JOTD",10,10
			dc.b	"Version "
		DECL_VERSION
	dc.b	0
slv_config:
    dc.b    "C1:B:skip introduction;"
    dc.b    "C2:L:language:english,french,italian;"
    dc.b    "C3:B:disable speed regulation;"
	dc.b	0

slv_CurrentDir:
	dc.b	"data",0

_intro
	dc.b	"intro",0
_args_intro
	dc.b	10
_args_intro_end
	dc.b	0
_program:
	dc.b	"syn",0
_args		dc.b	"/q",10
_args_end
	dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

_bootdos
		move.l	_resload(pc),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
		lea		_dosbase(pc),a0
		move.l	d0,(a0)
	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
  

		lea	(tag,pc),a0
		jsr	(resload_Control,a2)

        IFD CHIP_ONLY
		; chip-only mode: exe starts at $20000
        movem.l a6,-(a7)
		move.l	$4.w,a6
        move.l  #$20000-$1B2B8-$AD8,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
        ENDC

        move.l  skip_intro(pc),d0
        bne.b   .sk
        
	;load exe
		lea	_intro(pc),a0
		lea	_args_intro(pc),a1
		moveq	#_args_intro_end-_args_intro,d0
		lea	patch_intro(pc),a5
		bsr	_load_exe
.sk
	; now check if lang.def exists in RAM:
	lea	 _langdef_load(pc),a0
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2
	move.l	_dosbase(pc),a6
	jsr		(_LVOOpen,a6)
	tst.l	d0
	bne.b	.exists		; exists: use the setting set from intro
	; doesn't exist: create it
	lea	 _langdef_load(pc),a0
	move.l	a0,d1
	move.l	#MODE_NEWFILE,d2
	move.l	_dosbase(pc),a6
	jsr		(_LVOOpen,a6)
	; write proper language from CUSTOM2
	move.l	d0,d4
	lea	language+2(pc),a0
	move.l	d0,d1
	move.l	a0,d2
	move.l	#2,d3
	jsr		_LVOWrite(a6)
	move.l	d4,d0
.exists
	move.l	d0,d1
	jsr		(_LVOClose,a6)

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_main(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)


        
; < d7: seglist

patch_intro
	move.l	d7,a1
	add.l	#4,a1
	lea	pl_intro(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	rts

; < d7: seglist

patch_main
	patch	$100,do_flush
	move.l	d7,a1
	add.l	#4,a1
	
	lea	rawkey_code_1_address(pc),a0
	add.l	#$20f30,a1
	move.l	(2,a1),(a0)
	
	move.l	d7,a1
	add.l	#4,a1
	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	rts

pl_intro
	PL_START
	PL_L	$54,$72004E71	; VBR stuff
	PL_W	$4DE4,$D0C0	; programming error add.l d0,a0 -> add.w

	PL_PS	$4CE2,rjp1	; lowlevel readjoyport workarounds
	PL_PS	$4CFA,rjp1

	PL_END

pl_main
	PL_START
	PL_PS	$20f30,read_rawkey_code
	PL_L	$11B98,$72004E71	; VBR stuff
	PL_L	$11CEC,$4EF80100	; SMC
    PL_PS   $12784,kbint_hook

	PL_IFC3
	PL_ELSE
	PL_PS	$1117c,mainloop_hook
	PL_PS	$12024,vbl_hook
	PL_ENDIF
	
	; removes an infinite loop when F1 is pressed during game
	PL_PS	$32b92,wait_f1_release
	
    ; avoid "mouse or joypad required" spurious error
    ; (lowlevel first readings can be wrong, so we're going to
    ; trust the user and ignore this bloody error)  
    PL_S    $53e,$00564-$53E
	PL_END

mainloop_hook
    movem.l d1/a0-a1,-(a7)
    moveq.l #0,d1       ; the bigger the longer the wait
    lea vbl_counter(pc),a0
    move.w  (a0),d0
    cmp.w   #10,d0
    bcc.b   .nowait     ; first time called/lost sync/pause/whatever
    ; wait till at least x vblanks passed after last zeroing
.wait
    cmp.w   (a0),d1
    bcc.b   .wait
.nowait
    clr.w   (a0)
    movem.l (a7)+,d1/a0-a1
    rts
    
	MOVEQ	#0,D0			;1117c: 7000
	MOVE.W	(16,A5),D0		;1117e: 302d0010
	rts

vbl_hook
	move.l	a0,d0
    lea vbl_counter(pc),a0
    addq.w  #1,(a0)
	move.l	d0,a0
	clr.l	d0	; original
	rts
	
wait_f1_release
	move.l	a0,-(a7)
	lea		$BFEC01,a0
.loop
	move.b	(a0),d0
	cmp.b	#$5F,d0
	beq.b	.loop
	
	move.l	(a7)+,a0
	rts
	
; F1 raw (unshifted/unnegged: $5E)
read_rawkey_code
	move.l	a0,-(a7)
	move.l	rawkey_code_1_address(pc),a0
	move.b	(a0),d0
	cmp.b	#$5F,d0
	bne.b	.no_f1
	clr.b	(a0)		; clear keycode immediately
.no_f1
	move.l	(a7)+,a0
	rts
	
	
kbint_hook:
    move.l  d0,-(a7)
    not.b   d0
    ror.b   #1,d0
    cmp.b   _keyexit(pc),d0
    beq _quit    
    move.l  (a7)+,d0
    MOVE.B	#$00,($C00,A1)		;142f8: 137c00000c00
    rts
    
do_flush
	bsr	_flushcache
	MOVEA.L	(A7)+,A4		;13CB6: 285F
	RTS				;13CB8: 4E75

rjp1
	add.l	#4,(a7)
	moveq	#0,d0
	btst	#7,$bfe001
	bne.b	.sk2
	bset	#22,d0
.sk2
	move.l	d1,-(a7)
	move.w	$dff016,d1
	btst	#14,d1
	bne.b	.sk3
	bset	#23,d0
	move.w	#$cc01,$dff034
.sk3
	move.l	(a7)+,d1
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
	jsr	(_LVOLoadSeg,a6)
	move.l	d0,d7			;D7 = segment
	beq	.end			;file not found

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	d0-a6,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d0-a6
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
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

tag		dc.l	WHDLTAG_CUSTOM1_GET
skip_intro	dc.l	0
	dc.l	WHDLTAG_CUSTOM2_GET
language	dc.l	0

		dc.l	0
_dosbase
	dc.l	0
rawkey_code_1_address
	dc.l	0
vbl_counter
	dc.w	0
_langdef_load:
	DC.B	"ram:lang.def",0

;============================================================================

	END
