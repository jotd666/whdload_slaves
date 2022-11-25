;*---------------------------------------------------------------------------
;  :Program.	GobliiinsHD.asm
;  :Contents.	Slave for "Gobliiins"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: GobliiinsHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	INCLUDE	lvo/intuition.i
	INCLUDE	lvo/graphics.i

	IFD BARFLY
	OUTPUT	"Gobliiins.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================


;CHIP_ONLY

	IFD	CHIP_ONLY
CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $0000
HRTMON
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
BLACKSCREEN
	ENDC


NUMDRIVES	= 1
WPDRIVES	= %0000
;DISKSONBOOT
;DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
STACKSIZE = 15000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

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
	ENDM

slv_name	dc.b	"Gobliiins"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
	dc.b	0

slv_copy	dc.b	"1990 Coktel Vision",0
slv_info	dc.b	"Install & fix by JOTD",10,10
		dc.b	"Set CUSTOM2=1 to force language selection",10
		dc.b	"Set CUSTOM2=2 to force english language",10,10
		dc.b	"Thanks to Wepl, Adrian",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
	dc.b    "C2:L:1 lang select - 2 force english:None,1,2;"
	dc.b	0
_program:
	dc.b	"loader",0


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

	EVEN

_bootdos
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
		bsr	set_arguments
		lea	_program(pc),a0
		lea	patch_main(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

PATCH_XXXLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
	lea	old_\1(pc),a0
	move.l	2(A1),(A0)
	move.w	#$4EF9,(A1)+	
	pea	new_\1(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
old_\1:
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1

	ENDM

; < d7: seglist (APTR)

patch_main
	; fix sound

	addq.l	#4,d7
	move.l	d7,a0
	move.l	d7,a1
	add.l	#$1A000,a0
	lea	$3000(a0),a1
	move.l	#8,d0
	lea	sound_pattern(pc),a2
	bsr	hex_search
	cmp.l	#0,A0
	beq.b	.skipsnd
	
	move.l	#$4E714EB9,(a0)+
	pea		wait_sound(pc)
	move.l	(A7)+,(A0)+
.skipsnd
	; remove protection
	move.l	d7,a0
	move.l	d7,a1
	lea	$7FF0(a1),a1
	lea	$7FF0(a1),a1
	move.l	#20,d0
	lea	prot_pattern(pc),a2
	bsr	hex_search
	cmp.l	#0,A0
	beq.b	.skipprot

	addq.l	#2,a0
	lea	crack(pc),a1
	move.w	#end_crack-crack,D0
.copy
	move.b	(a1)+,(a0)+
	subq.l	#1,d0
	bne.b	.copy
.skipprot
	; quit

	addq.l	#4,d7
	move.l	d7,a0
	move.l	d7,a1
	lea	$700(a1),a1
	move.l	#4,d0
	lea	quit_pattern(pc),a2
	bsr	hex_search
	cmp.l	#0,A0
	beq.b	.skipquit

	move.l	#$4EF80100,(a0)	; quit
	patch	$100,_quit
.skipquit

	lea	gfxname(pc),a1
	moveq	#0,d0
	move.l	$4.W,a6
	jsr	_LVOOpenLibrary(a6)

	move.l	d0,a6	
	PATCH_XXXLIB_OFFSET	RectFill


	lea	intname(pc),a1
	moveq	#0,d0
	move.l	$4.W,a6
	jsr	_LVOOpenLibrary(a6)

	move.l	d0,a6	
	PATCH_XXXLIB_OFFSET	OpenScreen
;;	PATCH_XXXLIB_OFFSET	GetPrefs

	bsr	_flushcache
	rts

quit_pattern
	dc.l	$504F60FE

prot_pattern:
	dc.l	$fffe426d,$fffe302d,$fffec1fc,$0012206c,$92ec3230 

sound_pattern:
	dc.l	$33FC8001,$00DFF096
	
wait_sound:
	move.w	#$8001,$DFF096	; stolen
	movem.l	D0,-(A7)
	moveq.l	#7,D0
	bsr	beamdelay
	movem.l	(A7)+,D0	
	rts

; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts
	
new_OpenScreen
	clr.w	2(a0)	; top edge is 0 instead of $32
	move.l	old_OpenScreen(pc),-(a7)
	rts
	
new_RectFill
	cmp.w	#200,d3
	bcs.b	.d3_ok

	moveq	#0,d3
.d3_ok
	cmp.w	#320,d2
	bcs.b	.d2_ok
	
	; fix wrong access mode -> fastmem MSW read: 79xx: crash

	moveq	#0,d2	; like when code is run from chipmem only

.d2_ok
	move.l	old_RectFill(pc),-(a7)
	rts

; > A1 arg ptr
; > D0 arg len

set_arguments:	
	lea	arg_lang_sel(pc),A0
	move.l	_custom2(pc),D1
	cmp.b	#1,D1
	beq.b	.out			; custom2=1: ask for language
	lea	arg_presel(pc),A0
	lea	arg_lang(pc),A1

	cmp.b	#2,D1
	beq.b	.out			; custom2=2: force english

	move.l	_language(pc),D1
	cmp.b	#3,D1
	beq.b	.german
	cmp.b	#4,D1
	beq.b	.french
	cmp.b	#5,D1
	beq.b	.spanish
	cmp.b	#6,D1
	beq.b	.italian
	bra.b	.out		; not found: english
.spanish:
	move.w	#'SP',(A1)
	bra.b	.out
.italian:
	move.w	#'IT',(A1)
	bra.b	.out
.french:
	move.w	#'FR',(A1)
	bra.b	.out
.german
	move.w	#'DE',(A1)
	bra		.out
.out
	move.l	a0,a1
.strlen
	tst.b	(a0)+
	bne.b	.strlen
	move.l	a0,d0
	sub.l	a1,d0
	subq	#1,d0
	rts

arg_lang_sel:
	dc.b	"HD EXTERN",10,0

arg_presel:
	dc.b	"HD EXTERN LG_"
arg_lang:
	dc.b	"GB",10,0


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_LANG_GET
_language	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	0

crack:
	dc.l	$42577212,$206C92EC,$2F087078,$91C07007
	dc.l	$42A051C8,$FFFC205F,$3017C1C1,$30300800
	dc.l	$B06F000A,$660C3017,$C1C1D1C0,$317CFFFF
	dc.l	$00025257,$0C5700FA

;;	incbin	"crack.bin"
end_crack:

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

gfxname
	dc.b	"graphics.library",0
intname
	dc.b	"intuition.library",0
	even

;============================================================================
