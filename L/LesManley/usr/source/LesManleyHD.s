;*---------------------------------------------------------------------------
;  :Program.	LesManleyHD.asm
;  :Contents.	Slave for "LesManley"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: LesManleyHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"LesManley.slave"
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
;CHIPMEMSIZE	= $140000
;FASTMEMSIZE	= $0000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
;DOSASSIGN
DEBUG
;INITAGA
HDINIT
CACHE
;HRTMON
IOCACHE		= 15000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
STACKSIZE = 20000
BOOTDOS


slv_Version = 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_NoKbd
slv_keyexit	= $5D	; num '*'

;============================================================================

	include	whdload/kick13.s

;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC
	
DECL_VERSION:MACRO
	dc.b	"1.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_assign
	dc.b	"LesManley",0

slv_name		dc.b	"Les Manley - Search for the King",0
slv_copy		dc.b	"1990-1991 Accolade",0
slv_info		dc.b	"adapted by JOTD",10
			dc.b	"from Wepl excellent KickStarter 34.005",10,10
			dc.b	"Thanks to Hubert Maier for disk images & testing",10,10
			dc.b	"Thanks to LockPick for protection removal",10,10
			dc.b	"Version "
			DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
	dc.b    "C5:L:keyboard:auto,us,fr,de;"
	dc.b	0
	
_program:
	dc.b	"king",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
        move.l  _keyboard_type(pc),d0
        bne.b   .manual
        move.l  _language(pc),d1
        cmp.b	#3,D1
        beq.b	.german
        cmp.b	#4,D1
        beq.b	.french 
        bra.b   .english
.french
        moveq.l #2,d0
        bra.b   .kbbounds
.german
        moveq.l #3,d0
        bra.b   .kbbounds
.manual
        cmp.l   #4,d0
        bcs.b   .kbbounds
.english        
        moveq.l #1,d0   ; us: don't do anything        
.kbbounds
        subq.l  #1,d0
        lea _keyboard_type(pc),a0
        move.l  d0,(a0)
        
        lea    old_kbint(pc),a1
        lea kbint_hook(pc),a0
        cmp.l   (a1),a0
        beq.b   .done
        move.l  $68.W,(a1)
        move.l  a0,$68.W
.done	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

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

patch_main
	move.l	d7,a1
	lea	pl_main(pc),a0
	jsr	resload_PatchSeg(a2)

	rts



pl_main:
	PL_START
	PL_PS	$674,cpu_dep_loop
	PL_PS	$9B4,cpu_dep_loop

; removes copy protection (Thanks LockPick)

	PL_L	$27358,$397C00FF
	PL_L	$2735C,$199E600A
	PL_END

cpu_dep_loop
	movem.l	d1/d2,-(a7)

	; get D1 MSW as a counter

	move.l	d0,d1
	clr.w	d1
	swap	d1

	; remove D0 MSW and divide

	swap	d0
	clr.w	d0
	swap	d0
	divu	#100,d0
	swap	d0
	clr.w	d0
	swap	d0
	move.l	d0,d2

.loop
	move.b	8420(A4),8421(A4)
	move.l	d2,d0	
	bsr	_beamdelay
	dbf	d1,.loop
	
	movem.l	(a7)+,d1-d2
	add.l	#10,(a7)	; skip game loop
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

kbint_hook:
    movem.l  a0-a1/d0-d3,-(a7)
    move.b  $BFEC01,d0
    ror.b   #1,d0
    not.b   d0
    moveq.l #0,d1
    bclr    #7,d0
    sne     d1
    lea kb_table(pc),a0
    move.l  _keyboard_type(pc),d2
    add.l   d2,d2
    move.w  (a0,d2.w),a1
    add.w   a1,a0
    
.loop
    move.b  (a0)+,d2
    bmi.b   .noswap
    move.b  (a0)+,d3
    cmp.b   d0,d2
    bne.b   .loop
    move.b  d3,d0

.pack
    tst.b   d1
    beq.b   .norel
    bset    #7,d0   ; key released
.norel
    not.b   d0
    rol.b   #1,d0
    move.b  d0,$BFEC01    
.noswap
    movem.l  (a7)+,a0-a1/d0-d3
    
    move.l  old_kbint(pc),-(a7)
    rts

    
old_kbint:
    dc.l    0

kb_table:
    dc.w    us-kb_table,french-kb_table,deutsch-kb_table

us:
    dc.b    -1
french:
    dc.b    $10,$20   ; a <-> q
    dc.b    $20,$10   ; a <-> q
    dc.b    $11,$31   ; w <-> z
    dc.b    $31,$11   ; w <-> z
    dc.b    $29,$37   ; m <-> ,
    dc.b    $37,$38   ; m <-> ,
    dc.b    $39,$29   ; . <-> ;
    dc.b    $3A,$01   ; / <-> !
    dc.b    -1    
deutsch:
    dc.b    $15,$31   ; y -> z
    dc.b    $31,$15   ; z -> y
    dc.b    -1    
    even
    
_tag		dc.l	WHDLTAG_CUSTOM5_GET
_keyboard_type	dc.l	0
		dc.l	WHDLTAG_LANG_GET
_language	dc.l	0
		dc.l	0

;============================================================================

	END
