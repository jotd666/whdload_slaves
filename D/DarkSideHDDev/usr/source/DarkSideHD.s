;*---------------------------------------------------------------------------
; Program:	DarkSide.s
; Contents:	Slave for "Dark Side" (c) 1989 Incentive Software/Domark
; Author:	Codetapper/Action
; History:	20.04.2002 - v1.0
;		           - Full load from HD
;		           - Loads and saves games to HD
;		           - Empty DBF loop fixed
;		           - Stack relocated to fast memory
;		           - Instructions included
;		           - 4 Colour Icon, MagicWB Icon, RomIcon, NewIcon, OS3.5 Colour Icon (created by 
;		             me!) and 2 Exoticons (taken from http://exotica.fix.no)
;		           - Quit option (default key is 'PrtSc' on numeric keypad)
;		31.05.2002 - v1.1
;		           - Also supports the Rob Northen series 1 copylocked version (thanks to 
;		             Belgarath for supplying and decoding the copylock!)
; Requires:	WHDLoad 15+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
; Version 1:	US release from Cinemaware, unprotected. Supplied by Adrian
;		Simpson. The file dates show an April 1989 release.
; Version 2:	UK release from Microprose, Rob Northen series 1 copylock.
;		Supplied and decoded by Belgarath! The 1.drk file has a
;		single byte difference between it and version 1. The file
;		dates show a May 1989 release.
;---------------------------------------------------------------------------*

		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i
		INCLUDE	lvo/dos.i

		IFD BARFLY
		OUTPUT	"DarkSide.slave"
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
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
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


MAINLOOP_OFFSET_V1  = $559c
VBLHOOK_OFFSET_V1 = $10a4


;============================================================================

DECL_VERSION:MACRO
	dc.b	"2.0"
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
	
slv_name		dc.b	"Dark Side"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
	dc.b	0
slv_copy		dc.b	"1989 Incentive Software/Domark",0
slv_info		dc.b	"Installed by Codetapper & JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		dc.b	-1,"Thanks to Adrian Simpson, Mike West and"
		dc.b	10,"Belgarath for sending the originals!"
		dc.b	0
slv_CurrentDir:
		dc.b	"data",0
slv_config:
	dc.b	"C4:L:speed:unregulated,fast,slow,slower;"
	dc.b	0
_MainFile	dc.b	"0.drk",0
_args		dc.b	10
_args_end
		EVEN

						

_bootdos	move.l	_resload(pc),a2		;a2 = resload

	;get tags
	lea     (_tag,pc),a0
	jsr     (resload_Control,a2)

		lea	_dosname(pc),a1		;Open doslib
		move.l	(4),a6
		jsr	_LVOOldOpenLibrary(a6)
		move.l	d0,a6			;A6 = dosbase


		IFD	CHIP_ONLY
		movem.l	A6,-(a7)
		move.l	4,a6
		move.l	#$30000-$2f1e8,d0
		move.l	#MEMF_CHIP,d1
		jsr		_LVOAllocMem(a6)
		movem.l	(a7)+,a6
		ENDC
		
		lea	_MainFile(pc),a0	;Virtual Worlds intro name
_LoadIntro	move.l	a0,d1			;Load exe
		jsr	_LVOLoadSeg(a6)
		move.l	d0,d7			;D7 = segment
		beq	_failedtoload

		move.l	d7,a0
		add.l	a0,a0
		add.l	a0,a0
		add.l	#4,a0

		cmp.l	#$4afc23c0,$ee(a0)	;Rob Northen series 1 copylock
		beq	_Intro_V2

		cmp.l	#'KEV.',$30(a0)		;KEV.library protected version
		beq	_IntroOK

		cmp.l	#'dos.',$30(a0)		;dos.library unprotected version
		bne	_wrongver

_IntroOK	lea	_PL_Intro(pc),a0	;Patch game
		move.l	d7,a1
		jsr	resload_PatchSeg(a2)

_CommonIntro	IFD DEBUG
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

_PL_Intro	PL_START
		PL_L	$30,'dos.'		;KEV.library->dos.library
		PL_PS	$29a,_Game		;lea ($1c,a6),a0 to jump to game
		PL_L	$180+2,$10000		; chipmem => fastmem for main program
		PL_END

;============================================================================

_Intro_V2	move.l	d7,-(sp)		;Save segment address
		move.l	a0,a5			;a5 = Start of the data

		move.l	#$4f9a,d0		;d0 = Length of encrypted data
		move.l	#$a9c98459,d5		;D0 = $00004F9A , D1 = $00000001
		move.l	#$d4657d6f,d6		;D5 = $A9C98459 , D6 = $D4657D6F
		move.l	#$d465e035,d7		;D7 = $D465E035 , A0 = $00000CEC
		lea	$cec-$20(a5),a0		;A1 = $0000001C , A2 = $00000CF0
		bsr	_Decrypt		

		lea	$cf0-$20+$c(a5),a2	;Table of reloc32 values
		lea	$e5c-$20(a5),a3		;Current position of game code
		move.l	a5,d0			;Destination address
_RelocNext	move.l	(a2)+,d2
		beq	_RelocDone		;Registers used for relocate file
		add.l	d0,(a3,d2.l)		;
		bra	_RelocNext		;A2 = $00000CF0 , A3 = $00000E5C

_RelocDone	lea	$e5c-$20(a5),a0
		move.l	a5,a1
		move.l	#$4f9a-1,d0
_Relocate	move.l	(a0)+,(a1)+
		dbf	d0,_Relocate

		lea	_PL_Intro(pc),a0	;Patch game (PatchSeg fails so
		move.l	a5,a1			;we will do it this way)
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		move.l	(sp)+,d7		;Restore segment address
		bra	_CommonIntro

;============================================================================

_Game
		; first, restore A6: MOVEA.L	(A7)+,A6
		move.l	(4,a7),a6
	
		move.l	A6,$200.W	; to debug
		; return address where it should be
		move.l	(a7),(4,a7)
		; and pop stack
		addq.w	#4,a7
		
		movem.l	d0-d1/a0-a2/a6,-(sp)	;Patch main game



		move.l	#$4eaefdd8,d0		;jsr _LVOOpenLibrary(a6)
		cmp.l	$3c6(a6),d0
		bne	_wrongver

		move.l	a6,a1
		
		; save offset of the mainloop
		lea		_mainloop_first_jsr(pc),a0
		move.l	#MAINLOOP_OFFSET_V1,d0
		move.l	(2,a1,d0.l),(a0)
		lea		_potgo_copy(pc),a0
		move.l	#VBLHOOK_OFFSET_V1,d0
		move.l	(6,a1,d0.l),(a0)
		
		lea	_PL_GameV1(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)


_StartGame	movem.l	(sp)+,d0-d1/a0-a2/a6
		lea	$1c(a6),a0		;Stolen code
		rts

_flush_the_caches
	ADDI.L	#$00009c40,D1
	bra		_flushcache
	
_PL_GameV1	PL_START
		PL_L	$20ee,$4eb80100		;Empty d1 loop (4000)
		PL_PS	$2706,_LongD0Loop	;1500000 empty d0 loop
		PL_S	$270c,$12-$c
		PL_R	$271e			;Disk access
		PL_P	$274a,_LongD0Loop	;1500000 empty d0 loop
		PL_P	$2c88,_debug		;Infinite loop
		PL_P	$2c96,_debug		;Infinite loop
		PL_P	$2d10,_exit
		
		PL_PS	$466,_flush_the_caches
		
		; remove check for "exe located high in memory"
		; that crashes the game if exe runs in fastmem
		;PL_NOP	$3e2,4
		;PL_B	$422,$60
		
		; speed regulation
		PL_IFC4
		PL_PS	MAINLOOP_OFFSET_V1,mainloop_hook
		PL_PSS	VBLHOOK_OFFSET_V1,vbl_hook,4
		PL_ENDIF
		
		; add a few bytes to fix game allocation size error
		; (if not changed, crashes when pressing a key to start game!)
		PL_AL	$3D0+2,$10
		
		PL_END

;============================================================================

_LongD0Loop	move.l	#25-1,d0		;Wait half a second
.Wait		waitvb
		dbf	d0,.Wait
		rts

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
		rts

;======================================================================

_Decrypt	movem.l	d0/d5-d7/a0,-(sp)	;Rob Northen Decryption (3 Key)
.DecryptLoop	lsl.l	#1,d7
		btst	d5,d7
		beq.s	.Skip1
		btst	d6,d7
		beq.s	.Skip3
		bra.s	.Skip2
.Skip1		btst	d6,d7
		beq.s	.Skip2
.Skip3		addq.l	#1,d7			;Modify key for correct btst otherwise fuckup!
.Skip2		add.l	d7,(a0)			;Modify key to encrypted data = correct data
		add.l	(a0)+,d7		;Modify key with next encrypted longword
		subq.l	#1,d0			;Subtract from counter until null
		bne.s	.DecryptLoop
		movem.l	(sp)+,d0/d5-d7/a0
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
	
;======================================================================

_failedtoload
		jsr	(_LVOIoErr,a6)
		move.l	a3,-(a7)
		move.l	d0,-(a7)
		pea	TDREASON_DOSREAD
		bra	_end
		
_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
		bra	_end
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
