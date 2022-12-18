;*---------------------------------------------------------------------------
;  :Program.	PortalHD.asm
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
	OUTPUT	"Portal.slave"
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
STACKSIZE = 24000		; game needs at least 23500

;CHIP_ONLY
; amount of memory available for the system
	IFD	CHIP_ONLY
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $50000
	ENDC
	

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'


;============================================================================

	INCLUDE	whdload/kick13.s
	
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
slv_name		dc.b	"Portal"
			IFD		CHIP_ONLY
			dc.B	" (debug/chip mode)"
			ENDC
			
			dc.b	0
slv_copy		dc.b	"1986 Activision",0
slv_info		dc.b	"Adapted by JOTD",10,10
			dc.b	"Thanks to Tony Aksnes & BTTR for disk images",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

_assign1:
	dc.b	"PORTAL1",0
_assign2:
	dc.b	"PORTAL2",0
_assign3:
	dc.b	"PORTAL3",0

slv_config:
	dc.b	"C5:B:skip introduction;"
	dc.b	0

_intro:
	dc.b	"title",0

_program:
	dc.b	"main",0
_args:
	dc.b	10
_args_end:
	dc.b	0
	even


PATCH_XXXLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
	lea	old_\1(pc),a0
	move.l	2(A1),(A0)
	move.w	#$4EF9,(A1)+	
	pea	new_\1(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
old_\1:
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1
    ENDM
	
;============================================================================

	;initialize kickstart and environment

_bootdos
		lea		_stacksize(pc),a0
		move.l	(4,a7),(a0)		; store stacksize
		sub.l	#5*4,(a0)			;required for MANX stack check
	
		move.l	(_resload,pc),a2	;a2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
		
		lea	(_gfxname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = gfxbase

        PATCH_XXXLIB_OFFSET RectFill
        PATCH_XXXLIB_OFFSET Text


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
		lea	_assign3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign


	;load exe
		move.l	_skip_intro(pc),d0
		bne.b	.si
		lea	_intro(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		sub.l	a5,a5
		bsr	load_exe
.si		
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
	move.l	_resload(pc),a2
	lea		pl_main(pc),a0
	jsr		resload_PatchSeg(a2)
	
	rts
	
; call graphics.library function then wait
DECL_GFX_WITH_WAIT:MACRO
new_\1
    pea .next(pc)
	move.l	old_\1(pc),-(a7)
	rts
.next:
    bra wait_blit
    ENDM
    
    
    ; the calls where a wait is useful
    DECL_GFX_WITH_WAIT  RectFill
    DECL_GFX_WITH_WAIT  Text
   
wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts
	
pl_main
	PL_START
	PL_B	$3B4,$66
	PL_P	$10E8,_quit


	PL_L	$2eEE6,$70004E75
	
	PL_END

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
_skip_intro	dc.l	0
		dc.l	0
_seglist:
	dc.l	0
_msq:
	dc.w	0
_saveregs
		ds.l	16,0
_stacksize
		dc.l	0
_gfxname
	dc.b	"graphics.library",0
	