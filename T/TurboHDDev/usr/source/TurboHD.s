;*---------------------------------------------------------------------------
;  :Program.	TurboHD.asm
;  :Contents.	Slave for "Turbo"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: TurboHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"Turbo.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;DEBUG
	IFD	DEBUG
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE = $80000
FASTMEMSIZE = $40000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

DISKSONBOOT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
CBDOSLOADSEG

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s

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

slv_name		dc.b	"Turbo",0
slv_copy		dc.b	"1989 Microillusions",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Thanks to Chris Vella for disk images",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	0
slv_config:
		dc.b    "C1:B:Infinite time;"			
		dc.b	0

	dc.b	"$","VER: slave "
	DECL_VERSION

	EVEN

;============================================================================


; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	

	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0

	cmp.b	#4,(a0)
	bne.b	.skip
	; disable "echo" command
	move.l	d1,a0
	move.l	#$70004E75,4(a0)
.skip
	cmp.b	#5,(a0)
	bne.b	.nomain
	cmp.b	#'T',1(a0)
	bne.b	.nomain

	move.l	d1,a1
	addq.l	#4,a1	; code segment
	move.l	_resload(pc),a2
	lea	pl_main(pc),a0
	jsr	resload_Patch(a2)

.nomain

	rts


; replaces the following offset computation:
;
;	MOVE.L	-52(A5),D0		;0B1C4: 202DFFCC
;	ASL.L	#8,D0			;0B1C8: E180
;	ADD.L	-48(A5),D0		;0B1CA: D0ADFFD0
;
; in C: i*256 + j (i:-52(A5), j:-48(a5))
;
; which is then added to the address of a table
;
; at first call values are random addresses, seems not to bother
; the game if only 24-bit addresses are there, but with 32-bit fastmem
; it generates a huge offset and access fault

fix_offset_calc

	MOVE.L	-52(A5),D0		;0B1C4: 202DFFCC
	and.l	#$FF000000,d0
	beq.b	.ok

	; something fishy: values have not been initialized
	; just put 0

	;;clr.l	-52(a5)
	;;clr.l	-48(a5)
	moveq	#0,d0
	bra.b	.out
.ok
	MOVE.L	-52(A5),D0		; reload the value
	ASL.L	#8,D0			;0B1C8: E180
	ADD.L	-48(A5),D0		;0B1CA: D0ADFFD0
.out
	rts

; damn I'm sooo glad I've written this m68kchecker.py script moons ago.
; Look at those nice "for (i=0;i<10000;i++);" loops... that have no effect during game, argh...

;VIOLATION:turbo.asm:19175:probable CPU-dependent/infinite loop for label 'LAB_06BE'
;LAB_06BE:
;        ADDQ.W  #1,-4(A5)               ;0ddb4: 526dfffc
;LAB_06BF:
;        CMPI.W  #$1388,-4(A5)           ;0ddb8: 0c6d1388fffc
;        BLT.S   LAB_06BE                ;0ddbe: 6df4
;VIOLATION:turbo.asm:19249:probable CPU-dependent/infinite loop for label 'LAB_06C3'
;LAB_06C3:
;        ADDQ.W  #1,-2(A5)               ;0de86: 526dfffe
;LAB_06C4:
;        CMPI.W  #$2710,-2(A5)           ;0de8a: 0c6d2710fffe
;        BLT.S   LAB_06C3                ;0de90: 6df4
;VIOLATION:turbo.asm:19344:probable CPU-dependent/infinite loop for label 'LAB_06C6'
;LAB_06C6:
;        ADDQ.W  #1,-2(A5)               ;0dfa8: 526dfffe
;LAB_06C7:
;        CMPI.W  #$2710,-2(A5)           ;0dfac: 0c6d2710fffe
;        BLT.S   LAB_06C6                ;0dfb2: 6df4
		
		
pl_main
	PL_START
	PL_PSS	$b1c4,fix_offset_calc,4
	PL_PSS	$b1f2,fix_offset_calc,4
;	PL_PSS	$ddb4,wait_5000,2
;	PL_PSS	$de8a,wait_10000,2
;	PL_PSS	$dfac,wait_10000,2

	PL_IFC1
	PL_NOP	$3D0,4
	PL_ENDIF
	PL_END

RATIO=4

	
	
wait_5000
	move.l  d0,-(a7)
	move.w	#500*RATIO,d0
.loop
	bsr	_beamdelay
	move.l	(a7)+,d0
	rts

wait_10000
	move.l  d0,-(a7)
	move.w	#1000*RATIO,d0
.loop
	bsr	_beamdelay
	move.l	(a7)+,d0
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


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0


;============================================================================

	END
