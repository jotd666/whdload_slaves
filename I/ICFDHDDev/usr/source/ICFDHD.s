;*---------------------------------------------------------------------------
;  :Program.	ICFDHD.asm
; :Contents.  Slave for "ICFD" ; :Author.  JOTD, from Wepl sources ;
;*--------------------------------------------------------------------------


	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"ICFD.slave"
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

	IFD	CHIP_ONLY
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC
	
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
HDINIT
DEBUG
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
CACHE
BOOTDOS

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s


;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_assign1
	dc.b	"desert1",0
_assign2
	dc.b	"desert2",0
_assign3
	dc.b	"desert3",0
_assign4
	dc.b	"DES4",0
_assign5
	dc.b	"DSAVE",0

DECL_VERSION:MACRO
	dc.b	"2.1"
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

slv_name		dc.b	"It Came From The Desert I/II"
		IFD		CHIP_ONLY
		dc.b	" (debug/chip mode)"
		ENDC
				dc.b	0
slv_copy		dc.b	"1989 Cinemaware/Mirrorsoft",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

program:
	dc.b	"dshell",0
args		dc.b	10
args_end
	dc.b	0
	EVEN



;============================================================================


	;initialize kickstart and environment

_bootdos
	clr.l	$0.W


	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

	move.l	(_resload,pc),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
		lea		dosbase(pc),a0
		move.l	d0,(a0)
		
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
		lea	_assign4(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign5(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign


	move.l	a6,-(a7)
	IFD	CHIP_ONLY
	move.l	#$20000-$1c0c0,d0
	move.l	#MEMF_CHIP,d1
	move.l	4,a6
	jsr		_LVOAllocMem(a6)
	ENDC
	move.l	(a7)+,a6
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

patch_main
	move.l	d7,a1
	addq.l	#4,a1
	move.l	_resload(pc),a2
	bsr	get_version
	; d1 = 0: patch immediately
	tst.b	d1
	beq	.patch
	
	; else, emulate trace vector decoder routine
	; unpack decrypted part (that we ripped from an execution from
	; WinUAE with a working config)
	;
	; that part was NOT a piece of cake but with winuae it was done in
	; a few hours. I'm sure Stingray would have blasted that with a cleaner
	; solution in 30 minutes but he's busy somewhere else so ... :)
	;
	; that TVD part was NOT Rob Northen, and was NOT Ben Herdnon. It was something
	; hybrid. And I don't even know if the disk is protected after all...
	
	movem.l	a0-a2,-(a7)

	; compute future A4 value
	move.l	d7,a3
	move.l	(a3),d0	; data segment
	add.l	d0,d0
	add.l	d0,d0	; as APTR
	addq.l	#4,d0	; segment start
	lea		varzone(pc),a0
	add.l	#32768-2,d0

	move.l	d0,(a0)

	move.l	a1,a6

	lea		decrypted(pc),a0
	jsr		resload_Decrunch(a2)

	; move data, the encrypted part does that
	
	lea		($5A40,a6),a3
	lea		($4FF8,a6),a4
	move.l	#($24544-$5A40)/4-1,d0
.copy
	move.l	(a3)+,(a4)+
	dbf	d0,.copy

	; what is missing there is "just" 3 relocation entries (the rest is position independent!)
	; - the variable zone address (that we computed properly with segment address
	;   and stored in "varzone"
	; - the first jump at offset 0 that skips decrypted start data to entry
	; - the address of the load reloc segment in A4 routine
	;
	movem.l	(a7)+,a0-a2
.patch
	jsr	resload_Patch(a2)
	rts



; patch according to version

VERSION_PL:MACRO
.\1
	lea	pl_\1(pc),a0
	bra.b	.out
	ENDM

get_version:
	movem.l	d0/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)
	clr		d1
	
	cmp.l	#160332,D0
	beq.b	.main_1

	cmp.l	#170972,d0
	beq.b	.main_antheads
	

	cmp.l	#160428,D0
	beq.b	.main_sps14		; SPS version 14
	
	cmp.l	#173588,d0
	bne.b	.wrong_version
	st.b	d1
	
	bra.b	.main_antheads_sps
.wrong_version
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

	VERSION_PL	main_1
	VERSION_PL	main_antheads
	VERSION_PL	main_antheads_sps
	VERSION_PL	main_sps14
	nop
.out
	movem.l	(a7)+,d0/a1
	rts

; < D0: numbers of "ticks" to wait
; these are not DBFs but active for(i=0;i<xxx;i++); C loops
;LAB_0216
;	ADDQ.L	#1,-4(A5)		;03330: 52adfffc
;	CMPI.L	#$000061a8,-4(A5)	;03334: 0cad000061a8fffc
;	BLT.S	LAB_0216		;0333c: 6df2

cpu_delay_emulation:
	movem.l	D0-D2,-(A7)
	move.l	d0,d2
	lsr.l	#3,D2	; divide
.loop
	moveq	#1,d2
	bsr	beamdelay
	subq.l	#1,d2
	bne.b	.loop
	movem.l	(a7)+,D0-D2
	rts


emulate_delay_4a5:
	movem.l	D0,-(A7)
	move.l	-4(A5),D0
	bsr	cpu_delay_emulation
	movem.l	(a7)+,d0
	addq.l	#6,(A7)
	rts

emulate_delay_4a5_2:
	movem.l	D0,-(A7)
	move.l	#100,D0
	bsr	cpu_delay_emulation
	movem.l	(a7)+,d0
	addq.l	#6,(A7)
	rts


emulate_delay_2a5:
	movem.l	D0,-(A7)
	move.l	#10000,D0
	bsr	cpu_delay_emulation
	movem.l	(a7)+,d0
	addq.l	#6,(A7)
	rts

emulate_delay_10a5:
	movem.l	D0,-(A7)
	move.l	#$4E20,D0
	bsr	cpu_delay_emulation
	movem.l	(a7)+,d0
	addq.l	#8,(A7)
	rts

emulate_delay_16a5:
	movem.l	D0,-(A7)
	move.l	#$C350,D0
	bsr	cpu_delay_emulation
	movem.l	(a7)+,d0
	addq.l	#8,(A7)
	rts

emulate_delay_12812a4:
	movem.l	D0,-(A7)
	move.l	-12812(A4),D0
	bsr	cpu_delay_emulation
	movem.l	(a7)+,d0
	addq.l	#6,(A7)
	rts

emulate_delay_12820a4:
	movem.l	D0,-(A7)
	move.l	-12820(A4),D0
	bsr	cpu_delay_emulation
	movem.l	(a7)+,d0
	addq.l	#6,(A7)
	rts

emulate_delay_10894a4:	; antheads
	movem.l	D0,-(A7)
	move.l	-10894(A4),D0
	bsr	cpu_delay_emulation
	movem.l	(a7)+,d0
	addq.l	#6,(A7)
	rts


pl_main_sps14
	PL_START
	; difficult-to-find cpu-dependent loops
	; (found with a tool I have written in Python
	; to detect cpu-dependent loops)
	PL_PS	$3330,emulate_delay_4a5
	PL_PS	$334A,emulate_delay_4a5
	PL_PS	$9706,emulate_delay_12812a4
	PL_PS	$9FC2,emulate_delay_2a5
	PL_PS	$10286,emulate_delay_10a5
	PL_PS	$104B0,emulate_delay_16a5

	PL_PS	$16F24,active_d1_loop
	PL_PS	$F4D2,move_d6_dmacon
	PL_PS	$F51A,move_d6_dmacon
	PL_PS	$F526,move_d0_dmacon
	PL_PS	$1eae6,wait_blit_3
	PL_END

pl_main_1
	PL_START
	; difficult-to-find cpu-dependent loops
	; (found with a tool I have written in Python
	; to detect cpu-dependent loops)
	PL_PS	$331E,emulate_delay_4a5
	PL_PS	$3338,emulate_delay_4a5
	PL_PS	$9688,emulate_delay_12820a4
	PL_PS	$9F44,emulate_delay_2a5
	PL_PS	$10208,emulate_delay_10a5
	PL_PS	$10436,emulate_delay_16a5

	PL_PS	$16EA6,active_d1_loop
	PL_PS	$F454,move_d6_dmacon
	PL_PS	$F49C,move_d6_dmacon
	PL_PS	$F4A8,move_d0_dmacon
	PL_PS	$1EA92,wait_blit_1
	PL_END

pl_main_antheads
	PL_START
	; difficult-to-find cpu-dependent loops
	; (found with a tool I have written in Python
	; to detect cpu-dependent loops)
	PL_PS	$36e2,emulate_delay_4a5
	PL_PS	$36fc,emulate_delay_4a5
	PL_PS	$aa54,emulate_delay_10894a4
;;	PL_PS	$9xxx,emulate_delay_2a5
	PL_PS	$11a76,emulate_delay_10a5
	PL_PS	$11ca0,emulate_delay_16a5
	PL_PS	$13ecc,emulate_delay_4a5_2

	PL_PS	$187B4,active_d1_loop
	PL_PS	$10CC0,move_d6_dmacon
	PL_PS	$10D08,move_d6_dmacon
	PL_PS	$10D14,move_d0_dmacon
	PL_PS	$20B0A,wait_blit_2
	PL_END
	
pl_main_antheads_sps
	PL_START
	; needs to fix the startup
	PL_PS	0,jump_to_real_entry
	; needs to correct just one call
	PL_PS	$20410,load_a4_base
	
	; fix lock
	;;PL_PSS	$22B06,fix_root_lock,2
	
	; quit on error
	PL_I	$22a48
	PL_I	$23408
	PL_END
	
pl_xxx
	PL_START
	; difficult-to-find cpu-dependent loops
	; (found with a tool I have written in Python
	; to detect cpu-dependent loops)
	PL_PS	$36e2,emulate_delay_4a5
	PL_PS	$0aa3a,emulate_delay_10894a4
;;	PL_PS	$9xxx,emulate_delay_2a5
	PL_PS	$11a5c,emulate_delay_10a5
	PL_PS	$11c86,emulate_delay_16a5
	PL_PS	$13eb0,emulate_delay_4a5_2

	PL_PS	$18798,active_d1_loop
	PL_PS	$10ca6,move_d6_dmacon
	PL_PS	$10cee,move_d6_dmacon
	PL_PS	$10cfa,move_d0_dmacon
	PL_PS	$20aee,wait_blit_2
	PL_END

	
		
jump_to_real_entry
	add.l	#$22998,(a7)
	add.l	#2,(a7)		; skip load a4
	bsr		load_a4_base
	rts
	
load_a4_base
	move.l		varzone(pc),a4
	rts
	
	
wait_blit_3
	bsr	wait_blit	
	move.w	10854(a4),$dff044
	addq.l	#2,(a7)
	rts

wait_blit_1
	bsr	wait_blit	
	move.w	10846(a4),$dff044
	addq.l	#2,(a7)
	rts

wait_blit_2
	bsr	wait_blit	
	move.w	13454(a4),$dff044
	addq.l	#2,(a7)
	rts

wait_blit
	TST.B	dmaconr+$DFF000
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	bra.s	.end
.wait
	TST.B	$BFE001
	TST.B	$BFE001
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	TST.B	dmaconr+$DFF000
.end
	rts

move_d6_dmacon
	move	d6,$dff096	; sound
	move.l	d1,-(a7)
	moveq	#7,d1
	bsr	beamdelay
	move.l	(a7)+,d1
	rts

move_d0_dmacon
	move	d0,$dff096	; sound
	move.l	d1,-(a7)
	moveq	#7,d1
	bsr	beamdelay
	move.l	(a7)+,d1
	rts

active_d1_loop
	swap	D1
	clr.w	D1
	swap	D1
	divu.w	#$28,D1
	swap	D1
	clr.w	D1
	swap	D1
	bsr	beamdelay

	clr.l	D1

	rts

; < D1: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  D1,-(a7)
        move.b	$dff006,D1	; VPOS
.bd_loop2
	cmp.b	$dff006,D1
	beq.s	.bd_loop2
	move.w	(a7)+,D1
	dbf	D1,.bd_loop1
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

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
		dc.l	0
dosbase
	dc.l	0
varzone
	dc.l	0
decrypted
	incbin	"decrypt.rnc"
;============================================================================
