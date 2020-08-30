;*---------------------------------------------------------------------------
;  :Program.	LeisureSuitLarry5HD.asm
;  :Contents.	Slave for "LeisureSuitLarry5"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: SpaceQuest5HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"LeisureSuitLarry5.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $100000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
;DOSASSIGN
;DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 25000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 8000
CBDOSLOADSEG
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s


;============================================================================

DECL_VERSION:MACRO
	dc.b	"1.5"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
slv_name	dc.b	"Leisure Suit Larry 5",0
slv_copy	dc.b	"1991 Sierra",0
slv_info	dc.b	"adapted & fixed by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Thanks to BTTR/Christian Sauer for disk images",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

;============================================================================


	;initialize kickstart and environment


; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	

	move.l	d0,a0
	add.l	a0,a0
	add.l	a0,a0
	cmp.b	#4,(a0)
	bne.b	.skip_prog

	; prog

	; section 6

	moveq	#6,d2
	bsr	_get_section
	pea	_copy_savedir(pc)
	move.l	(a7)+,$1548-$BF0(a0)

	; section 4 - increment, crack

	moveq	#4,d2
	bsr	_get_section
	move.l	a0,a3
	lea	$1D50-$7B4(a3),a0
	move.w	#$4EB9,(a0)+
	pea	increment(pc)
	move.l	(a7)+,(a0)
	lea	$1D78-$7B4(a3),a0
	move.w	#$4EB9,(a0)+
	pea	increment(pc)
	move.l	(a7)+,(a0)

	; quit

	move.l	#53,d2
	bsr	_get_section
	
	lea	$57C-$334(a0),a0
	cmp.l	#$48E760E2,(a0)
	bne.b	.noquit
	pea	_quit(pc)
	move.w	#$4EF9,(a0)+
	move.l	(a7)+,(a0)
.noquit

	; avoid access fault

	move.l	#23,d2
	bsr	_get_section
	
	add.l	#$7D0-$294,a0
	move.w	#$4EB9,(a0)+
	pea	check_a0(pc)
	move.l	(a7)+,(a0)

.skip_prog
.outcb
	rts

	IFEQ	1
; < A0: address
; > D0: longword
get_long
	move.l	a0,-(a7)
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	move.l	(a7)+,a0
	rts
	


	ENDC

	; note: I'm not sure this works with 68000/68010: could crash if A3 is odd
	; let's wait for user reports :)
increment:
	MOVE	(A3),D0

	bne		.noinccode	; not 0: skip
	cmp.l	#'rmig',-$E0(a3)
	bne.b	.nodeinccode

	; first check is not enough, we interfere on the rest of the game

	cmp.l	#'hafe',-$AF2(a3)
	bne.b	.noinccode		

	move.l	#$2B672B67,-$AC6(a3)		; all required codes to 1
	move.w	#$2B67,-$AC2(a3)
	move.l	#'1111',-$1C(a3)	; code entered to '11111'
	move.b	#'1',-$18(a3)


	move	#4,d0			; set to 4 -> 5: code entered

	bra	.noinccode

.nodeinccode

	; try UK version crack

	cmp.l	#'btnC',-$E0(a3)
	bne.b	.noinccode		

	; first check is not enough, we interfere on the rest of the game
	; and it sounds like there is a little shift somewhere, since my
	; original offsets don't match, so something must have changed,
	; nevermind, I'll consider both cases even if one is maybe not used

	cmp.l	#'tina',-$AF0(a3)
	beq.b	.inccode_uk_1

	cmp.l	#'tina',-$AE6(a3)
	beq.b	.inccode_uk_2

	; false alarm

	bra.b	.noinccode

.inccode_uk_1
	move.l	#$2B672B67,-$AC0(a3)		; all required codes to 1
	move.w	#$2B67,-$ABC(a3)
	bra.b	.uk_end
.inccode_uk_2
	move.l	#$2B672B67,-$AB6(a3)		; all required codes to 1
	move.w	#$2B67,-$AB2(a3)
.uk_end

	move.l	#'1111',-$C8(a3)	; code entered to '11111'
	move.b	#'1',-$C4(a3)

	move	#4,d0			; set to 4 -> 5: code entered

.noinccode

	ADDQ	#1,D0
	MOVE	D0,(A3)
	rts

check_a0:
	cmp.l	#0,a0
	beq.b	.sk
	cmp.w	#$1234,-10(a0)
	rts
.sk
	cmp.l	#1,a0	; wrong test
	rts

; < d1 seglist
; < d2 section #
; > a0 segment
_get_section
	move.l	d1,a0
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a0),a0
	add.l	a0,a0
	add.l	a0,a0
	dbf	d2,.loop
.out
	addq.l	#4,a0
	rts


_wrong_version:
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
; < A0: address
; < D0: longword
set_long
	movem.l	d0,-(a7)
	move.b	d0,3(a0)
	lsr.l	#8,d0
	move.b	d0,2(a0)
	lsr.l	#8,d0
	move.b	d0,1(a0)
	lsr.l	#8,d0
	move.b	d0,(a0)
	movem.l	(a7)+,d0
	rts
	
_copy_savedir
	movem.l	a1,-(a7)
	move.l	(8,A7),a1	; dest
	cmp.l	(12,A7),a1	; source
	beq.b	.skip
	; byte copy instead of long copy that could fail on 68000/010
	move.l	A0,-(a7)
	lea	.savepath(pc),a0
.copy
	move.b	(a0)+,(a1)+
	bne.b	.copy
	movem.l	(a7)+,A0
.skip
	movem.l	(a7)+,a1
	rts

.savepath:
	dc.b	"SYS:save",0
	even


_quit
	PEA	TDREASON_OK
	MOVE.L	_resload(PC),-(A7)
	add.l	#resload_Abort,(a7)
	rts


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
