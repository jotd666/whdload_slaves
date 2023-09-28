;*---------------------------------------------------------------------------
;  :Program.	KingsQuest5HD.asm
;  :Contents.	Slave for "KingsQuest5"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: KingsQuest5HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
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
	INCLUDE	dos/dosextens.i

	IFD BARFLY
	OUTPUT	"KingsQuest5.slave"
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
;CHIPMEMSIZE	= $180000
;FASTMEMSIZE	= $00000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 25000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 5000
CACHE
CBDOSLOADSEG
;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s

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
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

slv_name	dc.b	"King's Quest 5",0
slv_copy	dc.b	"1992 Sierra",0
slv_info	dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Enter JOTD at each protection check",10,10
		dc.b	"Thanks to Tony Aksnes/BTTR for disk images",10
		dc.b	"and to Hubert Maier for savegames & testing",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

;============================================================================

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

	move.l	_resload(pc),a2

	; prog

	; section 4: spell protection (differs from UK to DE version)

	move.w	#4,d2
	bsr	.get_section

	movem.l	D0-D1/A0-A2,-(A7)
	move.l	A0,A1
	lea	pl_section4(pc),a0
	cmp.w	#$3013,$FC6(a1)
	beq.b	.go_4
	bra.b	.skip_4		; no protection skip on german version yet
	add.l	#$a,a1
	cmp.w	#$3013,$FC6(a1)
	beq.b	.go_4

	bra	wrong_version

.go_4
	jsr	resload_Patch(a2)
.skip_4
	movem.l	(a7)+,D0-D1/A0-A2
	
	; section 52/53 - quit

	; english

	move.w	#52,d2
	bsr	.get_section
	add.l	#$122E-$FF8,a0
	cmp.l	#$48E760E2,(a0)
	bne.b	.german

	movem.l	D0-D1/A0-A2,-(a7)
	move.w	#59,d2
	bsr	.get_section
	move.l	a0,a1
	sub.l	#$19D8,a1
	lea	pl_af_uk(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,D0-D1/A0-A2

	bra.b	.go_52

	; german
.german
	movem.l	D0-D1/A0-A2,-(a7)
	move.w	#60,d2
	bsr	.get_section
	move.l	a0,a1
	sub.l	#$1ED8,a1
	lea	pl_af_de(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,D0-D1/A0-A2

	move.w	#53,d2
	bsr	.get_section
	add.l	#$568-$320,a0
	cmp.l	#$48E760E2,(a0)
	bne.b	wrong_version

.go_52
	; english

	move.w	#$4EF9,(a0)+
	pea	_quit(pc)
	move.l	(a7)+,(a0)

	; section 23 - access fault #1, same for UK & DE

	move.w	#23,d2
	bsr	.get_section

	add.l	#$670-$134,a0
	move.w	#$4EB9,(a0)+
	pea	check_a0(pc)
	move.l	(a7)+,(a0)

	bra.b	.out

.skip_prog
	moveq	#0,d0
	move.b	(a0),d0
	lea	(a0,d0.w),a3
	cmp.b	#'v',(a3)
	bne.b	.out
	cmp.b	#'r',-1(a3)
	bne.b	.out

	; sound driver patch

	move.l	#$2C762000,d0
	move.l	d1,a0
	add.l	#$4+$1A9E,a0
	cmp.l	(a0),d0
	beq.b	.patchsnd

	bra.b	.nosnd
.patchsnd
	move.l	#$4E714EB9,(a0)+
	pea	patch_sound(pc)
	move.l	(a7)+,(a0)
	bra.b	.out
.nosnd

.out
	rts


; < d1 seglist
; < d2 section #
; > a0 segment
.get_section
	move.l	d1,a0
	subq	#1,d2
.loop
	move.l	(a0),a0
	add.l	a0,a0
	add.l	a0,a0
	dbf	d2,.loop
	addq.l	#4,a0
	rts

pl_af_uk
	PL_START
	PL_PS	$23F4,move_a0_1
	PL_PS	$2412,move_a0_2
	PL_P	$23DA,and_8_a0
	PL_END

pl_af_de
	PL_START
	PL_PS	$29D4,move_a0_1
	PL_PS	$29F2,move_a0_2
	PL_P	$29BA,and_8_a0
	PL_END


and_8_a0:
	movem.l	d0,-(a7)
	move.l	a0,d0
	movem.l	(a7)+,d0
	bmi.b	.skip	; a0=$FFFFFFF6 -> AF
	ANDI	#$FFFE,8(A0)		;22B6A: 0268FFFE0008
.skip
	UNLK	A5			;22B70: 4E5D
	RTS				;22B72: 4E75

move_a0_1:
	; on some memory configs, could trigger an access fault

	cmp.l	#0,a0
	beq.b	.sk

	move.w	(-2,a0),(-6,a5)
	rts
.sk
	clr.w	(-6,a5)
	rts

move_a0_2:
	; access fault if a0 = 0

	cmp.l	#0,a0
	beq.b	.sk

	move.w	(-6,a5),(-2,a0)
.sk
	rts

patch_sound
	movem.l	D0,-(a7)
	MOVE.L	$00(A6,D2.W),D0
	move.l	d0,a6
	and.l	#$F00FFFFE,d0
	movem.l	(a7)+,d0
	beq.b	.skip		; 0xx00001-type address: write access fault
	MOVE.W	#$0000,(A6)
.skip
	RTS

pl_section4
	PL_START
	PL_PS	$FC6,read_a3	; for 4 letter code
	PL_PS	$1ADE,dec_a3	; for infinite code retries
	PL_END

dec_a3
	move.w	#57,d0
	cmp.l	#'andi',14(a3)
	beq.b	.skipdec

	move.w	#79,d0
	cmp.l	#'hant',42(a3)
	beq.b	.skipdec
	
	bra.b	.normal

.skipdec
	bsr	copy_jotd_text

	; don't decrease protection counter

	move.w	(A3),d0
	rts
.normal
	MOVE.w	(A3),D0
	SUB.W	#1,D0
	move.w	D0,(A3)
	rts

read_a3
	bsr	prottest

	MOVE	(A3),D0			;14F7AE: 3013
	ADDQ	#2,A2			;14F7B0: 544A
	MOVE	D0,(A2)			;14F7B2: 3480
	rts

wrong_version:
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

copy_jotd_text
	movem.l	a0-a1,-(a7)
	lea	(a3,d0.w),a1
	lea	.jotdtext(pc),a0
.copy
	tst.b	(a0)
	beq.b	.out
	move.b	(a0)+,(a1)+
	bra.b	.copy
.out
	movem.l	(a7)+,a0-a1
	rts
.jotdtext
;	dc.b	"use Crispin's wand"
	dc.b	"enter JOTD letters",0
	even


FIRSTOFFSET = 14
prottest
	movem.l	d2,-(a7)
	move.l	#'heck',d2
	cmp.l	-FIRSTOFFSET(a3),d2
	bne.b	.sk1
	move.w	#'J'-'A',(A3)
.sk1
	cmp.l	-10-FIRSTOFFSET(a3),d2
	bne.b	.sk2
	move.w	#'O'-'A',(A3)
.sk2
	cmp.l	-20-FIRSTOFFSET(a3),d2
	bne.b	.sk3
	move.w	#'T'-'A',(A3)
.sk3
	cmp.l	-30-FIRSTOFFSET(a3),d2
	bne.b	.sk4
	move.w	#'D'-'A',(A3)
.sk4
	movem.l	(a7)+,d2
	rts

check_a0:
	cmp.l	#0,a0
	beq.b	.sk
	cmp.w	#$1234,-10(a0)
	rts
.sk
	cmp.l	#1,a0	; wrong test
	rts

_wrong_version:
		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

_quit
	pea	TDREASON_OK
	move.l	_resload(pc),a2
	jmp	resload_Abort(A2)


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

	END
