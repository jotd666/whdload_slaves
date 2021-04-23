;*---------------------------------------------------------------------------
;  :Program.	LegacyOfSorasilHD.asm
;  :Contents.	Slave for "LegacyOfSorasil"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: LegacyOfSorasilHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

;CHIP_ONLY
	IFD BARFLY
	OUTPUT	"HeroQuest2.slave"
	IFND	DEBUG
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	ENDC
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================


	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE
; SEGTRACKER  yielding false results, maybe because file is packed?

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

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


assign_1
	dc.b	"Legacy Of Sorasil DISK 1",0
assign_2
	dc.b	"Legacy Of Sorasil DISK 2",0
assign_3
	dc.b	"Legacy Of Sorasil DISK 3",0

slv_name		dc.b	"Hero Quest II - Legacy Of Sorasil"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1992 Gremlin",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"QuestII.RNC",0
program2:
	dc.b	"QuestII",0
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

		move.l	_resload(pc),a2		;A2 = resload

	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)

    IFD CHIP_ONLY
    move.l  4,A6
    move.l  #0,D1
    move.l  #$20000-$1C330,d0
    jsr (_LVOAllocMem,a6)
    ENDC

	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	assign_1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	assign_2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	assign_3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	program(pc),a0
        bsr get_file_size
        tst.l   d0
        bne.b   .cont
       
		lea	program2(pc),a0
        bsr get_file_size
.cont
        lea program_name(pc),a1
        move.l  a0,(a1)
        ; d0: size
        ; a0: filename

        cmp.l   #79864,d0
        beq.b   .ok
        cmp.l	#161420,d0
        beq.b	.ok
        ; wrong size or missing questII / questII.rnc
        pea	TDREASON_WRONGVER
        move.l	_resload(pc),-(a7)
        addq.l	#resload_Abort,(a7)
        rts

.ok
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

get_file_size
    move.l  a0,-(a7)
    jsr (resload_GetFileSize,a2)
    move.l  (a7)+,a0
    rts
    
; < d7: seglist (APTR)


patch_main
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	program_name(pc),A0
	bsr get_file_size
    move.l  d7,a1
    
	cmp.l	#79864,D0
	beq.b	.orig_packed

	cmp.l	#161420,d0
	beq.b	.unpacked


	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.orig_packed:
	lea	pl_packed(pc),a0
	bra.b	.patch_s0

.unpacked:
	lea	pl_unpacked(pc),a0
.patch_s0
	jsr	resload_PatchSeg(a2)
.out
	movem.l	(a7)+,d0-d1/a0-a2
	rts

pl_packed
	PL_START
	PL_P	$240,after_decrunch
	PL_END
	
pl_unpacked
	PL_START
	PL_W	$F840,$6036	; remove protection
    ; addressing mode fix: move.w $12,D1 => move.w #$12,D1
	PL_L	$0a3e6,$323c0012
	PL_NOP	$0a3eA,2
    
    ; shortcut to quit, avoids access fault
    PL_P    $006de,_quit
    
    ; fixed music
    PL_PSS  $0a0a0,soundtracker_loop,2
    PL_PSS  $0a0b4,soundtracker_loop,2
    
	PL_END
    
soundtracker_loop
	move.w  d0,-(a7)
	move.w	#7,d0   ; make it 7 if still issues
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
after_decrunch:
	MOVE.L	D1,(A7)			;00240: 2e81
	MOVEM.L	(A7)+,D0-D7/A0-A6	;00242: 4cdf7fff

	move.l	(a7),a1 ; return address is start of questII proggy
	move.l	_resload(pc),a2
	lea	pl_unpacked(pc),a0
	jsr	resload_Patch(a2)
	RTS
	
	
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

	bsr	update_task_seglist

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

_saveregs
		ds.l	16,0
_stacksize
		dc.l	0

update_task_seglist
	movem.l	d0/a0/a6,-(a7)
	move.l	$4,A6
	sub.l	a1,a1
	jsr	(_LVOFindTask,a6)
	move.l	d0,a0
	move.l	pr_CLI(a0),d0
	asl.l	#2,d0
	move.l	d0,a0

	; store loaded segments in current task

	move.l	d7,cli_Module(a0)

	movem.l	(a7)+,d0/a0/a6
	rts

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1		dc.l	0
		dc.l	0
program_name
    dc.l    0
    
;============================================================================

	END
