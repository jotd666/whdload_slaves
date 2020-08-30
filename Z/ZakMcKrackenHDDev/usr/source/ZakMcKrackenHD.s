;*---------------------------------------------------------------------------
;  :Program.	ZakMcKrackenHD.asm
;  :Contents.	Slave for "ZakMcKracken"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: ZakMcKrackenHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"ZakMcKracken.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;USE_CHIPMEM

	IFD	USE_CHIPMEM
HRTMON
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000
POINTERTICKS = 1

;DISKSONBOOT
;INITAGA
HDINIT
;IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_config:
	dc.b    "C1:X:Cheat on drawing section:0;"		
	dc.b    "C2:X:Keep protection enabled:0;"		
	dc.b	0

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

slv_name		dc.b	"Zak Mc Kracken"
	IFD		USE_CHIPMEM
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
	dc.b	"zak",0
_args		dc.b	10
_args_end
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
	move.l	a6,a0
	
	add.w	#_LVODeleteFile,a0
	lea	_deletefile(pc),a1
	move.w	#$4EF9,(a0)+
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
	move.l	a1,a3

	move.l	_keep_password(pc),-(a7)
	tst.l	(a7)+
	bne.b	.skipprot

	move.l	a3,a0
	move.l	a3,a1
	add.l	#$10000,A1
	lea	.protection(pc),A2
	move.l	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipprot
	
	move.l	#$4EB80300,(A0)
	patch	$300,_crackit
.skipprot

	move.l	A3,A0
	move.l	A0,A1
	add.l	#$2000,A1
	lea	.af(pc),A2
	move.l	#12,D0
	bsr	_hexsearch
	IFEQ	1
	cmp.l	#0,A0
	beq.b	.skipquit
	move.w	#$4EB9,(a0)+
	pea	_patch_af(pc)
	move.l	(a7)+,(a0)+
	ENDC
.skipquit
	bsr	_flushcache
	move.l	(A7)+,A2
	rts

.protection:
	dc.l	$32310800,$8350602C

.af:
	dc.l	$4212422A,$0028422A,$0050422A
_patch_af:
	btst	#31,d4
	bne	_quit
	clr.b	(a2)
	clr.b	($28,a2)
	clr.b	($50,a2)
	rts

_crackit:
	move.w	(0,A1,D0.L),D1	; original code
	

	cmp.w	#$800,D1
	bne.b	.skip

	move.l	_keep_password(pc),-(a7)
	tst.l	(a7)+
	bne.b	.skip

	; if CUSTOM1 is set, then behave like previous versions
	; (every drawing is correct)

	move.l	_cheat_drawing(pc),-(a7)
	tst.l	(a7)+
	bne.b	.doit

	; added because it solves the drawing puzzles (d4 = 7)
	; along with removing the protection

	cmp.b	#7,d4
	beq.b	.skip
.doit
	moveq	#0,D1
.skip
	rts


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


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_cheat_drawing	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_keep_password	dc.l	0
		dc.l	0

	END
