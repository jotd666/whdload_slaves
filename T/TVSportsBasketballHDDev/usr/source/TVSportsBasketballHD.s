;*---------------------------------------------------------------------------
;  :Program.	TVSportsBasketballHD.asm
;  :Contents.	Slave for "TVSportsBasketball"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: TVSportsBasketballHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	INCLUDE	dos/dosextens.i

;;CHIP_ONLY
	IFD BARFLY
	OUTPUT	"TVSportsBasketball.slave"
	IFND	CHIP_ONLY
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
SETPATCH
;STACKSIZE = 10000
BOOTDOS
;CACHECHIPDATA
CACHE
; ATM segtracker option triggers access fault
;SEGTRACKER

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	include	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
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

assign_1
	dc.b	"REEL1",0
assign_2
	dc.b	"REEL2",0

slv_name		dc.b	"TV Sports Basketball"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1990 Cinemaware",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"bb",0
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
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
		lea	my_dosbase(pc),a0
		move.l	d0,(a0)


	;assigns
		lea	assign_1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	assign_2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

        IFD CHIP_ONLY
        movem.l a6,-(a7)
        move.l  4,A6
        move.l  #$10000-$B9B0,d0
        move.l  #MEMF_CHIP,d1
        jsr (_LVOAllocMem,a6)
        movem.l (a7)+,a6
        ENDC
	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; patch according to version

VERSION_PL:MACRO
.\1
	lea	pl_\1(pc),a0
	bra.b	.out
	ENDM

get_version:
	movem.l	d0-d1/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#169756,D0
	beq.b	.sps

	cmp.l	#170156,d0
	beq.b	.alt


	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.out
	movem.l	(a7)+,d0-d1/a1
	rts
    
	VERSION_PL	sps
	VERSION_PL	alt

    
PATCH_DOSLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	my_dosbase(pc),a6
	move.l	A6,A1
	add.l	#_LVO\1,A1
	moveq	#0,D0
	move.w	4(A1),D0
	addq.l	#4,D0
	add.l	D0,A1

	lea	old_\1(pc),a0
	move.l	A1,(A0)+

	move.l	A6,A1
	add.l	#_LVO\1,A1
	move.b	1(A1),D0
	ext.w	D0
	ext.l	D0
	move.l	D0,(A0)		; moves to d0_value_xxx

	move.w	#$4EF9,(A1)+	
	pea	new_\1_init(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
new_\1_init
	move.l	d0_value_\1(pc),d0
	bra	new_\1
old_\1:
	dc.l	0
d0_value_\1
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1
	ENDM


my_dosbase
	dc.l	0
loaded_segment
	dc.l	0

patch_dos
	PATCH_DOSLIB_OFFSET	LoadSeg
	rts

new_LoadSeg:
	pea	.cont(pc)
	move.l	old_LoadSeg(pc),-(A7)
	rts
.cont
	movem.l	d0-a6,-(a7)

	lea	loaded_segment(pc),a0
	move.l	d0,(a0)

	addq.l	#1,D0
	add.l	D0,D0
	add.l	D0,D0
	move.l	D0,A1	; loaded segment


	movem.l	(a7)+,d0-a6
	tst.l	D0
	rts

; < d7: seglist (APTR)


patch_main
;;	bsr	patch_dos
    bsr get_version	

	moveq	#0,d2
	bsr	get_section

	jsr	resload_Patch(a2)
	rts

pl_sps
	PL_START
	PL_NOP	$3380,2	; remove CloseWorkbench loop
	PL_B	$3390,$60	; crack?
;;	PL_BKPT	$4314
	PL_NOP	$5692,4   ; skip this else it reboots kickemu...
    PL_P    $656c,flush_after_table_build
;;	PL_L	$5704,$4E714E71
;;	PL_P	$6F46,create_proc
    PL_PS    $4e7e,fix_audio_access_fault_8
    PL_PS    $4e42,fix_audio_access_fault_12
	PL_END
pl_alt
	PL_START
	PL_NOP	$3374,2	; remove CloseWorkbench loop
	PL_B	$3384,$60	; crack?
    PL_P    $6554,flush_after_table_build
	PL_NOP	$00567a,4   ; skip this else it reboots kickemu...
    PL_PS    $4e66,fix_audio_access_fault_8
    PL_PS    $4e2a,fix_audio_access_fault_12
	PL_END
    
flush_after_table_build
    ; the program builds a table and returns there... crazy SMC
    ; where I thought it was a "simple" MANXs C overlayed program
    bsr _flushcache
	MOVEM.L (A7)+,D0-D2/A0-A4    ;006554: 4cdf1f07
	RTS                          ;006558: 4e75

; when green player (left) wins the tipoff, D0 is > 3
; and there is an access fault when writing to audio registers

FIX_AUDIO_AF:MACRO
fix_audio_access_fault_\1:
	CLR.L   D0                   ;004e66: 4280
	MOVE.W  $\1(A5),D0         ;004e68: 302d0008
.skip
    and.w   #3,d0
    rts
    ENDM
    
    FIX_AUDIO_AF    8
    FIX_AUDIO_AF    12

    IFEQ    1
fix_audio_access_fault_avoid:
	CLR.L   D0                   ;004e66: 4280
	MOVE.W  $0008(A5),D0         ;004e68: 302d0008
    cmp.w   #4,d0
    bcc.b   .avoid
    rts
.avoid
    
    ; don't write into random memory because D0 > 3
    addq.l  #4,(a7)
	UNLK    A5                   ;004e92: 4e5d
	RTS                          ;004e94: 4e75
    ENDC
    
create_proc
	move.l	d3,d0
	addq.l	#1,d0
	add.l	d0,d0
	add.l	d0,d0
	illegal

	JSR	_LVOCreateProc(A6)	;(dos.library)
	MOVE.L	(A7)+,D4	; 006F4A: 	281F	
	RTS	; 006F4C: 	4E75	

; < d7 seglist
; < d2 section #
; > a1 segment
get_section
	move.l	d7,a1
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a1),a1
	add.l	a1,a1
	add.l	a1,a1
	dbf	d2,.loop
.out
	addq.l	#4,a1
	rts


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

    ; program detaches from CLI
    ; we have to wait else it quits before starting...
    
	move.l	$4,a6
	moveq	#0,d0
	jsr	_LVOWait(a6)

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

_saveregs
		ds.l	16,0
_stacksize
		dc.l	0

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1		dc.l	0
		dc.l	0

;============================================================================

	END
