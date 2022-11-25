;*---------------------------------------------------------------------------
;  :Program.	BladeHD.asm
;  :Contents.	Slave for "Blade"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BoppinHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"Blade.slave"
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


    IFD AGA
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $200000   ; no fast: out of memory when loading music => access fault
    ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
    ENDC
BLACKSCREEN


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

slv_Version	= 17
slv_keyexit	= $5D	; num '*'
    IFD AGA
INITAGA
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ReqAGA|WHDLF_ClearMem
	include	whdload/kick31.s
    ELSE
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
	include	whdload/kick13.s
    ENDC
    
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.0"
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
	dc.b	0
    IFND    AGA
assign1
	dc.b	"Blade1",0
assign2
	dc.b	"Blade2",0
gfx
    dc.b    "OCSData",0
    ENDC
    
slv_name		dc.b	"Blade"
	IFD	AGA
	dc.b	" AGA"
	ENDC
			dc.b	0
slv_copy		dc.b	"1997 Alive Mediasoft",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

intro:
	dc.b	"intro",0
program:
	dc.b	"blade",0
args		dc.b	10
args_end
	dc.b	0
slv_config
    IFD AGA
	dc.b    "C1:B:skip intro;"
    ENDC
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN


_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)

	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
        

        IFND AGA
	;assigns
		lea	assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	assign2(pc),a0
		lea gfx(pc),a1
		bsr	_dos_assign
        ELSE
        move.l  skip_intro(pc),d0
        bne.b   .nointro
		lea	intro(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
        ; no VBR or anything to fix in intro
		sub.l   a5,a5
		bsr	load_exe
.nointro        
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

; < d7: seglist (APTR)
SEGMENT_SIZE = $20000

patch_main
	lea	pl_main(pc),a0    
    move.l  d7,a1
	jsr	resload_PatchSeg(a2)
    rts
    
; apply on SEGMENTS
pl_main
    PL_START
    ; VBR read
    PL_DATA $0066e,4
    sub.l   a0,a0
    nop
    
    ; fix color bit
    PL_ORW  $086dc+2,$200   ; AGA
    PL_ORW  $09810+2,$200   ; ECS status
    PL_ORW  $0989c+6,$200   ; another ECS copperlist (ECS game?)
    
    IFD    AGA
    PL_PSS    $0139a,alloc_screen_memory,4
    PL_P    $013c2,free_screen_memory
    
    ELSE
    ;;PL_S    $102,$3A    ; force ECS (not really needed)
    ENDC

    PL_END

    IFD    AGA

    ; the remaining memory after the menu gfx HAS to be 0
    ; but it is not: menu screen memory fills it with some non-zero
    ; data, and afterwards some more chip is allocated: status bar is
    ; trashed
    ;    
    ; fixes one of the issues with main game (trashed
    ; bottom display) 
    ; alloc only once the first time
alloc_screen_memory
    lea  allocated_buffer(pc),a0
    tst.l   (a0)
    bne.b   .ok
	MOVE.L	#$00010002,D1		;0139a: 223c00010002
	JSR	(_LVOAllocMem,A6)	;013a0: 4eaeff3a exec.library (off=-198)
    lea allocated_buffer(pc),a0
    move.l  d0,(a0)     ; store
.ok
    move.l  (a0),d0
    rts
    
; hook on menu screen memory free and clear it
; but don't free it as some other stuff can allocate
; and trash the memory
free_screen_memory
    move.l   #$00014000/4-1,d1
.clr
    clr.l   (a1)+
    dbf d1,.clr
    ; don't free memory, keep it allocated
    rts
    ENDC
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

_saveregs
		ds.l	16,0
_stacksize
		dc.l	0

tag		dc.l	WHDLTAG_CUSTOM1_GET
skip_intro	dc.l	0

		dc.l	0
		dc.l	0

allocated_buffer
    dc.l    0
        
;============================================================================

	END
