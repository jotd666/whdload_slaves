;*---------------------------------------------------------------------------
;  :Modul.	kick13.asm
;  :Contents.	kickstart 1.3 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick13.asm 1.2 2001/09/20 19:46:12 wepl Exp wepl $
;  :History.	19.10.99 started
;		20.09.01 ready for JOTD ;)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCDIR	osemu:
	INCLUDE	lvo/dos.i
	INCLUDE	lvo/exec.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

;DEBUG

	IFD BARFLY
	OUTPUT	"AnotherWorld.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

	IFND	DEBUG
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
BLACKSCREEN
	ELSE
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
HRTMON
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %1111

;DISKSONBOOT
BOOTDOS
CACHE
HDINIT
;MEMFREE	= $100
;NEEDFPU
;SETPATCH

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s

;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

slv_name		dc.b	"Another World",0
slv_copy		dc.b	"1991 Delphine Software",0
slv_info		dc.b	"adapted & fixed by Harry/JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
_args:
	dc.b	10
_args_end:
	dc.b	0
_program:
	dc.b	"another",0

	EVEN

;============================================================================

	;initialize kickstart and environment


_bootdos	move.l	(_resload),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.end

	;patch

	bsr	_patchexe
	bsr	_flushcache

	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1

		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check

		movem.l	d0/d7/a2/a6,-(a7)

		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

.end		
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_patchexe:
	movem.l	D0-A6,-(A7)
	add.l	d7,d7
	add.l	d7,d7
	move.l	D7,A1
	LEA.L	$7F00(A1),A0

.2	MOVE.W	(A1),D0
	AND.W	#$F1FF,D0
	CMP.W	#$3039,D0
	BNE.S	.1
	MOVE.L	6(A1),D0
	AND.L	#$FFF8FFFF,D0
	CMP.L	#$51C8FFFE,D0
	BNE.S	.1

	MOVE.L	2(A1),6(A1)
	move.w	#$4EB9,(A1)
	pea	TIME(pc)
	move.l	(A7)+,2(A1)

.1	ADDQ.W	#2,A1
	CMP.L	A0,A1
	BLO.S	.2


	; jotd

	move.l	D7,A0
	LEA.L	$7F00(A0),A1
	lea	.code_entered(pc),a2
	moveq	#6,d0
	bsr	_hexsearch
	cmp.l	#0,a0
	beq.b	.sk
	
	move.w	#$4EB9,(a0)+
	pea	enter_code_test(pc)
	move.l	(a7)+,(a0)
.sk

	movem.l	(a7)+,D0-A6

	rts

.code_entered
	dc.l	$B83C0033
	dc.w	$6700

enter_code_test
	movem.l	d0/a0,-(a7)
	move.l	8(a7),a0	; return address
	moveq	#0,d0
	move.w	(a0),d0		; offset of the BEQ

	cmp.b	#$33,d4		; 'C' key
	beq.b	.enter_code
	btst	#6,$bfe001	; left mouse
	beq.b	.enter_code
	btst	#14,$dff016	; second button / blue CD32 button
	bne.b	.nothing
	move.w	#$cc01,$dff034
	bra.b	.enter_code

	bra.b	.nothing
.enter_code
	ext.l	d0
	add.l	d0,8(a7)	; perform BEQ	
	bra.b	.out
.nothing	
	addq.l	#2,8(a7)	; skip rest of BEQ
.out
	movem.l	(a7)+,d0/a0
	rts

TIME	MOVEM.L	D1/A0,-(A7)
	MOVEQ.L	#0,D1
	MOVE.L	8(A7),A0
	MOVE.L	(A0),A0
	MOVE.W	(A0),D1
	BSR.S	PATCHTIME
	MOVEM.L	(A7)+,D1/A0
	ADDQ.L	#4,(A7)
	RTS



PATCHTIME
	DIVU	#$28,D1
.4	MOVE.L	D1,-(A7)
	MOVE.B	$DFF006,D1
.3	CMP.B	$DFF006,D1
	BEQ.S	.3
	MOVE.L	(A7)+,D1
	DBF	D1,.4
	RTS


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

; < d1 - file pos
; < a0 - name
; < a1 - buffer

_cb_dosRead
	cmp.b	#'1',5(a0)
	bne.b	.out
	cmp.b	#'0',4(a0)
	bne.b	.out

;	cmp.l	#$1A000,d1
;	bcs.b	.out
;	cmp.l	#$1C000,d1
;	bcc.b	.out

	cmp.l	#$1B5EE,d1	; protection load
	beq.b	.prot

	bra.b	.out
.prot
	move.l	a2,-(a7)

.v3
	; version 3 (supported with patched file on disk,
        ; but not at the same offset)
	; 114621: 0A 80 29 1E 09 EA 0A 80 29
	lea	$9cf(a1),a2
	cmp.b	#$a,(a2)
	bne.b	.v2
	move.b	#$07,(a2)+
	move.b	#$0a,(a2)+
	move.b	#$3b,(a2)

	; 114761 ($1C049): 0A 01 1B 15 0A

	lea	$a5b(a1),a2
	move.b	#$07,(a2)+
	move.b	#$0a,(a2)+
	move.b	#$71,(a2)
	bra	.skip

.v2
	; version 2 (UK)

	lea	$9fc(a1),a2
	cmp.b	#$a,(a2)
	bne.b	.v1
	; 0A 80 29 1E 0A 17 07 0A

	move.b	#$07,(a2)+
	move.b	#$0A,(a2)+
	move.b	#$68,(a2)

	lea	$a88(a1),a2
	move.b	#$07,(a2)+
	move.b	#$0A,(a2)+
	move.b	#$9E,(a2)

	bra.b	.skip

.v1
	; version 1 (french)
	; 114493 ($1BF3D) 0A 80 29 1E 09 6A 0A 80 29
	lea	$94f(a1),a2
	cmp.b	#$a,(a2)
	bne.b	.skip

	move.b	#$07,(a2)+
	move.b	#$09,(a2)+
	move.b	#$bb,(a2)
	; 0A 01 1B 15 0A 28 14 32
	lea	$9db(a1),a2
	move.b	#$07,(a2)+
	move.b	#$09,(a2)+
	move.b	#$f1,(a2)

	bra.b	.skip

.skip
	; cracked versions or unsupported originals
	; land here, nothing is patched, so the
	; protection is left intact

	move.l	(a7)+,a2
.out

	rts

;============================================================================

	END

