;*---------------------------------------------------------------------------
;  :Program.	FantasticVoyageCDTVHD.asm
;  :Contents.	Slave for "FantasticVoyageCDTV"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: FantasticVoyageCDTVHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

	IFD BARFLY
	OUTPUT	"FantasticVoyageCDTV.slave"
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
FASTMEMSIZE	= $40000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE
CBDOSLOADSEG

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


_assign
	dc.b	"cd0",0

slv_name		dc.b	"Fantastic Voyage CDTV",0
slv_copy		dc.b	"1992 Centaur Software",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version "
		incbin	slave_version
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"FVLOADER",0
_args		dc.b	10
_args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
		incbin	slave_version
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
		dc.b	$A,$D,0
	ENDC

	EVEN

REPLACE_BLIT:MACRO
	movem.l	d0-d1/a0-a2,-(a7)
	lea	\1_bytes(pc),a2
	moveq.l	#\2,d0
.loop\@
	bsr	hex_search
	cmp.l	#0,a0
	beq.b	.out\@

	move.w	#$4EB9,(a0)+
	pea	\1(pc)
	move.l	(a7)+,(a0)+
	bra.b	.loop\@
.out\@
	movem.l	(a7)+,d0-d1/a0-a2
	ENDM

REPLACE_BLIT_SHORT:MACRO
	movem.l	d0-d1/a0-a2,-(a7)
	lea	\1_bytes(pc),a2
	moveq.l	#\2,d0
.loop\@
	bsr	hex_search
	cmp.l	#0,a0
	beq.b	.out\@

	patch	\3,\1
	move.w	#$4EB8,(a0)+
	move.w	#\3,(a0)+

	bra.b	.loop\@
.out\@
	movem.l	(a7)+,d0-d1/a0-a2
	ENDM

; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	

	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0
	addq	#1,a0

	lea	.cd0fv(pc),a1
.l
	cmp.b	(a1)+,(a0)+
	beq.b	.l
	tst.b	-1(a1)
	bne.b	.skip
.ok
	subq.l	#1,a0
	; cd0:fv something...

	move.l	d1,a1
	addq.l	#4,a1
	move.l	_resload(pc),a2

	cmp.b	#'i',(a0)
	beq.b	.intro
	cmp.b	#'r',(a0)
	beq.b	.room
	cmp.b	#'s',(a0)
	bne.b	.noshrink
	cmp.b	#'n',6(a0)
	beq.b	.shrinknormal
	; shrinkreverse

	bra.b	.skip
.room
	sub.l	#$B830,a1
	lea	pl_room(pc),a0
	jsr	resload_Patch(a2)
	bra.b	.skip
.shrinknormal
	sub.l	#$DF40,a1
	lea	pl_shrinknormal(pc),a0
	jsr	resload_Patch(a2)
	bra.b	.skip
.intro
	sub.l	#$B830,a1
	lea	pl_intro(pc),a0
	jsr	resload_Patch(a2)
	bra.b	.skip
.noshrink
	cmp.b	#'l',(a0)
	bne.b	.skip

	; fvlevelx

	move.l	a1,a0
	add.l	#$30000,a1

	REPLACE_BLIT	blit_5ac2_0000,6
	REPLACE_BLIT	blit_d0_5ac0,6
	REPLACE_BLIT	blit_5ac0_ffff,6
	REPLACE_BLIT	blit_5ac2_ffff,6
	REPLACE_BLIT	blit_5ae0_001e,6
	REPLACE_BLIT	blit7,8
	REPLACE_BLIT_SHORT	blit8,8,$C0
	REPLACE_BLIT	blit9,8
	
	bra.b	.skip
.nol1	
.skip
	rts

.cd0fv
	dc.b	"cd0:fv",0
	even

pl_intro
	PL_START
	PL_PS	$bfbe,blit_5ac2_0000
	PL_END

pl_room
	PL_START
	PL_PS	$bfea,blit_5ac2_0000
	PL_PS	$d22e,blit_d0_5ac0
	PL_PS	$cebe,blit_5ac2_ffff
	PL_PS	$cf18,blit7
	PL_PS	$cf56,blit_5ac2_0000

	PL_END

pl_shrinknormal
	PL_START
	PL_PS	$E11E,fix_int_test
	PL_END

	PL_PS	$0002170a,blit_5ac2_ffff
	PL_PS	$000217ac,blit_5ac2_0000
	PL_PS	$00021a8e,blit_5ac0_ffff
	PL_PS	$00020a44,blit_5ae0_001e
	PL_PS	$00021a02,blit_5ac0_ffff
	PL_PS	$00021762,blit7
	PL_PS	$00021796,blit7

fix_int_test
	movem.l	d0,-(a7)
	move.w	($5a9a,a6),d0
	btst	#5,d0
	movem.l	(a7)+,d0
	rts

blit_5ac2_0000:
	bsr	wt
blit_5ac2_0000_bytes:
	dc.w	$3D7C,$0000,$5AC2	;	move.w	#0,($5AC2,a6)
	rts


blit_d0_5ac0
	bsr	wt
blit_d0_5ac0_bytes:
	move.w	d0,($5ac0,a6)                  ;$00dff044
	moveq	#$4c,d0
	rts

blit_5ac0_ffff
	bsr	wt
blit_5ac0_ffff_bytes
	move.w	#$ffff,($5ac0,a6)              ;$00dff044
	rts

blit3:
	move.w	d1,$5ad4(a6)
	bra		wt

blit_5ac2_ffff
	bsr	wt
blit_5ac2_ffff_bytes
	move.w	#$ffff,($5ac2,a6)              ;$00dff046
	rts
	
blit_5ae0_001e
	bsr	wt
blit_5ae0_001e_bytes
	move.w	#$1e,($5ae0,a6)                ;$00dff064
	rts

blit7
	bsr	wt
blit7_bytes
	move.l	a2,($5acc,a6)                  ;$00dff050
	move.l	a3,($5ad0,a6)
	addq.l	#2,(a7)
	rts


blit8
	bsr	wt
	move.l	a2,($5ac8,a6)                  ;$00dff04c
	rts

blit9
	bsr	wt
	move.l	a2,($5ac4,a6)                  ;$00dff048
	move.l	a2,($5ad0,a6)                  ;$00dff054
	rts

blit8_bytes
	dc.l	$2D4A5AC8
blit9_bytes
	dc.l	$2D4A5AC4
	dc.l	$2D4A5AD0

wt
	TST.B	dmaconr+$DFF000
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	bra.s	.end
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
.end
	rts

_bootdos

	move.l	(_resload),a2		;A2 = resload


	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_loader(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)

patch_loader
	move.l	d7,a1
	addq.l	#4,a1
	lea	pl_loader(pc),a0
	jsr	resload_Patch(a2)
	rts

pl_loader
	PL_START
	PL_I	$138
	PL_END

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

hex_search:
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
