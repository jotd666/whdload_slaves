;*---------------------------------------------------------------------------
;  :Program.	BoppinHD.asm
;  :Contents.	Slave for "Boppin"
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

;CHIP_ONLY
	IFD BARFLY
	OUTPUT	"BlackDawnRebirth.slave"
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
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $100000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
;DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE
NO68020

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	include	whdload/kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.2"
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


slv_name		dc.b	"Black Dawn Rebirth"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"2019 Doublesided Games",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

intro:
	dc.b	"intro",0
flashtro:
	dc.b	"trainer",0
program:
	dc.b	"BD",0
args		dc.b	10
args_end
	dc.b	0
slv_config
	dc.b    "C1:X:show flashtro:0;"
	dc.b    "C3:B:skip introduction;"
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN


_bootdos
		clr.l	$0.W

    move.l  _resload(pc),a2
    lea tag(pc),a0
    jsr (resload_Control,a2)
    
	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload

	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
        
       IFD CHIP_ONLY
       movem.l a6,-(a7)
		move.l	$4.w,a6
       move.l  #$50000-$44520,d0
       move.l  #MEMF_CHIP,d1
       jsr _LVOAllocMem(a6)
       movem.l (a7)+,a6
       ENDC

	;load exe
		move.l	trainer_flags(pc),d0
		btst	#0,d0
		beq.b	.skip_flashtro
		lea	flashtro(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_train(pc),a5
		bsr	load_exe
		; copy trainer memory flags set by flashtro
		lea	$7FF00,a0
		lea	flashtro_trainer_flags(pc),a1
		move.l	(a0)+,(a1)+
		move.b	(a0)+,(a1)+
.skip_flashtro
        move.l  skip_intro(pc),d0
        bne.b   .skip
	;load exe
		lea	intro(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		sub.l   a5,a5
		bsr	load_exe
.skip
	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)


patch_train
	lea	pl_train(pc),a0   
    move.l  d7,a1
	jsr	resload_PatchSeg(a2)
	rts

	
; < d7: seglist (APTR)

patch_main
	lea	pl_main(pc),a0   
    move.l  d7,a1
	jsr	resload_PatchSeg(a2)

	; trainer
	lea		trainer_patchlists(pc),a3
	lea		trainer_flags(pc),a4
	move.l	a3,a5
	move.w	#4,d6
.loop
	move.w	(a5)+,a0	; get next patchlist
	add.l	a3,a0	
	tst.b	(a4)+
	beq.b	.no_train
	move.l	d7,a1
	jsr	resload_PatchSeg(a2)
.no_train
	dbf	d6,.loop
	rts

CENTRAL_OFFSET = $0d1fa

pl_train_unpacked
	PL_START
	PL_R	$0184	; remove vpos wait that locks up with whdload
	PL_P	$012a,get_vbr
	PL_P	$1030,get_vbr
	PL_END
	
pl_train
	PL_START
	PL_P	$1ba,end_unpack
	PL_END
	
pl_health
	PL_START
	PL_NOP	(CENTRAL_OFFSET+9688),2
	PL_END
pl_stamina
	PL_START
	PL_NOP	(CENTRAL_OFFSET+25178),2	
	PL_END
pl_energy
	PL_START
	PL_NOP	CENTRAL_OFFSET,2		
	PL_NOP	(CENTRAL_OFFSET+50),2		
	PL_NOP	(CENTRAL_OFFSET-50),2		
	PL_NOP	(CENTRAL_OFFSET+100),2		
	PL_END
pl_ammo
	PL_START
	PL_NOP	(CENTRAL_OFFSET+15874),4
	PL_NOP	(CENTRAL_OFFSET+16108),4
	PL_END
pl_one_hit_kills
	PL_START
	PL_W	(CENTRAL_OFFSET+26612),$4290		
	PL_W	(CENTRAL_OFFSET+28988),$4290	
	PL_END


; apply on SEGMENTS
pl_main
    PL_START
    PL_P   $29290,set_word
    ;PL_PS   $40918,set_copper
    PL_END
 
get_vbr
	clr.l	d0
	rte
	
set_word
	BTST	#0,D0			;29290: 08000000
	BNE.S	LAB_0601		;29294: 6604
    cmp.l   #$DFF1DC,A0     ; avoid NTSC change
    beq.b   .skip
	MOVE.W	D3,(A0)			;29296: 3083
.skip
	RTS				;29298: 4e75
LAB_0601:
	MOVE.B	D3,1(A0)		;2929a: 11430001
	LSR.W	#8,D3			;2929e: e04b
	MOVE.B	D3,(A0)			;292a0: 1083
	RTS				;292a2: 4e75

end_unpack
	MOVEM.L	(A7)+,D0-D7/A0-A6	;001c6: 4cdf7fff
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	20(a7),a1		; return address
	lea	pl_train_unpacked(pc),a0
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
	movem.l (a7)+,d0-d1/a0-a2
	RTS				;001ca: 4e75
   
get_version:
	movem.l	d1/a0/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#297224,D0
    bra.b   .original       ; FORCED
    
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.original
	moveq	#1,d0
    bra.b   .out
    nop

.out
	movem.l	(a7)+,d1/a0/a1
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

tag		dc.l	WHDLTAG_CUSTOM3_GET
skip_intro	dc.l	0
	dc.l	WHDLTAG_CUSTOM1_GET
trainer_flags	dc.l	0

		dc.l	0
		dc.l	0
trainer_patchlists
	dc.w	pl_health-trainer_patchlists
	dc.w	pl_stamina-trainer_patchlists
	dc.w	pl_energy-trainer_patchlists
	dc.w	pl_ammo-trainer_patchlists
	dc.w	pl_one_hit_kills-trainer_patchlists
flashtro_trainer_flags
unl_health
	dc.b	0
unl_stamina
	dc.b	0
unl_energy
	dc.b	0
unl_ammo
	dc.b	0
one_hit_kills
	dc.b	0
	dc.b	0

	
;============================================================================

	END
