;*---------------------------------------------------------------------------
; Program:	HighwayHawks.s
; Contents:	Slave for "HighwayHawks" (c) 1988 Anco
; Author:	JOTD
; History:	
; Requires:	WHDLoad 16+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
;---------------------------------------------------------------------------*

		INCDIR	Include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i
		INCLUDE	lvo/dos.i

;;CHIP_ONLY

		IFD BARFLY
		OUTPUT	"HighwayHawks.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

    IFD CHIP_ONLY
CHIPMEMSIZE	= $C0000
FASTMEMSIZE	= $0000  
    ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $40000
    ENDC
NUMDRIVES	= 1
WPDRIVES	= %1111

;BLACKSCREEN
BOOTBLOCK
;BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
;CACHE
;DEBUG
DISKSONBOOT
;DOSASSIGN
;FONTHEIGHT	= 8
;HDINIT
;HRTMON
;IOCACHE		= 1024
;MEMFREE	= $100
;NEEDFPU
;POINTERTICKS	= 1
;SETPATCH
;STACKSIZE	= 6000
TRDCHANGEDISK
;CACHECHIPDATA
CACHE

;======================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D

;======================================================================

		INCLUDE	whdload/kick13.s

;======================================================================

		IFD	BARFLY
		IFND	.passchk
		DOSCMD	"WDate >T:date"
.passchk
		ENDC
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
    
slv_CurrentDir	dc.b	0
slv_name	dc.b	"Highway Hawks"
    IFD CHIP_ONLY
    dc.b    " (DEBUG/CHIP ONLY)"
    ENDC
    dc.b    0
slv_copy	dc.b	"1988 Anco",0
slv_info	dc.b	"Adapted & fixed by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		IFD	BARFLY
		dc.b	" "
		INCBIN	"T:date"
		ENDC
		dc.b	-1,"Thanks to Chris Vella for diskimages"
		dc.b	0
		EVEN


	dc.b	"$","VER: slave "
	DECL_VERSION
	IFD	BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
		dc.b	0
    even
    
;======================================================================

_bootblock
	movem.l	a0-a2/a6/d0-d1,-(A7)

	;get tags
	lea	(tag,pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Control,a2)


	lea	pl_bootblock(pc),a0
	move.l	a4,a1
	move.l	_resload(pc),a2

	jsr	resload_Patch(a2)
	movem.l	(a7)+,a0-a2/a6/d0-d1
	jsr	($C,a4)
	movem.l	a0-a2/a6/d0-d1,-(A7)

	ILLEGAL	; not reached
;	move.l	a0,a1
;	lea	pl_boot(pc),a0
;	move.l	_resload(pc),a2
;	jsr	resload_Patch(a2)

	movem.l	(a7)+,a0-a2/a6/d0-d1
	moveq.l	#0,D0
	rts

pl_bootblock
	PL_START
	PL_P	$40,patch_exe
	PL_END

patch_exe
	MOVEA.L	(A7)+,A1		;040: 225F
	MOVEA.L	(A5),A0			;042: 2055
	movem.l	d0-d1/a0-a2,-(a7)
    
    ;set segment tags
    move.l  _resload(pc),a2
    move.l  a0,d0
    subq.l  #4,d0
    lsl.l   #2,d0   ; BCPL
    lea (segments,pc),a0
    move.l  d0,(a0)
    lea	(segtag,pc),a0
	jsr	(resload_Control,a2)
    
	move.l	(a5),a1
	lea	pl_exe(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	pea	relocate_program(pc)	; game stores return address to call
					; the relocate_program routine
					; which is located after the JSR A0 in the boot!!

	pea	avoid_trap_15(pc)
	move.l	(a7)+,$BC.W

	JMP	(A0)			;044: 4E90

ABSEXECBASE = 4

; some CPUs trigger spurious interrupts, which the game does not like at all :)

avoid_trap_15
	; spurious interrupt occured: clear all
	move.w	#$7FFF,$DFF09C
	move.w	#$7FFF,$DFF09C

	; patch return from trap
	move.l	a0,-(a7)
	lea	.return(pc),a0
	move.l	a0,6(A7)	; so next RTE goes to "return"
	move.l	(a7)+,a0
	rte
.return
	rte

relocate_program
	bsr	do_relocate_program
	rts

load_another_exe
	; protection is OK
	moveq	#0,d0
	move.w	d0,d1
	rts

    
	;JSR	(A1)			;06B6: 4E91
	;CLR	D1			;06B8: 4241
	;MOVE.B	D0,D1			;06BA: 1200
	;rts

swap_disks
	move.b	#0,d0
	move.b	_trd_disk(pc),d1
	eor.b	#3,d1	; toggle between 1 and 2
	;d0.b = unit
	;d1.b = new disk image number
	bsr	_trd_changedisk

	add.l	#$22,(a7)	; skip the rest
	rts

do_relocate_program:
	TST.L	(A0)+			;046: 4A98
	BNE	relocate_program		;048: 6600FFFC
	MOVE.L	(A0)+,D7		;04C: 2E18
	MOVE.L	D7,D2			;04E: 2407
	ADDQ.L	#2,D2			;050: 5482
	LSL.L	#2,D2			;052: E58A
	ADDA.L	D2,A0			;054: D1C2
	SUBQ	#1,D7			;056: 5347
	MOVE	D7,D2			;058: 3407
	MOVEA.L	A1,A3			;05A: 2649
LAB_0001:
	CMPI.L	#$000003E9,(A0)+	;05C: 0C98000003E9
	BNE	LAB_0002		;062: 66000010
	MOVE.L	(A0)+,D0		;066: 2018
	LSL.L	#2,D0			;068: E588
	MOVE.L	A0,(A3)+		;06A: 26C8
	ADDA.L	D0,A0			;06C: D1C0
	MOVE.L	A0,(A3)+		;06E: 26C8
	BRA	LAB_0006		;070: 60000062
LAB_0002:
	CMPI.L	#$000003EA,-4(A0)	;074: 0CA8000003EAFFFC
	BNE	LAB_0003		;07C: 66000010
	MOVE.L	(A0)+,D0		;080: 2018
	LSL.L	#2,D0			;082: E588
	MOVE.L	A0,(A3)+		;084: 26C8
	ADDA.L	D0,A0			;086: D1C0
	MOVE.L	A0,(A3)+		;088: 26C8
	BRA	LAB_0006		;08A: 60000048
LAB_0003:
	CMPI.L	#$000003EB,-4(A0)	;08E: 0CA8000003EBFFFC
	BNE	LAB_0004		;096: 66000020
	MOVEM.L	A0-A1,-(A7)		;09A: 48E700C0
	MOVE.L	(A0)+,D0		;09E: 2018
	LSL.L	#2,D0			;0A0: E588
	MOVE.L	#$00010000,D1		;0A2: 223C00010000
	MOVEA.L	ABSEXECBASE.W,A6		;00E: 2C7900000004
	JSR	_LVOAllocMem(A6)	;(exec.library)
	MOVEM.L	(A7)+,A0-A1		;0AC: 4CDF0300
	MOVE.L	D0,(A3)+		;0B0: 26C0
	MOVE.L	A0,(A3)+		;0B2: 26C8
	BRA	LAB_0006		;0B4: 6000001E
LAB_0004:
	CMPI.L	#$000003EC,-4(A0)	;0B8: 0CA8000003ECFFFC
	BNE	LAB_0006		;0C0: 66000012
LAB_0005:
	MOVE.L	(A0)+,D0		;0C4: 2018
	ADDQ.L	#1,D0			;0C6: 5280
	LSL.L	#2,D0			;0C8: E588
	ADDA.L	D0,A0			;0CA: D1C0
	TST.L	(A0)			;0CC: 4A90
	BNE	LAB_0005		;0CE: 6600FFF4
	ADDQ.L	#4,A0			;0D2: 5888
LAB_0006:
	DBF	D2,LAB_0001		;0D4: 51CAFF86
	TST	D7			;0D8: 4A47
	BMI	LAB_000B		;0DA: 6B000036
	MOVEA.L	A1,A3			;0DE: 2649
LAB_0007:
	MOVEA.L	4(A3),A0		;0E0: 206B0004
	CMPI.L	#$000003EC,(A0)+	;0E4: 0C98000003EC
	BNE	LAB_000A		;0EA: 66000020
	MOVEA.L	(A3),A2			;0EE: 2453
LAB_0008:
	MOVE.L	(A0)+,D0		;0F0: 2018
	SUBQ.L	#1,D0			;0F2: 5380
	MOVE.L	(A0)+,D1		;0F4: 2218
	LSL.L	#3,D1			;0F6: E789
	MOVE.L	0(A1,D1.L),D1		;0F8: 22311800
LAB_0009:
	MOVE.L	(A0)+,D2		;0FC: 2418
	ADD.L	D1,0(A2,D2.L)		;0FE: D3B22800
	DBF	D0,LAB_0009		;102: 51C8FFF8
	TST.L	(A0)			;106: 4A90
	BNE	LAB_0008		;108: 6600FFE6
LAB_000A:
	ADDQ.L	#8,A3			;10C: 508B
	DBF	D7,LAB_0007		;10E: 51CFFFD0
LAB_000B:
	RTS				;112: 4E75
	
pl_exe
	PL_START	
	PL_S	$16,$22-$16		; skip 1st protection
	PL_PS	$6B6,load_another_exe	; skip 2nd protection
	PL_I	$6EE4
	PL_PS	$71AC,swap_disks

	PL_PS	$2DC2,fix_access_fault_1
	PL_PS	$6166,fix_access_fault_2
	PL_PS	$1944,fix_access_fault_3
    
    ; nop THEN waitblit (to save cycles)
    PL_NOP   $03B0,4
    PL_NOP   $3840,4
    PL_NOP   $387C,4
    PL_NOP   $38D8,4
    PL_NOP   $390E,4
    PL_NOP   $3966,4
    PL_NOP   $3A06,4
    PL_NOP   $4ADA,4
    PL_NOP   $4B24,4
    PL_NOP   $4BF4,4
    PL_NOP   $4C60,4
    PL_NOP   $6384,4
    PL_NOP   $63C4,4
    PL_NOP   $63EE,4
    PL_NOP   $652C,4
    
    PL_PS   $03B0+4,wait_blit
    PL_PS   $3840+4,wait_blit
    PL_PS   $387C+4,wait_blit
    PL_PS   $38D8+4,wait_blit
    PL_PS   $390E+4,wait_blit
    PL_PS   $3966+4,wait_blit
    PL_PS   $3A06+4,wait_blit
    PL_PS   $4ADA+4,wait_blit
    PL_PS   $4B24+4,wait_blit
    PL_PS   $4BF4+4,wait_blit
    PL_PS   $4C60+4,wait_blit
    PL_PS   $6384+4,wait_blit
    PL_PS   $63C4+4,wait_blit
    PL_PS   $63EE+4,wait_blit
    PL_PS   $652C+4,wait_blit
        
    
	PL_END
    
wait_blit
    BTST    #6,2(A0)
.wait
	BTST	#6,2(A0)		;03B0: 082800060002
	BNE.B	.wait		;03B6: 6600FFF8
    rts
    
fix_access_fault_1
	add.l	#2,(a7)

	MOVEA.L	0(A1,D0.W),A1		;2DC2: 22710000	; access fault?
	ADDA.L	4(A0),A1		;2DC6: D3E80004

	move.l	a1,d1
	bclr	#31,d1
	move.l	d1,a1
	rts

fix_access_fault_2
	add.l	#2,(a7)

	MOVEA.L	0(A4,D0.W),A4		;6166: 28740000
	ADDA.L	4(A6),A4		;616A: D9EE0004

	movem.l	d1,-(a7)
	move.l	a4,d1
	bclr	#31,d1
	move.l	d1,a4
	movem.l	(a7)+,d1

	rts

fix_access_fault_3
	add.l	#2,(a7)

	MOVEA.L	0(A3,D0.W),A3		;1944: 26730000
	ADDA.L	4(A1),A3		;1948: D7E90004

	movem.l	d1,-(a7)
	move.l	a3,d1
	bclr	#31,d1
	move.l	d1,a3
	movem.l	(a7)+,d1

	rts


;======================================================================

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1		dc.l	0
		dc.l	0

segtag		
        dc.l    WHDLTAG_DBGSEG_SET
segments:
		dc.l	0
		dc.l	0
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

