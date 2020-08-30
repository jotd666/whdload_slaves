;*---------------------------------------------------------------------------
;  :Program.	ManiacMansionHD.asm
;  :Contents.	Slave for "ManiacMansion"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: ManiacMansionHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"ManiacMansion.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC
	
;CHIP_ONLY
;============================================================================
	IFD	CHIP_ONLY
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0
HRTMON
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $50000
BLACKSCREEN
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000
POINTERTICKS = 1

;DISKSONBOOT
;DOSASSIGN

;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s


;KICKSIZE	= $80000			;40.068

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.6"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

slv_name		dc.b	"Maniac Mansion"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG MODE)"
	ENDC
				dc.b	0
slv_copy		dc.b	"1989 Lucasfilm",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"maniac",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
	
	move.l	a6,a0
	add.w	#_LVODeleteFile,a0
	move.w	#$4EF9,(a0)+
	lea	_deletefile(pc),a1
	move.l	a1,(a0)

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_exe(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist

_patch_exe:
	movem.l	A2,-(A7)
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	move.l	A1,A3

	move.l	A3,A0
	move.l	A0,A1
	add.l	#$C000,A1
	lea	.crack(pc),A2
	moveq.l	#12,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipcop
	move.l	#$4EB80300,2(A0)
	patch	$300.W,_crackit
.skipcop
	move.l	A3,A0
	move.l	A0,A1
	add.l	#$2000,A1
	lea	.af(pc),A2
	move.l	#12,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipquit
	move.w	#$4EB9,(a0)+
	pea	_patch_af(pc)
	move.l	(a7)+,(a0)+
.skipquit
	bsr	_flushcache
	move.l	(A7)+,A2
	rts

.crack:
	dc.l	$70001030,$18003800,$4A446616
.af:
	dc.l	$4212422A,$0028422A,$0050422A
_patch_af:
	btst	#31,d4
	bne	_quit
	clr.b	(a2)
	clr.b	($28,a2)
	clr.b	($50,a2)
	rts

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

_crackit:
	movem.l	D2,-(A7)

	moveq.l	#0,D2
	movem.l	D0/A0,-(A7)
	bsr	get_long
; add a new version? just enable this
; go up try to enter code, press FIRE when
; clicking on a code and observe the contents of A0
;	btst	#7,$bfe001
;	bne.b	.sk
;	ILLEGAL
;.sk	
	; for english version
	CMPI.L	#'Acce',D0
	BNE.S	.v2
	addq.l	#4,A0
	bsr	get_long
	CMPI.L	#'ss k',D0
	BEQ.S	.crackit
	bra	.skipcrack
.v2
	moveq.l	#1,D2
	; for german version
	bsr	get_long
	CMPI.L	#'Der ',(A0)
	BNE.S	.v3
	addq.l	#4,A0
	bsr	get_long
	CMPI.L	#'Schl',D0
	BEQ.S	.crackit

	; french version
.v3
	moveq.l	#2,D2
	bsr	get_long
	CMPI.L	#$436F6465,D0
	BNE.S	.v4
	addq.l	#4,A0
	CMPI.L	#$3A207365,D0
	BEQ.S	.crackit
	; spanish version
.v4
	moveq.l	#3,D2
	addq.l	#4,A0
	bsr	get_long
	CMPI.L	#'go d',D0
	BEQ.S	.crackit
	BRA.S	.skipcrack

.crackit
	movem.l	(A7)+,D0/A0
	; time to crack it

	move.l	A0,-(A7)
	MOVEA.L	8(A7),A0	; return address
	MOVEA.L	164(A0),A0		;00042: 206800A4
	CLR.L	126(A0)			;00046: 42A8007E
	CLR.L	130(A0)			;0004A: 42A80082
	MOVE.L	(A7)+,A0		;0004E: 20780360
	MOVEM.L	D0/A1,-(A7)		;00052: 48E78040

	LEA	.cracktext_es(PC),A1	;00056: 43FA0042
	cmp.w	#3,D2
	beq.b	.out
	LEA	.cracktext_fr(PC),A1	;00056: 43FA0042
	cmp.w	#2,D2
	beq.b	.out
	LEA	.cracktext_de(PC),A1	;00056: 43FA0042
	cmp.w	#1,D2
	beq.b	.out
	LEA	.cracktext_uk(PC),A1	;00056: 43FA0042
	
.out
	MOVEQ	#48,D0			;0005A: 7030
.LAB_0003:
	MOVE.B	(A1)+,(A0)+		;0005C: 10D9
	DBF	D0,.LAB_0003		;0005E: 51C8FFFC

	MOVEM.L	(A7)+,D0/A1		;00062: 4CDF0201
	MOVE.B	#$43,D0			;00066: 103C0043
	bra.b	.exit

.skipcrack:
	movem.l	(A7)+,D0/A0		; restore work registers
	MOVE.B	0(A0,D1.L),D0		; original code
.exit
	movem.l	(A7)+,D2
	RTS				;

.cracktext_es:
; thanks google translate for that one, my spanish isn't so good nowadays
	dc.b	"Clic 4 veces en la caja superior izquierda    "
	dc.l	0,0
.cracktext_uk:
	dc.b	"Click four times on the upper left case       "
	dc.l	0,0
.cracktext_de:
	dc.b	"Klicke viermal auf das Zeichen oben links     "
	dc.l	0,0
.cracktext_fr:
	dc.b	"Cliquez 4 fois sur la case haut gauche        "
	dc.l	0,0
	even
	
_deletefile:
	moveq.l	#-1,D0		; always OK, but don't perform the delete
	rts


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
	jsr	(a5)
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
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
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

;============================================================================


;============================================================================

	END
