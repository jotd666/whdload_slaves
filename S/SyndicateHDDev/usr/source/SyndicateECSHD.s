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
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"SyndicateECS.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $C0000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 11000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
STACKSIZE = 6000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	include	whdload/kick13.s

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

slv_name	dc.b	"Syndicate (ECS)",0
slv_copy	dc.b	"1993 Bullfrog",0
slv_info	dc.b	"adapted by JOTD",10,10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	
slv_config:
    dc.b    "C1:B:skip introduction;"
    ;dc.b    "C2:L:language:english,french,italian;"
    dc.b    "C3:B:disable speed regulation;"
	dc.b	0
	
_intro
	dc.b	"intro",0

_program:
	dc.b	"syn",0
_args	
	dc.b	"/q",10
_args_end
	dc.b	0
_noargs
	dc.b	10
_noargs_end
	dc.b	0

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload


	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		bsr	check_version
	;load intro
		move.l	skip_intro(pc),d0
		bne.b	.skip_intro
		lea	_intro(pc),a0
		lea	_noargs(pc),a1
		moveq	#_noargs_end-_noargs,d0
		lea	patch_intro(pc),a5
		bsr	_load_exe
.skip_intro
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

patch_intro
	move.l	d7,a1
	cmp.l	#$4E7A1801,$3E+4(a1)
	bne.b	.novbr
	move.l	#$72004E71,$3E+4(a1)
.novbr
	rts

check_version
	lea	_program(pc),a0
	jsr	resload_GetFileSize(a2)
	cmp.l	#314720,d0
	beq.b	.ok
	cmp.l	#313952,d0
	beq.b	.ok
	cmp.l	#315736,d0
	bne.b	wrongver

.ok
	rts
wrongver
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts	
; < d7: seglist (APTR)

patch_main
	patch	$100,do_flush
	move.l	d7,a1
	add.l	#4,a1

	add.l	#$13000,a1
	cmp.l	#$285F4E75,$BBA(a1)
	bne.b	.tryukflop

	; CAPS 405 "SYN" file (313952 bytes)

	lea	pl_405(pc),a0

	bra.b	.out

.tryukflop
	cmp.l	#$285F4E75,$CB6(a1)
	bne.b	.noflop2

	; SPS 739 "SYN" file (314720) bytes

	lea	pl_739(pc),a0

	bra.b	.out
.noflop2
	cmp.l	#$33C000DF,$B3C(a1)
	bne.b	wrongver

	; SPS 1887 "SYN" file (315736 bytes)

	lea	saved_addr(pc),a0
	move.l	$B5A(a1),(a0)

	lea	pl_1887(pc),a0
.out
	move.l	d7,a1
	add.l	#4,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	rts

do_flush_2
	bsr	_flushcache
	move.l	saved_addr(pc),$6C.W
	rts

saved_addr
	dc.l	0

do_flush
	bsr	_flushcache
	MOVEA.L	(A7)+,A4		;13CB6: 285F
	RTS				;13CB8: 4E75

active_loop_1
	MOVE.L	#$000186A0,D6		;0B6A6: 0C86000186A0
	ADD.L	D6,D5   ; not necessary, as D5 isn't used

	movem.l	D0-D1,-(A7)
	move.l	D6,d0
	lsr.l	#6,d1
.loop
	bsr	beamdelay
	dbf	D1,.loop

	movem.l	(A7)+,D0-D1
	add.l	#10,(A7)
	rts

active_loop_2:
	; when shooting? sfx ?

	movem.l	d0,-(a7)
	move.l	d7,d0
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$10,D0	;approx
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beamdelay
	movem.l	(a7)+,d0
	add.l	#6,(A7)
	move.w	#$FFFF,d7
	rts

active_loop_3:
	movem.l	d0,-(a7)
	moveq.l	#2,d0
	bsr	beamdelay
	movem.l	(a7)+,d0
	add.l	#8,(A7)
	rts

; 739 and 405 are very close
; 1887 looks older (doesn't have VBR support)
pl_739:
	PL_START
	PL_L	$13CB6,$4EF80100	; VBL install -> crash
	PL_L	$13B62,$72004E71	; VBR stuff
	PL_PS	$B6A6,active_loop_1
	PL_PS	$27C36,active_loop_2
	PL_PS	$3842A,active_loop_3
    PL_PS   $1447C,kbint_hook
	
	PL_IFC3
	PL_ELSE
	PL_PS	$130FE,mainloop_hook
	PL_PSS	$13FDA,vbl_hook,4
	PL_ENDIF
	PL_END
pl_405:
	PL_START
	PL_L	$13bba,$4EF80100	; VBL install -> crash
	PL_L	$13a66,$72004E71	; VBR stuff
	PL_PS	$0b5aa,active_loop_1
	PL_PS	$27b4e,active_loop_2
	PL_PS	$38342,active_loop_3
    PL_PS   $14380,kbint_hook
	PL_IFC3
	PL_ELSE
	PL_PS	$13002,mainloop_hook
	PL_PSS	$13ede,vbl_hook,4
	PL_ENDIF
	PL_END

pl_1887:
	PL_START

	PL_PS	$0b68e,active_loop_1
	PL_PS	$28080,active_loop_2
	PL_PS	$3885a,active_loop_3
    PL_P    $13af2,flush_and_allow_interrupts
    PL_P    $13ad4,flush_and_allow_interrupts_2
    PL_PS   $142f8,kbint_hook
	PL_P	$13B58,do_flush_2
	
	PL_IFC3
	PL_ELSE
	PL_PS	$12faa,mainloop_hook
	PL_PSS	$13e5e,vbl_hook,4
	PL_ENDIF
	
	PL_END

mainloop_hook
    movem.l d1/a0-a1,-(a7)
    clr.l d1       ; the bigger the longer the wait, 0 min value
    lea vbl_counter(pc),a0
    move.l  (a0),d0
    cmp.l   #10,d0
    bcc.b   .nowait     ; first time called/lost sync/pause/whatever
    ; wait till at least x vblanks passed after last zeroing
.wait
    cmp.l   (a0),d1
    bcc.b   .wait
.nowait
    clr.l   (a0)
    movem.l (a7)+,d1/a0-a1
    rts
    
	MOVEQ	#0,D0			;1117c: 7000
	MOVE.W	(16,A5),D0		;1117e: 302d0010
	rts
	
vbl_hook
	AND.W	_custom+intenar,D0		;13ede: c07900dff01c
	ANDI.W	#$4020,D0		;13ee4: 02404020
	beq.b	.no_vbl
    lea vbl_counter(pc),a0
    addq.l  #1,(a0)
.no_vbl
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
    
    ; at segment 0 offset 13b44 there's a routine that performs SMC
    ; on a VBL hook. Flushing the cache ensures that the address isn
    ; properly updated
flush_and_allow_interrupts
    bsr _flushcache
	MOVE.W	#$c020,$dff09a
	MOVEM.L	(A7)+,D0/A1/A6		;13afa: 4cdf4201
	RTS				;13afe: 4e75

flush_and_allow_interrupts_2
    bsr _flushcache
	MOVE.W	D0,$dff09a
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
	movem.l	d2/d7/a4,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
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
	jsr	(_LVOIoErr,a6)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


; < D0: numbers of vertical positions to wait
beamdelay
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
skip_intro	dc.l	0
		dc.l	0
vbl_counter
	dc.l	0
	END
