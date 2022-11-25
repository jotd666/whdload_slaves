;*---------------------------------------------------------------------------
;  :Program.	ColonizationHD.asm
;  :Contents.	Slave for "Colonization"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: ColonizationHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
    IFD AGA
	OUTPUT	"ColonizationAGA.slave"
    ELSE
	OUTPUT	"ColonizationECS.slave"
	ENDC
	ENDC

    IFD AGA
INITAGA
	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $100000
	ENDC
    ELSE
NO68020
	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $180000
	ENDC    
    ENDC
;============================================================================


NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

    IFD AGA
	include	whdload/kick31.s    
    ELSE
	include	whdload/kick13.s
    ENDC
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

assign1
	dc.b	"Colonization Disk 1",0
assign2
	dc.b	"Colonization Disk 2",0
assign3
	dc.b	"Colonization Disk 3",0

slv_name		dc.b	"Colonization"
    IFD AGA
    dc.b " (AGA)"
    ENDC
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1995 Microprose",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
	dc.b    "C5:L:keyboard:us,fr,de;"	
	dc.b	0

program:
	dc.b	"Colonization",0
args		dc.b	10
args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	(_resload,pc),a2		;A2 = resload

	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)

        move.l  _keyboard_type(pc),d0
        cmp.l   #3,d0
        bcs.b   .kbbounds
        moveq.l #0,d0
.kbbounds
        
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

	;assigns
		lea	assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	assign3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		sub.l	a5,a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)


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
    dc.b    -1    
deutsch:
    dc.b    $15,$31   ; y -> z
    dc.b    $31,$15   ; z -> y
    dc.b    -1    
    even
    
; < d7: seglist (APTR)



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

_saveregs
		ds.l	16,0
_stacksize
		dc.l	0

tag	
    dc.l	WHDLTAG_CUSTOM5_GET
_keyboard_type	dc.l	0
  
		dc.l	0

;============================================================================

	END
