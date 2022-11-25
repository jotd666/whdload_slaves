;*---------------------------------------------------------------------------
; Program:	Driller.s
; Contents:	Slave for "Driller" (c) 1988 Incentive Software/Domark
; Author:	Codetapper/Action
; History:	23.04.2002 - v1.0
;		           - Supports 3 versions
;		           - Full load from HD
;		           - Loads and saves games to HD
;		           - Copy protection removed (MFM track)
;		           - Empty DBF loops fixed (x2)
;		           - Stack relocated to fast memory
;		           - Intro file can be compressed to save space (main game is already packed)
;		           - 4 Colour Icon, MagicWB Icon, RomIcon, NewIcon and GlowIcon (created by me!)
;		           - Quit option (default key is 'F10')
; Requires:	WHDLoad 15+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
; Version 1:	Taken from the "Virtual Worlds" compilation. Copy protection 
;		is the file "nofastmem" which runs before the game
;		starts and alters the _LVOOpenLibrary(a6) call to check
;		for "KEV.library" and replace it with "dos.library" so the
;		game works. The main game is called "1" and the disk is
;		labelled "3D Worlds". This version does not have the file
;		"title.seq" on it! Supplied by Carlo Pirri!
; Version 2:	Unprotected version containing the main game "driller" and
;		the file "title.seq".
; Version 3:	Encrypted version with manual protection aswell. Supplied by
;		Mike West!
;---------------------------------------------------------------------------*

		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i
		INCLUDE	lvo/dos.i

		IFD BARFLY
		OUTPUT	"Driller.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;============================================================================
;CHIP_ONLY

	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $A8000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $40000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000


;DEBUG
;DISKSONBOOT
;DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"2.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

;============================================================================

		CNOP 0,4
slv_name		dc.b	"Driller"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
	dc.b	0
slv_copy		dc.b	"1988 Incentive Software/Domark"
		IFD		CHIP_ONLY
		dc.b	"(debug/chip mode)"
		ENDC
		dc.b	0
slv_info		dc.b	"Installed by Codetapper/Action",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		dc.b	-1,"Thanks to Carlo Pirri and Mike West"
		dc.b	10,"for sending the originals!"
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
	dc.b	"C4:L:speed:unregulated,fast,slow,slower;"
	dc.b	0
_MainFile	dc.b	"driller",0
_MainFile_V2	dc.b	"1",0
_args		dc.b	10
_args_end	dc.b	0
		EVEN
		
MAINLOOP_OFFSET_2555  = $0d922
VBLHOOK_OFFSET_2555 = $09ef0
MAINLOOP_OFFSET_2498 = $ed8e
VBLHOOK_OFFSET_2498 = $9f6a

_bootdos	move.l	_resload(pc),a2		;a2 = resload

	;get tags
	lea     (_tag,pc),a0
	jsr     (resload_Control,a2)


		lea	_dosname(pc),a1		;Open doslib
		move.l	(4),a6
		jsr	_LVOOldOpenLibrary(a6)
		move.l	d0,a6			;A6 = dosbase

		IFD		CHIP_ONLY
		move.l	a6,-(a7)
		move.l	#$20000-$1B4F0,d0
		move.l	#MEMF_CHIP,d1
		move.l	$4.w,a6
		jsr		_LVOAllocMem(a6)
		move.l	(a7)+,a6
		ENDC
		
		lea	_MainFile(pc),a0	;Original name
		bsr	_GetFileSize
		bne.b	_LoadIntro

		lea	_MainFile_V2(pc),a0	;3D Worlds name
		; no need to test if exists, let loadseg report it
_LoadIntro	move.l	a0,d1			;Load exe
		jsr	_LVOLoadSeg(a6)

		move.l	d0,d7			;D7 = segment
		beq	_failedtoload

		move.l	d7,a0
		add.l	a0,a0
		add.l	a0,a0
		add.l	#4,a0

		
		cmp.l	#$51639234,$98(a0)	;Encrypted version (Mike West, SPS 2498)
		beq	_Version3

		cmp.l	#'KEV.',$7ee2(a0)	;KEV.library protected version
		beq	_Game			;from 3D Worlds compilation (Carlo Pirri, SPS 2255)

		cmp.l	#'dos.',$7ee2(a0)	;dos.library unprotected version
		bne	_wrongver		;from 3D Worlds compilation (KEV->dos, SPS 2256)

_Game	
		lea	_PL_Game(pc),a0		;Patch game
		move.l	d7,a1
		jsr	resload_PatchSeg(a2)

		IFD DEBUG
		clr.l	-(a7)			;set debug
		move.l	d7,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add.w	#12,a7
		ENDC

		lea	_PL_LowMem(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		move.l	d7,a1			;call
		add.l	a1,a1
		add.l	a1,a1
		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

		bra	_exit

_PL_LowMem	PL_START
		PL_P	$100,_EmptyD1Loop	;Fix empty DBF loops
		PL_END

_PL_Game	PL_START
		PL_L	$5c,'dos.'		'KEV.library->dos.library
		PL_L	$7ee2,'dos.'		'KEV.library->dos.library
		PL_L	$a7f6,$4eb80100		;Empty d1 loop (4000)
		PL_PS	$ab56,_LongD0Loop	;1500000 empty d0 loop
		PL_S	$ab5c,$62-$5c
		PL_R	$ab6e			;Disk access
		PL_P	$ab9a,_LongD0Loop	;1500000 empty d0 loop
		PL_P	$b8a2,_exit
		PL_P	$A6,reloc_end
		PL_PS	$b626,kb_hook
		PL_END

_pl_game_pass_2
		PL_START
		PL_IFC4
		PL_PS	MAINLOOP_OFFSET_2555,mainloop_hook
		PL_PSS	VBLHOOK_OFFSET_2555,vbl_hook,4
		PL_ENDIF
		PL_END

reloc_end
	; there's a manual relocation phase in this game... maybe inherited
	; from Atari ST executables?
	;
	; at a minimum caches should be flushed (resload_Patch does that)
	
	LEA	28(A5),A0		;000a6: 41ed001c
	MOVEA.L	A6,A5			;000aa: 2a4e

	movem.l	d0-d1/a0-a2,-(a7)
	lea	(-$7E4A,a0),a1		; return to base address
	; save offset of the mainloop
	lea		_mainloop_first_jsr(pc),a0
	move.l	#MAINLOOP_OFFSET_2555,d0
	move.l	(2,a1,d0.l),(a0)
	lea		_potgo_copy(pc),a0
	move.l	#VBLHOOK_OFFSET_2555,d0
	move.l	(6,a1,d0.l),(a0)
	
	lea		_pl_game_pass_2(pc),a0
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp		(a0)
	
kb_hook
	move.w	d1,-(a7)
	not.b	d1
	ror.b	#1,d1
	cmp.b	_keyexit(pc),d1
	beq		_exit
	move.w	(a7)+,d1
	addq.l	#2,d0
	rts
	
mainloop_hook:
	; regulate
	bsr		vbl_reg
	; jump to original routine
	move.l	_mainloop_first_jsr(pc),-(a7)
	rts

vbl_reg:    
    movem.l d0-d1/a0,-(a7)
    move.l _speed_regulation(pc),d1       ; the bigger the longer the wait
    lea _vbl_counter(pc),a0
    move.w  (a0),d0
    cmp.w   #10,d0
    bcc.b   .nowait     ; first time called/lost sync/pause/whatever
    ; wait till at least x vblanks passed after last zeroing
.wait
    cmp.w   (a0),d1
    bcc.b   .wait
.nowait
    clr.w   (a0)
    movem.l (a7)+,d0-d1/a0
    rts
	
vbl_hook
    move.w  _custom+intreqr,d0
	btst	#5,d0
	beq.b	.novbl
    ; add to counter
    lea _vbl_counter(pc),a0
    addq.w  #1,(a0)
.novbl
	; original program
	move.l	_potgo_copy(pc),a0
	move.w	_custom+potinp,(a0)
	rts
	
;============================================================================

_LongD0Loop	move.l	#25-1,d0		;Wait half a second
.Wait		waitvb
		dbf	d0,.Wait
		rts

;============================================================================

PROGRAM_START_OFFSET_V3 = $7ea8
_Version3	lea	$128(a0),a6		;Decrypt the program
		lea	PROGRAM_START_OFFSET_V3(a0),a5
		move.l	a0,a3
		add.l	#$47648,a3
		lea	$7c(a0),a0
		lea	($28,a0),a0
		move.l	#$51639234,d0
		eor.l	d0,(a0)+
		eor.l	d0,(a0)+
		eor.l	d0,(a0)+
		eor.l	d0,(a0)+
		eor.l	d0,(a0)+
		eor.l	d0,(a0)+
		eor.l	d0,(a0)+
		clr.l	($24).l
		eor.l	d0,(a0)+
		eor.l	d0,(a0)+
		eor.l	d0,(a0)+
		clr.l	($24).l
		addi.l	#$17254376,d0
		add.l	d0,(a0)+
		add.l	d0,(a0)+
		add.l	d0,(a0)+
		add.l	d0,(a0)+
		add.l	d0,(a0)+
		add.l	d0,(a0)+
		moveq	#$20,d1
		add.l	d0,(a0)+
		add.l	d0,(a0)+
		movea.l	d1,a1
		add.l	d0,(a0)+
		clr.l	($24).l
		add.l	d0,(a0)+
		add.l	d0,(a0)+
		addq.w	#4,a1
.1b5c4		add.l	d0,(a0)+
		addi.l	#$51684624,d0
		move.l	d0,(a1)
		tst.l	(a3)
		bne.w	.1b5c4
		move.l	(2,a5),d0
		add.l	(6,a5),d0
		lea	($1C,a5,d0.l),a0
		lea	($1C,a5),a1
		move.l	a1,d2
		move.l	(a0)+,d0
		beq.b	.1b600
.1b5ea		adda.l	d0,a1
		add.l	d2,(a1)
.1b5ee		moveq	#0,d0
		move.b	(a0)+,d0
		beq.b	.1b600
		cmp.b	#1,d0
		bne.b	.1b5ea
		adda.w	#$FE,a1
		bra.b	.1b5ee

.1b600		movem.l	d0-d1/a0-a2,-(sp)

		lea	_PL_LowMem(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		move.l	a5,a1		; a1 = base+PROGRAM_START_OFFSET_V3
		; save offset of the mainloop
		lea		_mainloop_first_jsr(pc),a0
		move.l	#MAINLOOP_OFFSET_2498-PROGRAM_START_OFFSET_V3,d0
		move.l	(2,a1,d0.l),(a0)
		lea		_potgo_copy(pc),a0
		move.l	#VBLHOOK_OFFSET_2498-PROGRAM_START_OFFSET_V3,d0
		move.l	(6,a1,d0.l),(a0)

		lea	_PL_Game_V3(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		movem.l	(sp)+,d0-d1/a0-a2

		lea	($1C,a5),a0
		movea.l	a6,a5
		jmp	(a0)

_PL_Game_V3
		PL_START
		PL_L	$29c8,$4eb80100		;Empty d1 loop (4000)
		PL_PS	$2d28,_LongD0Loop	;1500000 empty d0 loop
		PL_S	$2d2e,$34-$2e
		PL_R	$2d40			;Disk access
		PL_P	$2d6c,_LongD0Loop	;1500000 empty d0 loop
		PL_P	$3a74,_exit
		PL_S	$3b3c,$68-$3c		;Skip scroll down/language selection/manual protection/scroll up
		PL_S	$3b5c,$62-$5c		;Remove manual protection (overkill)
		
		PL_IFC4
		PL_PS	MAINLOOP_OFFSET_2498-PROGRAM_START_OFFSET_V3,mainloop_hook
		PL_PSS	VBLHOOK_OFFSET_2498-PROGRAM_START_OFFSET_V3,vbl_hook,4
		PL_ENDIF
		
		PL_PS	$b6a0-PROGRAM_START_OFFSET_V3,kb_hook
		
		PL_END

;============================================================================

_EmptyD1Loop	movem.l	d0-d1,-(sp)
		and.l	#$ffff,d1
		divu	#80,d1
.wait1		move.b	(_custom+vhposr),d0
.wait2		cmp.b	(_custom+vhposr),d0
		beq	.wait2
		dbf	d1,.wait1
		movem.l	(sp)+,d0-d1
		rts

_EmptyD7Loop	move.l	d1,-(sp)
		move.l	d7,d1
		bsr	_EmptyD1Loop
		move.l	(sp)+,d1
		rts

;============================================================================

_GetFileSize	movem.l	d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		movem.l	(sp)+,d1/a0-a2
		tst.l	d0
		rts

;======================================================================

_failedtoload		jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
_exit		pea	TDREASON_OK
		bra	_end
;_debug		pea	TDREASON_DEBUG
;		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts
_tag		dc.l	WHDLTAG_CUSTOM1_GET
		dc.l	WHDLTAG_CUSTOM4_GET
_speed_regulation	dc.l	0
		dc.l	0

_mainloop_first_jsr
	dc.l	0
_potgo_copy
	dc.l	0
_vbl_counter
	dc.w	0
		END
