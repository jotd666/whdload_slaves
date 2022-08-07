;*---------------------------------------------------------------------------
;  :Modul.	kick13.asm
;  :Contents.	kickstart 1.3 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick13.asm 1.2 2001/09/20 19:46:12 wepl Exp wepl $
;  :History.	19.10.99 started
;		20.09.01 ready for JOTD ;)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	lvo/dos.i
	INCLUDE	lvo/exec.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

;CHIP_ONLY

	IFD BARFLY
	OUTPUT	"AnotherWorld.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

	IFND	CHIP_ONLY
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
BLACKSCREEN
	ELSE
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
HRTMON
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %1111

;DISKSONBOOT
BOOTDOS
CACHE
HDINIT
;MEMFREE	= $100
;NEEDFPU
;SETPATCH
CBDOSREAD
SEGTRACKER
;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s
IGNORE_JOY_DIRECTIONS    
    INCLUDE ReadJoyPad.s
    
;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
    ENDC
    
DECL_VERSION:MACRO
	dc.b	"2.8"
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
	dc.b	$D,0

slv_name		dc.b	"Another World",0
slv_copy		dc.b	"1991 Delphine Software",0
slv_info		dc.b	"adapted & fixed by Harry/JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
_args:
	dc.b	10
_args_end:
	dc.b	0
_program:
	dc.b	"another",0

	EVEN

;============================================================================

NOT_PATCHED = 0
JUST_PATCHED = 1
CONFIRM_PATCHED = 2

	;initialize kickstart and environment


_bootdos	move.l	(_resload,pc),a2		;A2 = resload

    bsr get_version
    bsr _detect_controller_types
    
    
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase


	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.end

	;patch
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
        addq.l  #4,a1
        
        bsr	_patchexe

	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1

		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check

		movem.l	d0/d7/a2/a6,-(a7)

		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)
        bra.b _quit
.end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
    
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
_quit
		pea	TDREASON_OK
        move.l  _resload(pc),a2
		jmp	(resload_Abort,a2)


get_version:
	movem.l	d1/a1,-(a7)
	lea	_program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#28896,D0       ; fr/kixx/us
	beq.b	.ok

	cmp.l	#28964,d0
	beq.b	.ok
	cmp.l	#28864,d0
	beq.b	.ok
	cmp.l	#28948,d0       ; sps 2377
	beq.b	.ok

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.ok
     lea    _progsize(pc),a0
     move.l d0,(a0)
	 movem.l	(a7)+,d1/a1
     rts
     
_patchexe
    ; install vbl hook which counts vblank
    ; and also reads controllers
    lea old_level3_interrupt(pc),a0
    move.l  $6C.W,(a0)
    lea new_level3_interrupt(pc),a0
    move.l  a0,$6C.W

    move.l  _progsize(pc),d0
    cmp.l   #28948,d0
    beq.b   .fr_2377
    cmp.l   #28864,d0
    beq.b   .uk2
    cmp.l   #28896,d0
    bne.b   .uk
    move.w  $3E(a1),d0
    cmp.w   #$66FE,d0
    beq.b   .fr
    ; us
    lea pl_us(pc),a0
    bra.b   .patch
.fr_2377
    lea pl_fr_2377(pc),a0
    bra.b   .patch
.fr
    lea pl_fr(pc),a0    ; kixx is identical
    bra.b   .patch
.uk
    lea pl_uk(pc),a0
    bra.b   .patch
.uk2
    lea pl_uk2(pc),a0
.patch    
    jsr resload_Patch(a2)
    rts
    
pl_fr
    PL_START
    PL_PSS  $4bf8-6,dma_delay,4
    PL_PSS  $4c24-6,dma_delay,4
    PL_PSS  $5000-6,dma_delay,4
    PL_PSS  $5170-6,dma_delay,4
    PL_PSS    $3820,wait_blit,2
    PL_PSS    $3e72,wait_blit,2
    PL_PSS    $3fc0,wait_blit,2
	PL_PS	$499a,enter_code_test
    PL_END
pl_fr_2377
    PL_START
    PL_PSS  $4c38-6,dma_delay,4
    PL_PSS  $4c64-6,dma_delay,4
    PL_PSS  $5036-6,dma_delay,4
    PL_PSS  $51a6-6,dma_delay,4
    
    PL_PSS    $386e,wait_blit,2
    PL_PSS    $3ec0,wait_blit,2
    PL_PSS    $400e,wait_blit,2
	PL_PS	$49da,enter_code_test
    PL_END

pl_uk
    PL_START
    PL_PSS  $4c48-6,dma_delay,4
    PL_PSS  $4c74-6,dma_delay,4
    PL_PSS  $5046-6,dma_delay,4
    PL_PSS  $51b6-6,dma_delay,4
    PL_PSS    $3872,wait_blit,2
    PL_PSS    $3ec4,wait_blit,2
    PL_PSS    $4012,wait_blit,2
	PL_PS	$49ea,enter_code_test
    PL_END
pl_uk2
    PL_START
    PL_PSS  $4bd8-6,dma_delay,4
    PL_PSS  $4c04-6,dma_delay,4
    PL_PSS  $4fe0-6,dma_delay,4
    PL_PSS  $5150-6,dma_delay,4
    PL_PSS    $380c,wait_blit,2
    PL_PSS    $3e5e,wait_blit,2
    PL_PSS    $3fac,wait_blit,2
	PL_PS	$497a,enter_code_test
    PL_END
pl_us
    PL_START
    PL_PSS  $4bf8-6,dma_delay,4
    PL_PSS  $4c24-6,dma_delay,4
    PL_PSS  $5000-6,dma_delay,4
    PL_PSS  $5170-6,dma_delay,4
    PL_PSS    $3824,wait_blit,2
    PL_PSS    $3e76,wait_blit,2
    PL_PSS    $3fc4,wait_blit,2
 	PL_PS	$499a,enter_code_test
    PL_END
    
TEST_BUTTON:MACRO
    btst    #JPB_BTN_\1,d1
    beq.b   .nochange_\1
    move.b  #\2,d3
    btst    #JPB_BTN_\1,d0
    bne.b   .pressed_\1
    bset    #7,d3   ; released
.pressed_\1

    not.b   d3
    rol.b   #1,d3
    move.b  d3,$bfec01 ; store keycode
.nochange_\1
    ENDM
   
    
wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts
; just keycode
new_level3_interrupt
    movem.l d0-d3/a0-a1,-(a7)
    move.w  _custom+intreqr,d0
    btst    #5,d0
    beq   .novbl
    bsr vblank
.novbl    
    movem.l (a7)+,d0-d3/a0-a1
    move.l  old_level3_interrupt(pc),-(a7)
    rts    
    
    
vblank
    movem.l a0-a1/d0-d1/d3,-(a7)
    ; vblank interrupt, read joystick/mouse
    lea counter(pc),a1
	ADDQ.b	#1,(A1)
    move.b  (a1),d0     ; read every 40ms
    btst    #0,d0
    beq   .nochange
    lea prev_buttons_state(pc),a0
    move.l  (a0),d1     ; get previous state
	moveq	#1,d0
	bsr	_read_joystick
    ; xor to d1 to get what has changed quickly
    eor.l   d0,d1
    beq.b   .nochange   ; cheap-o test just in case no input has changed
    move.l  d0,(a0)     ; save previous state for next time
    ; now D0 is current joypad state
    ;     D1 is previous joypad state
    ; d1 bears changed bits (buttons pressed/released)
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noquit
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .noquit
    btst    #JPB_BTN_YEL,d0
    bne _quit
.noquit    
    ;TEST_BUTTON REVERSE,$4A
    ;TEST_BUTTON FORWARD,$5E
    TEST_BUTTON BLU,$33     ; 'C'
    TEST_BUTTON GRN,$21     ; 'S' sound on/off
    TEST_BUTTON PLAY,$19     ; pause
.nochange
    movem.l (a7)+,a0-a1/d1-d0/d3
	RTS				;585c: 4e75

dma_delay
	move.w  d0,-(a7)
	move.w	#4,d0   ; make it 7 if still issues
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	;;;addq.l	#2,(a7)  harmful if not used with PSS!!
	move.w	(a7)+,d0
	rts 

    
NB_SAVED_REGS = 3*4	; must follow number of saved registers * 4

enter_code_test
	movem.l	d0-d1/a0,-(a7)
	move.l	NB_SAVED_REGS(a7),a0	; return address
	moveq	#0,d0
	move.w	(a0),d0		; offset of the BEQ

	
	cmp.b	#$33,d4		; 'C' key
	beq.b	.enter_code
	btst	#6,$bfe001	; left mouse
	beq.b	.enter_code

	bra.b	.nothing
.enter_code
	move.w	_protection_patched(pc),d1
	cmp.w	#CONFIRM_PATCHED,d1
	bne.b	.nothing		; too soon to enter code

	ext.l	d0
	add.l	d0,NB_SAVED_REGS(a7)	; perform BEQ	
	bra	.out
.nothing	
	addq.l	#2,NB_SAVED_REGS(a7)	; skip rest of BEQ
.out
	movem.l	(a7)+,d0-d1/a0
	rts

TIME	MOVEM.L	D1/A0,-(A7)
	MOVEQ.L	#0,D1
	MOVE.L	8(A7),A0
	MOVE.L	(A0),A0
	MOVE.W	(A0),D1
	BSR.S	PATCHTIME
	MOVEM.L	(A7)+,D1/A0
	ADDQ.L	#4,(A7)
	RTS



PATCHTIME
	DIVU	#$28,D1
.4	MOVE.L	D1,-(A7)
	MOVE.B	$DFF006,D1
.3	CMP.B	$DFF006,D1
	BEQ.S	.3
	MOVE.L	(A7)+,D1
	DBF	D1,.4
	RTS

; < d1 - file pos
; < a0 - name
; < a1 - buffer

_cb_dosRead
	cmp.b	#'1',5(a0)
	bne	.out
	cmp.b	#'0',4(a0)
	bne	.out

;	cmp.l	#$1A000,d1
;	bcs.b	.out
;	cmp.l	#$1C000,d1
;	bcc.b	.out

	cmp.l	#$1B5EE,d1	; protection load
	beq.b	.prot

	cmp.l	#$30000,d1
	bcs	.out		; not reading intro part yet
	
	lea	_protection_patched(pc),a0
	tst.w	(a0)
	beq	.out	; not patched yet
	move.w	#CONFIRM_PATCHED,(a0)
	bra	.out
.prot
	move.l	a2,-(a7)

	; note that the protection has been patched
	; we can't use code enter just now until protection
	; screen has completed
	; (or at least we reached the protection offset, kixx version
	; is already cracked)
	lea		_protection_patched(pc),a2
	move.w	#JUST_PATCHED,(a2)

	move.l	(a7),a2

	; version 3 (supported with patched file on disk,
        ; but not at the same offset)
	; 114621: 0A 80 29 1E 09 EA 0A 80 29
	lea	$9cf(a1),a2
	cmp.b	#$a,(a2)
	bne.b	.v2
	move.b	#$07,(a2)+
	move.b	#$0a,(a2)+
	move.b	#$3b,(a2)

	; 114761 ($1C049): 0A 01 1B 15 0A

	lea	$a5b(a1),a2
	move.b	#$07,(a2)+
	move.b	#$0a,(a2)+
	move.b	#$71,(a2)
	bra	.patched

.v2
	; version 2 (UK)

	lea	$9fc(a1),a2
	cmp.b	#$a,(a2)
	bne.b	.v1
	; 0A 80 29 1E 0A 17 07 0A

	move.b	#$07,(a2)+
	move.b	#$0A,(a2)+
	move.b	#$68,(a2)

	lea	$a88(a1),a2
	move.b	#$07,(a2)+
	move.b	#$0A,(a2)+
	move.b	#$9E,(a2)

	bra.b	.patched

.v1
	; version 1 (french)
	; 114493 ($1BF3D) 0A 80 29 1E 09 6A 0A 80 29
	lea	$94f(a1),a2
	cmp.b	#$a,(a2)
	bne.b	.skip

	move.b	#$07,(a2)+
	move.b	#$09,(a2)+
	move.b	#$bb,(a2)
	; 0A 01 1B 15 0A 28 14 32
	lea	$9db(a1),a2
	move.b	#$07,(a2)+
	move.b	#$09,(a2)+
	move.b	#$f1,(a2)

.patched
.skip	
	; cracked versions or unsupported originals
	; land here, nothing is patched, so the
	; protection is left intact

	move.l	(a7)+,a2
.out

	rts
counter
    dc.w    0
_protection_patched
	dc.w	NOT_PATCHED
_progsize
    dc.l    0
prev_buttons_state
        dc.l    0
old_level3_interrupt        
        dc.l    0
;============================================================================

	END

