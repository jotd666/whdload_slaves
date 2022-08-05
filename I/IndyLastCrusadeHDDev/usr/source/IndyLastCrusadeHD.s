;*---------------------------------------------------------------------------
;  :Program.	IndyLastCrusadeHD.asm
;  :Contents.	Slave for "IndyLastCrusade"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: IndyLastCrusadeHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"IndyLastCrusade.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;;CHIP_ONLY = 1

;============================================================================

	IFD	CHIP_ONLY
CHIPMEMSIZE	= $110000
FASTMEMSIZE	= $0
HRTMON
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $50000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
;DEBUG	unusable: it crashes because write without ACCESS_WRITE
HDINIT
;HRTMON
CACHE
IOCACHE		= 40000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
POINTERTICKS = 1
BOOTDOS


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	include	whdload/kick13.s

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
	ENDM


slv_name		dc.b	"Indiana Jones and the Last Crusade (adv.)"
	IFD	CHIP_ONLY
	dc.b	" (CHIP ONLY)"
	ENDC
		dc.b	0
slv_copy		dc.b	"1989 Lucasfilm Games",0
slv_info		dc.b	"Installed by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0


	dc.b	"$VER: slave "
	DECL_VERSION
	dc.b	0

slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"indy",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

MAXED_SAVE_SIZE = 15000

PATCH_DOSLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
	moveq	#0,D0
	move.w	4(A1),D0
	addq.l	#4,D0
	add.l	D0,A1

	lea	old_\1(pc),a0
	move.l	A1,(A0)+

	move.l	A6,A1
	add.l	#_LVO\1,A1
	move.b	1(A1),D0
	ext.w	D0
	ext.l	D0
	move.l	D0,(A0)		; moves to d0_value_xxx

	move.w	#$4EF9,(A1)+	
	pea	new_\1_init(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
new_\1_init
	move.l	d0_value_\1(pc),d0
	bra	new_\1
old_\1:
	dc.l	0
d0_value_\1
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1
	ENDM


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
	
	PATCH_DOSLIB_OFFSET	Open

	;load exe
	lea	_program(pc),a0
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)
	move.l	d0,d7			;D7 = segment
	beq	_end			;file not found

	bsr	check_version
	
	;patch here
	bsr	_patch_exe
	bsr	_patch_saves

	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	lea	(_args,pc),a0
	move.l	(4,a7),d0		;stacksize
	sub.l	#5*4,d0			;required for MANX stack check
	movem.l	d0/d7/a2/a6,-(a7)
	moveq	#_args_end-_args,d0
	jsr	(4,a1)
	movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)

	;quit
_quit
	pea	TDREASON_OK
	move.l	(_resload,pc),a2
	jmp	(resload_Abort,a2)

_end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_patch_saves
	; remove delete for savegames

	move.l	a6,a0
	add.w	#_LVODeleteFile,a0
	lea	_deletefile(pc),a1
	move.w	#$4EF9,(a0)+
	move.l	a1,(a0)
	bsr	_flushcache
	rts

_deletefile:
	moveq	#-1,D0
	rts
	
CHECK_VER:MACRO
	cmp.l	#\1,D0
	beq.b	.\2
	ENDM

VERSION_PL:MACRO
.\1
	lea	pl_\1(pc),a0
	bra	.out
	ENDM
	
check_version:
	movem.l	d0-d1/a1,-(a7)
	lea	_program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	CHECK_VER	126352,french	; SPS1986
	CHECK_VER	126332,german	; SPS343 / SPS2323 (italian)
	CHECK_VER	65420,german
	CHECK_VER	126324,english	; SPS1990, probably NTSC as music is slow on PAL
	
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

	VERSION_PL	french
	VERSION_PL	german
	VERSION_PL	english

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.out
	lea	patchlist(pc),a1
	move.l	a0,(a1)
	movem.l	(a7)+,d0-d1/a1
	rts
new_Open:
	move.l	D0,-(A7)
	cmp.l	#MODE_NEWFILE,d2
	bne	.end
	; D1: df0:filename of the savegame.
	; First check that it's really a savegame
	; (who knows???) and there's also "*" and other special
	; filenames we don't want to tamper with
	
	move.l	d1,a0
	bsr	get_long
	cmp.l	#"SAVE",d0		; uppercase
	bne	.end

	; it's a savegame. In A0 we have the name. Check if the size is okay
	movem.l	d1/a2/a3,-(a7)
	move.l	a0,a3		; save filename
	move.l	_resload(pc),a2
	jsr	(resload_GetFileSize,a2)
	cmp.l	#MAXED_SAVE_SIZE,d0	
	bcc.b	.big_enough
	; file is smaller than 30kb, means that it will flash on gamesave
	; (because it's a stub or it doesn't exist). Create the file beforehand
	; with trash in it, the contents don't matter as it'll be overwritten
    move.l  #MAXED_SAVE_SIZE,d0                 ;size
	move.l 	a3,a0           ;name
	sub.l	a1,a1            ;source
	jsr     (resload_SaveFile,a2)	
.big_enough
	movem.l	(a7)+,d1/a2/a3
.end
	move.l	(a7)+,d0
	move.l	old_Open(pc),-(a7)
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
	
_patch_exe:
	movem.l	D0-A6,-(A7)
	move.l	D7,A5
	add.l	A5,A5
	add.l	A5,A5
	ADDQ.L	#4,A5		; A5: first segment (code start segment)

	cmp.l	#$4CDF7FFF,$EC(a5)	; powerpacker v2 file, german version
	                            ; exact same as unpacked CDTV/floppy german
	bne.b	.patch

	move.l	#$10000,$68(a5)		; fix MEMF_CHIP flag in decrunch routine
	move.w	#$4EB9,$EC(a5)		; intercept after decrunch for patch
	pea	_after_decrunch(pc)
	move.l	(a7)+,$EE(a5)
	bra.b	.out
.patch
	bsr	_patch_unpacked
.out
	movem.l	(A7)+,D0-A6
	rts

_patch_unpacked
	move.l	a5,a1
	move.l	_resload(pc),a2
	move.l	patchlist(pc),a0
	
	jsr	(resload_Patch,a2)
.out
	rts

pl_german
	PL_START
	PL_PS	$085e0,_crackit
	PL_PSS	$1432c,_dmadelay,2
	PL_END
pl_french
	PL_START
	PL_PS	$085e4,_crackit
	PL_PSS	$14342,_dmadelay,2
	PL_END
pl_english
	PL_START
	PL_PS	$085e0,_crackit
	PL_PSS	$1432e,_dmadelay,2
	PL_END
	
	
;_protection:
;	dc.l	$31AD00080800, 4E5D

_after_decrunch
	move.l	(a7)+,a2
	move.l	(a2),a5	

	lea	.return_address(pc),a2
	move.l	a5,(a2)

	bsr	_patch_unpacked

	bsr	_flushcache

	MOVEM.L	(A7)+,D0-D7/A0-A6	; original code
	move.l	.return_address(pc),-(a7)
	rts

.return_address
	dc.l	0
_crackit:
	cmp.w	#$D4,D0
	bne.b	.normal
	cmp.w	#$D4,D1
	bne.b	.normal

	bsr	.docrack

.normal
	move.w	(8,A5),(A0,D0.L)	; original program
	rts


.docrack
	movem.l	D0-D1/A0-A1,-(a7)
	lea	_crackinfo(pc),A1

	move.l	#$FF,D0

	; copy some variables ripped at the same point
	; but with a correct symbol combination

.copy
	move.b	(A1)+,(A0)+
	dbf	D0,.copy
	movem.l	(A7)+,D0-D1/A0-A1
	rts

_crackinfo:
	incbin	"crack.bin"
	
_dmadelay
	move.l	D0,-(A7)
	; dma enable should be followed by a wait
	; now that the code runs from fastmem/on fast amigas
	; some sfx could be wrongly played
	moveq.l	#0,d0
	bsr	_beamdelay
	move.l	(a7)+,D0
	rts


; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

patchlist
	dc.l	0
	
;============================================================================
