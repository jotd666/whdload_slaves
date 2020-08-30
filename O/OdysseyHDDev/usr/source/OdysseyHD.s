;*---------------------------------------------------------------------------
;  :Program.	OdysseyHD.asm
;  :Contents.	Slave for "Odyssey"
;  :Author.	Bored Seal & JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	
;  :History.	OSEmu
;               converted to kickemu, faster, fixes issue 0003297 (quitkey on 68k)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9, VASM
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i
	INCLUDE	lvo/intuition.i

	IFD BARFLY
	OUTPUT	"Odyssey.slave"
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
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0
HRTMON
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
BLACKSCREEN
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000


;DISKSONBOOT
DOSASSIGN

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


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


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


_assign_df0
	dc.b	"DF0",0
_assign_d1
	dc.b	"Odyssey1",0
_assign_d2
	dc.b	"Odyssey2",0

slv_name		dc.b	"Odyssey"
		IFD	DEBUG
		dc.b	" (DEBUG MODE)"
		ENDC
		dc.b   0
slv_copy		dc.b	"1995 Audiogenic",0
slv_info		dc.b	"installed & fixed by Bored Seal & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config
        dc.b    "C1:X:infinite lives:0;"
        dc.b    "C2:X:infinite energy:0;"
		dc.b	0

_program:
	dc.b	"odyssey",0
_outtro		dc.b	"cjm1004",0

_args		dc.b	10
_args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	(_resload,pc),a2		;A2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	lea	nme_filename(pc),a0
	jsr	(resload_GetFileSize,a2)
	tst.l	d0
	bne.b	.ok
	pea	missing_file_msg(pc)
	pea	TDREASON_FAILMSG
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
.ok
	; we don't care about the result: just make sure that the game crashes if the file
	; hasn't been renamed during the installation
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign_df0(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_d1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_d2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_game(pc),a5
		bsr	_load_exe
	;load outtro
		lea	_outtro(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		sub.l   a5,a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)

patch_game
	bsr	get_version
	lsr.l	#2,d7	; to BCPL again
	move.l	d7,a1
	jsr	resload_PatchSeg(a2)
	;illegal

	rts

VERSION_PL:MACRO
.\1
	lea	_patchlist_\1(pc),a0
	bra.b	.out
	ENDM

get_version:
	movem.l	d0-d1/a1,-(a7)
	lea	_program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#91652,D0
	beq.b	.v1		; originally fixed version (Bored Seal)

	cmp.l	#91556,d0
	beq.b	.v2		; new version linked to mantis issue

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

	VERSION_PL	v1
	VERSION_PL	v2


.out
	movem.l	(a7)+,d0-d1/a1
	rts
	
	IFEQ	1
SET_PALETTE_COLOR:MACRO
	move	#\2,\1*6(a5)
	move	#\3,\1*6+2(a5)
	move	#\4,\1*6+4(a5)
	ENDM

change_game_palette
	LEA	-30720(A4),A5		;2322: 4BEC8800
	move.l	_custom3(pc),d0
	beq.b	.skip
	SET_PALETTE_COLOR	1,13,0,0
	SET_PALETTE_COLOR	2,9,7,15
	SET_PALETTE_COLOR	3,14,13,15
.skip
	addq.l	#8,(A7)
	rts
	ENDC
	
_patchlist_v1	PL_START
		PL_P	$13030,Copylock
		PL_R	$13908			;OS fault routine
		PL_W	$4e,$6008		;snoop mode fixes
		PL_W	$130,$6006
		PL_R	$4de			;savegame patch
		PL_IFC1
		PL_W	$5e2,$6008		;lives
		PL_ENDIF
		PL_IFC2
		PL_W	$8490,$600a		;energy
		PL_ENDIF
		PL_W	$c224,$6018		;dos.open()
		PL_PS	$c246,SaveGame
;		PL_W	$c2d8,$6034		;disk message
		PL_PS	$c358,TestFile
		PL_W	$c35e,$6002		;remove dos.open()
		PL_W	$c366,$6002		;remove dos.close()
		PL_W	$c24c,$6038	    ;remove dos.write()
		PL_AW	$da68,$200	;fix bplcon0 access
		PL_B	$f67d,$5f	;fix MS Windows incompatible name "data/Players/3nme_sprite.bin"
		PL_END
		
_patchlist_v2	PL_START
		PL_P	$12fe8,Copylock
		PL_R	$138c0	;OS fault routine
		PL_W	$4e,$6008	;snoop mode fixes
		PL_W	$130,$6006
		PL_R	$4de	;savegame patch
		PL_IFC1
		PL_W	$5e2,$6008		;lives
		PL_ENDIF
		PL_IFC2
		PL_W	$8450,$600a		;energy	
		PL_ENDIF
		PL_W	$c1dc,$6018		;dos.open()
		PL_PS	$c1fe,SaveGame
;		PL_W	$c2d8,$6034		;disk message
		PL_PS	$c310,TestFile
		PL_W	$c316,$6002		;remove dos.open()
		PL_W	$c322,$6002		;remove dos.close()
		PL_W	$0c1fe+6,$6038	;remove dos.write()
		PL_AW	$da20,$200	;fix bplcon0 access
		PL_B	$f635,$5f	;fix MS Windows incompatible name "data/Players/3nme_sprite.bin"
		PL_END


SaveGame	movem.l	d0-d7/a0-a2,-(sp)
		move.l	d1,a0			;name
		lea	4(a0),a0		;skip df0:
		move.l	d2,a1			;buffer
		move.l	d3,d0
		move.l	(_resload,pc),a2
		jsr	(resload_SaveFile,a2)
		movem.l	(sp)+,d0-d7/a0-a2
		clr.b	$bfec01
		rts
TestFile	movem.l	a0-a2,-(sp)
		move.l	d1,a0
		lea	4(a0),a0
		move.l	(_resload,pc),a2
        jsr     (resload_GetFileSize,a2)
		movem.l	(sp)+,a0-a2
		rts

Copylock	move.l	#$4335eae8,d0		;rnc
		move.l	d0,(a3)
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
	;;bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3

	move.l	a4,a0

	movem.l	d7/a6,-(a7)

	move.l	d2,d0			; argument string length
	move.l	_stacksize(pc),-(a7)	; original stack format
	movem.l	(_saveregs,pc),d1-d7/a1-a2/a4-a6	; original registers (BCPL stuff)
	jsr	(4,a3)		; call program
	addq.l	#4,a7

	movem.l	(a7)+,d7/a6

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

_saveregs
		blk.l	16,0
_stacksize
		dc.l	0

_tag
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	0
missing_file_msg:
		dc.b	"wrong installation, missing file "
nme_filename:
	dc.b	"Players/3nme_Sprite.Bin",0

;============================================================================

	END
