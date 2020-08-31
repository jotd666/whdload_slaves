;*---------------------------------------------------------------------------
;  :Program.	wildwestworld.asm
;  :Contents.	Slave for "Wild West World" from Software 2000
;  :Author.	Wepl
;  :Original	v1 
;  :Version.	$Id: wildwestworld.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	07.08.00 started
;		03.08.01 some steps forward ;)
;		30.01.02 final beta
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"Gunship2000ECS.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $100000
NUMDRIVES	= 1
WPDRIVES	= %1111

BLACKSCREEN
;DEBUG
;DISKSONBOOT
DOSASSIGN
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
BOOTDOS
CBDOSLOADSEG
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s



;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_dsk1
	dc.b	"gs_dsk1",0
_dsk2
	dc.b	"gs_dsk2",0
_dsk3
	dc.b	"gs_dsk3",0
_dsk4
	dc.b	"gs_dsk4",0
_fonts
	dc.b	"FONTS",0

DECL_VERSION:MACRO
	incbin	"slave_version"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM


slv_name		dc.b	"Gunship 2000",0
slv_copy		dc.b	"1993 Microprose",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Set CUSTOM1=1 to skip introduction",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"Gunship 2000",0
_intro:
	dc.b	"Gunship 2000 Intro",0
_args		dc.b	10
_args_end
	dc.b	0


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

	EVEN

;============================================================================

	;initialize kickstart and environment

; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0

	cmp.b	#'g',1(A0)
	bne.b	.nomain
	cmp.b	#'s',2(A0)
	bne.b	.nomain

	bsr	.patch_segments
.nomain:
	rts

.patch_segments:
	move.l	d1,d0
	lea	.protstring(pc),a2
.loop
	move.l	d0,a3
	add.l	a3,a3
	add.l	a3,a3

	; check to remove protection

	lea.l	500(a3),a1
	move.l	a3,a0
	moveq.l	#8,d0
	bsr	_hexsearch
	cmp.l	#0,a0
	beq.b	.next
	move.l	#$4EB800C0,(A0)
	move.l	#$4EB800DE,$48C(A0)
	patch	$C0,_crackit_1
	patch	$DE,_crackit_2
.next
	move.l	(a3),d0
	bne.b	.loop
.out
	bsr	_flushcache
	rts
.protstring:
	dc.l	$43EDFFFA,$12D866FC

_bootdos	move.l	(_resload),a2		;A2 = resload

	; get flags

	move.l	_resload(pc),a2
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_dsk1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_dsk2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_dsk3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_dsk4(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
	;load exe
		move.l	_custom1(pc),d0
		bne.b	.skipintro
		lea	_intro(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		sub.l	a5,a5
		bsr	_load_exe
.skipintro
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



patch_main:
	move.l	d7,A1
	addq.l	#4,A1
	move.l	_resload(pc),a2
	lea	_pl_gs2000(pc),a0
	jsr	resload_Patch(a2)
	rts

_pl_gs2000:
	PL_START
	PL_P	$66C,move1d0rts
	PL_P	$78E,move1d0rts
	PL_END

move1d0rts
	moveq.l	#1,D0
	rts


_crackit_1:
	MOVEM.L	D0-D7/A0-A6,-(A7)	;0AC: 48E7FFFE
	MOVE.L	D5,D1			;0B0: 2205
	LSR	#1,D1			;0B2: E249
	MOVEQ	#0,D2			;0B4: 7400
	MOVE	D1,D2			;0B6: 3401
	MOVEQ	#0,D1			;0B8: 7200
	MOVE	D5,D1			;0BA: 3205
	ADD.L	D2,D1			;0BC: D282
	BSR.S	compute_correct_code		;0BE: 6128
	MOVEM.L	(A7)+,D0-D7/A0-A6	;0C0: 4CDF7FFF
	LEA	-6(A5),A1		;0C4: 43EDFFFA
	RTS				;0C8: 4E75
_crackit_2:
	MOVEM.L	D0-D7/A0-A6,-(A7)	;0CA: 48E7FFFE
	MOVE.L	D7,D1			;0CE: 2207
	LSR	#1,D1			;0D0: E249
	MOVEQ	#0,D2			;0D2: 7400
	MOVE	D1,D2			;0D4: 3401
	MOVEQ	#0,D1			;0D6: 7200
	MOVE	D7,D1			;0D8: 3207
	ADD.L	D2,D1			;0DA: D282
	BSR.S	compute_correct_code		;0DC: 610A
	MOVEM.L	(A7)+,D0-D7/A0-A6	;0DE: 4CDF7FFF
	LEA	-42(A5),A1		;0E2: 43EDFFD6
	RTS				;0E6: 4E75
compute_correct_code:
	DIVU	#$2710,D1		;0E8: 82FC2710
	ADDI.B	#$30,D1			;0EC: 06010030
	MOVE.B	D1,(A0)+		;0F0: 10C1
	SWAP	D1			;0F2: 4841
	EXT.L	D1			;0F4: 48C1
	DIVU	#$03E8,D1		;0F6: 82FC03E8
	ADDI.B	#$30,D1			;0FA: 06010030
	MOVE.B	D1,(A0)+		;0FE: 10C1
	SWAP	D1			;100: 4841
	EXT.L	D1			;102: 48C1
	DIVU	#$0064,D1		;104: 82FC0064
	ADDI.B	#$30,D1			;108: 06010030
	MOVE.B	D1,(A0)+		;10C: 10C1
	SWAP	D1			;10E: 4841
	EXT.L	D1			;110: 48C1
	DIVU	#$000A,D1		;112: 82FC000A
	ADDI.B	#$30,D1			;116: 06010030
	MOVE.B	D1,(A0)+		;11A: 10C1
	SWAP	D1			;11C: 4841
	ADDI.B	#$30,D1			;11E: 06010030
	MOVE.B	D1,(A0)			;122: 1081
	RTS				;124: 4E75


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
	add.l	d7,d7
	add.l	d7,d7
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
	move.l	a3,-(a7)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

_hexsearch:
	movem.l	D1/D3/A1-A2,-(A7)
.addrloop:
	moveq.l	#0,D3
.strloop:
	move.b	(A0,D3.L),D1	; gets byte
	cmp.b	(A2,D3.L),D1	; compares it to the user string
	bne.b	.notok		; nope
	addq.l	#1,D3
	cmp.l	D0,D3
	bcs.b	.strloop

	; pattern was entirely found!

	bra.b	.exit
.notok:
	addq.l	#1,A0	; next byte please
	cmp.l	A0,A1
	bcc.b	.addrloop	; end?
	sub.l	A0,A0
.exit:
	movem.l	(A7)+,D1/D3/A1-A2
	rts


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================


	END
