;*---------------------------------------------------------------------------
;  :Program.	MonkeyIslandHD.asm
;  :Contents.	Slave for "MonkeyIsland"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: MonkeyIslandHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"MonkeyIsland.slave"
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
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

POINTERTICKS=1
BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 25000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE
; vasm NEEDS CBDOSREAD macro
; or it won't take the hook into account
CBDOSREAD


; crk: $63514

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
	dc.b	"3.7"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

slv_name		dc.b	"The Secret Of Monkey Island"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
	dc.b	0
slv_copy		dc.b	"1990 LucasFilm Games",0
slv_info		dc.b	"Install & fix by JOTD",10,10
		dc.b	"Thanks to Olivier Schott for testing",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"Monkey_Island",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

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
	move.l	_resload(pc),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	PATCH_DOSLIB_OFFSET	Open
		
	;remove dos.Delete function so there are less os swaps

;		move.l	a6,a0
;		add.w	#_LVODeleteFile+2,a0
;		lea	_deletefile(pc),a1
;		move.l	a1,(a0)

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found


	;patch here
		bsr	_patchit

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

		pea	TDREASON_OK
		bra.b	_abort

_end
		jsr	(_LVOIoErr,a6)
		pea	_program(pc)
		move.l	d0,-(a7)
		pea	TDREASON_DOSREAD
_abort:
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

; < d1 - file pos
; < a0 - name
; < a1 - buffer

_cb_dosRead
	movem.l	d0/a0-a3,-(a7)
	cmp.b	#'1',5(a0)	; DISK01.LEC
	beq.b	.disk01
	cmp.b	#'1',11(a0)	; Rooms/DISK01.LEC
	beq.b	.disk01
	bra.b	.skip
.disk01
	cmp.l	#$63847,d1	; SP version
	beq.b	.crack
	cmp.l	#$636F0,d1	; UK version
	beq.b	.crack
	cmp.l	#$58567,d1	; FR version
	beq.b	.crack
	cmp.l	#$63DD0,d1	; GER version
	beq.b	.crack
	cmp.l	#$63CB2,d1	; IT version
	beq.b	.crack
	bra.b	.skip
.crack
	cmp.b	#$84,(a1)
	bne.b	.skip		; check
	move.w	#$ff,d0
	move.l	a1,a0
.copy
	move.b	#$69,(a1)+
	dbf	D0,.copy
	move.b	#$FE,$29(a0)
	move.b	#$C9,$FF(a0)
.skip
	movem.l	(a7)+,d0/a0-a3
	rts


_patchit:
	move.l	d7,A1
    move.l  _resload(pc),a2
    lea pl_main(pc),a0
    jsr (resload_PatchSeg,a2)
    rts
    
	


_avoid_af_1:
	move.l	D1,-(A7)
	move.l	A0,D1
	rol.l	#8,D1
	tst.b	D1
	beq.b	.ok
	cmp.b	_expmem(pc),D1
	bne.b	.avoid		; avoid access fault
.ok
	; stolen code
	move.b	(A0)+,D0
.avoid
	move.l	A0,($5C2A,A4)
	move.l	(A7)+,D1
	rts

_deletefile:
	moveq.l	#-1,D0
	rts

fix_dma_1
    MOVE.W	82(A5),_custom+dmacon

dmadelay
	movem.l	D0,-(A7)
	; dma enable should be followed by a wait
	; now that the code runs from fastmem/on fast amigas
	; some sfx could be wrongly played
	moveq.l	#4,d0
	bsr	beamdelay
	movem.l	(a7)+,D0
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
    
; all versions share the same executable (same as loom) thanks!!!
pl_main
    PL_START
    PL_PS   $04ba8,_avoid_af_1
    ; put back original code so crack (JSR $200.W) is supported
    ; the crack is done here by changing the VM code not the real code
    PL_L    $0a6f6,$322f0000

;	MOVEA.L	D1,A4			;01506: 2841
    ; should probably be clr A4 since A4 is overwritten the line after!
;	CLR.L	(A0)			;01508: 4290
;	MOVEA.L	D0,A4			;0150a: 2840

    PL_W    $01508,$4294	; clr.l (A0) -> clr.l (A4)
    
    PL_PSS   $00aae,fix_dma_1,2
    
    PL_S  $1642,8
    PL_P    $165A,end_level6_interrupt
    PL_END
    
end_level6_interrupt
	MOVEM.L	(A7)+,D0/A6		;0165a: 4cdf4001
	MOVE.W	#$2000,_custom+intreq		;01642: 33fc200000dff09c
	MOVE.W	#$2000,_custom+intreq		;01642: 33fc200000dff09c
	RTE				;0165e: 4e73
    
new_Open:
	move.l	D0,-(A7)
	cmp.l	#MODE_NEWFILE,d2
	bne	.end
	; D1: df0:filename of the savegame.
	; First check that it's really a savegame (who knows???)
	move.l	d1,a0
	addq.l	#8,a0	; skip "whdload:" assign
	bsr	get_long
	cmp.l	#"save",d0
	bne	.end
	; it's a savegame. In A0 we have the name. Check if the size is okay
	movem.l	d1/a2/a3,-(a7)
	move.l	a0,a3		; save filename
	move.l	_resload(pc),a2
	jsr	(resload_GetFileSize,a2)
	cmp.l	#30000,d0	
	bcc.b	.big_enough
	; file is smaller than 30kb, means that it will flash on gamesave
	; (because it's a stub or it doesn't exist). Create the file beforehand
	; with trash in it, the contents don't matter as it'll be overwritten
    move.l  #40000,d0                 ;size
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


;============================================================================


;============================================================================

	END
