;*---------------------------------------------------------------------------
;  :Program.	BeneathASteelSkyHD.asm
;  :Contents.	Slave for "BeneathASteelSky"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BeneathASteelSkyHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"BeneathASteelSky.slave"
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
FASTMEMSIZE	= $A0000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
;DOSASSIGN
;DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
STACKSIZE = 8000
BOOTDOS
CACHE
HD_Cyls = 1000

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

;============================================================================

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
	
slv_name	dc.b	"Beneath A Steel Sky",0
slv_copy	dc.b	"1993 Virtual Theatre/Virgin",0
slv_info	dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Thanks to O. Schott, and all the people who",10
		dc.b	"contributed to this release",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"disk_15/steelsky",0
_args		dc.b	10
_args_end
	dc.b	0
; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

	EVEN

_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload


	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase


	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_game(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)



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


patch_game:
	bsr	.getbounds

	lea	.af_load(pc),A2
	moveq.l	#6,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip0

	pea	af_load(pc)
	move.w	#$4EB9,(A0)+
	move.l	(A7)+,(A0)+
.skip0

	bsr	.getbounds

	lea	.reset(pc),A2
	moveq.l	#6,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip

	pea	_quit(pc)
	move.w	#$4EF9,(A0)+
	move.l	(A7)+,(A0)+
.skip

	; access fault (1)

	bsr	.getbounds

	lea	.af(pc),A2
	move.l	#10,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip2

	move.l	#$4EB80100,(A0)
	patch	$100.W,avoid_af
.skip2

	bsr	.getbounds

	lea	.restart(pc),A2
	moveq.l	#6,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip3

	pea	restart_test(pc)
	move.w	#$4EB9,(A0)+
	move.l	(A7)+,(A0)+
.skip3

	; access fault (2), file decryption problem

	bsr	.getbounds

	lea	.af_2(pc),A2
	move.l	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip22

	pea	avoid_crash(pc)
	move.w	#$4EF9,(A0)+
	move.l	(A7)+,(A0)
.skip22
	; access fault (3), at very late stages of the game, menu problem

	bsr	.getbounds

	lea	.af_3(pc),A2
	move.l	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip23

	pea	late_menu_correction(pc)
	addq.l	#6,A0
	move.w	#$4EF9,(A0)+
	move.l	(A7)+,(A0)
.skip23
	bsr	.getbounds	
	lea	.crack1(pc),A2
	move.l	#10,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip4
	move.b	#$FE,2(a0)
.skip4
	bsr	.getbounds	
	lea	.crack2(pc),A2
	move.l	#32,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip5
	move.b	#$50,30(a0)
.skip5
	bsr	.getbounds	
	lea	.crack3(pc),A2
	move.l	#10,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip6
	move.l	#$34C0B040,2(a0)
.skip6
	bsr	.getbounds	
	lea	.readbug(pc),A2
	move.l	#12,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip7
	move.b	#$6B,10(a0)	; BNE -> BMI program error + kickfs bug workaround
.skip7

	rts

.getbounds
	move.l	d7,A0
	add.l	#4,a0
	move.l	A0,a1	
	add.l	#$40000,A1
	rts

.af_load:
	dc.l	$24690030
	dc.w	$4A52

.readbug
	dc.l	$767F4843,$4EAEFFD6,$4A806600

.crack1:
	dc.w	0,$FFFE,0,$18,$18
.crack2:
	dc.l	$51AA,0,0,0,0,0,0,$51DB
.crack3:
	dc.w	$141,$321A,$B240,$6600,$0016

.restart:
	dc.w	$323C,$0003,$4E90

.reset:
	dc.w	$41F8,2,$4E70

.af
	dc.l	$3358000E,$33500010
	dc.w	$0469			; first menu access fault
.af_2:
	dc.l	$2C730000,$DDCB4ED6	; the one which makes LINC crash
.af_3:
	dc.l	$22711000,$E548D3F1	; late menu access fault
	
restart_test:
	cmp.w	#$12,D0
	bne.b	.normal
	bra	_quit

.normal:
	move.w	#3,D1
	jmp	(A0)

af_load:
	movem.l	D0,-(a7)
	MOVE.L	$0030(A1),D0
	swap	d0
	cmp.w	#$0AB5,d0
	bne.b	.ok
	move.l	#$05000000,d0	; access to a stupid address ($500)
				; maybe, but within bounds and filled with zeroes!
.ok
	swap	d0
	move.l	d0,a2
	movem.l	(a7)+,d0
	TST.W	(A2)
	rts

	IFD	XXXXX
_restart:
	move.w	#$7FFF,D0
	move.w	D0,$dff09a
	move.w	D0,$dff096

	pea	.sup(pc)
	move.l	(A7)+,$80.W
	TRAP	#0
.sup
	move	#$2700,SR
	move.l	(_expmem,pc),a0
	jmp	($fe,a0)			;this entry saves some patches
	ENDC

avoid_crash:
	move.l	D1,-(a7)
	move.l	(A3,D0.W),D1
	and.l	#$FFFFFF,D1	; avoids access fault with LINC
	move.l	D1,A6
	add.l	A3,A6
	move.l	(A7)+,D1
	jmp	(A6)

avoid_af:
	movem.l	D0/D1,-(A7)
	move.l	A1,D0
	movem.l	(A7)+,D0/D1
	bpl.b	.ok

	; access fault on $FFFFxxxx address: return with D0=1

	moveq.l	#1,D0
	addq.l	#4,A7
	rts

.ok
	move.w	(A0)+,$E(A1)	; stolen code
	rts

late_menu_correction:
	move.l	(A1,D0.W),D1
	and.l	#$FFFFFF,D1	; removes MSB which causes access fault
	add.l	D1,A1
	move.l	(A7)+,D1
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
