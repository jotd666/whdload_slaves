
		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"International3DTennis.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5d			;ws_keyexit = PrtSc
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================
    IFD    BARFLY
		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC
        ENDC
        
DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_name		dc.b	"International 3D Tennis",0
_copy		dc.b	"1990 Sensible Software/Palace",0
_info		dc.b	"Installed by Codetapper/Action!",10
		dc.b	"Version "
        DECL_VERSION
		dc.b	-1,"Press Help to toggle the mouse port on/off!"
		dc.b	-1,"Thanks to Didier Giron and"
		dc.b	10,"Philippe Bovier for the original!"
		dc.b	0
_FileName	dc.b	"International3DTennis."
_FileNumber	dc.b	"1",0
_SaveName	dc.b	"International3DTennis.save",0
_TrackNum	dc.b	0
		EVEN

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

_restart	lea	_FileName(pc),a0
		lea	$400,a1
		move.l	_resload(pc),a2
		jsr	resload_LoadFileDecrunch(a2)

		lea	_PL_Intro(pc),a0
		lea	$400,a1
		jsr	resload_Patch(a2)

		jmp	$400

_PL_Intro	PL_START
		PL_S	$c,$20-$c		;Disk access
		PL_P	$78,_Game		;Patch main game
		PL_P	$7e,_Loader		;Loading routines
		PL_R	$206			;Go to track d0
		PL_R	$21e			;Disk access
		PL_R	$23e			;Disk drive off
		PL_W	$3d4,$4204		;Colour bit fix (was $4004)
    
        PL_PSS  $16978-$400,fix_interrupt_wait,8
        PL_PS   $358,vbl_hook
		PL_END

vbl_hook:
    MOVE.W	#$0010,156(A6)		;00758: 3d7c0010009c
    move.w  d0,-(a7)
    move.b  $bfec01,d0
    ror.b   #1,d0
    not.b   d0
    cmp.b   _keyexit(pc),d0
    beq _exit
    move.w  (a7)+,d0
    rts
    
fix_interrupt_wait
    movem.l d3,-(a7)
    move.w   #$1000,d3       ; max wait x times
.wait
 	MOVE.W	intreqr(A0),D0		;16978: 3028001e
	ANDI.W	#$0780,D0		;1697c: 02400780
	AND.W	4(A4),D0		;16980: c06c0004
	bne.b   .out
    ; wait a bit, then retry
    tst.b   $BFE001
    tst.b   $BFE001
    dbf d3,.wait
.out
    movem.l (a7)+,d3
    RTS

; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d2,-(a7)
    move.b	$dff006,d2	; VPOS
.bd_loop2
	cmp.b	$dff006,d2
	beq.s	.bd_loop2
	move.w	(a7)+,d2
	dbf	d2,.bd_loop1
	rts

	; < A0: source
	; < A1: destination
	; < D0: size
memcpy:
	movem.l	d0-d3/A0/A1,-(a7)

	
	cmp.l	A0,A1
	beq.b	.exit		; same regions: out	
	bcs.b	.copyfwd	; A1 < A0: copy from start

	tst.l	D0
	beq.b	.exit		; length 0: out

	; here A0 > A1, copy from end

	add.l	D0,A0		; adds length to A0
	cmp.l	A0,A1
	bcc.b	.cancopyfwd	; A0+D0<=A1: can copy forward (optimized)
	add.l	D0,A1		; adds length to A1 too

.copybwd:
	move.b	-(A0),-(A1)
	subq.l	#1,D0
	bne.b	.copybwd

.exit
	movem.l	(a7)+,d0-d3/A0/A1
	rts

.cancopyfwd:
	sub.l	D0,A0		; restores A0 from A0+D0 operation
.copyfwd:
	move.l	A0,D1
	btst	#0,D1
	bne.b	.fwdbytecopy	; src odd: byte copy
	move.l	A1,D1
	btst	#0,D1
	bne.b	.fwdbytecopy	; dest odd: byte copy

	move.l	D0,D2
	lsr.l	#4,D2		; divides by 16
	move.l	D2,D3
	beq.b	.fwdbytecopy	; < 16: byte copy

.fwd4longcopy
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	subq.l	#1,D2
	bne.b	.fwd4longcopy

	lsl.l	#4,D3		; #of bytes*16 again
	sub.l	D3,D0		; remainder of 16 division

.fwdbytecopy:
	tst.l	D0
	beq.b	.exit
.fwdbytecopy_loop:
	move.b	(A0)+,(A1)+
	subq.l	#1,D0
	bne.b	.fwdbytecopy_loop
	bra.b	.exit

    
;======================================================================

_Game		movem.l	d0-d1/a0-a2,-(sp)

		bsr	_PatchKeyboard

		pea	_Kickstart(pc)
		move.l	(sp)+,$6c812

		lea	_PL_Game(pc),a0
		sub.l	a1,a1
		jsr	resload_Patch(a2)

		moveq	#5,d0			;Show credits screen for
		move.l	_resload(pc),a2		;a little bit
		jsr	resload_Delay(a2)

		bsr	_WaitButton

		movem.l	(sp)+,d0-d1/a0-a2
		jmp	$64abc

_PL_Game	PL_START


		PL_PS	$66c7c,_Keybd		;Detect quit key
		PL_W	$66d4c,$4204		;Colour bit fix (was $4004)
		PL_W	$6c5ac,12		;Switch joystick ports: move.w (10,a6),d0
		PL_W	$6c5b2,7		;Switch joystick buttons: btst #6,$bfe001
		;PL_W	$6c5c2,10		;Switch joystick ports: move.w (12,a6),d0
		PL_L	$6c5c0,$70007000	;Disable mouse in one player mode
		PL_W	$6c5ca,6		;Switch joystick buttons: btst #7,$bfe001
		PL_R	$761fa			;Deselect DF0
		PL_R	$76204			;Select DF0
		PL_R	$7620e			;Turn off DF0
		PL_R	$76220			;Turn on DF0
		PL_P	$7622e,_NextTrack	;Next track
		PL_P	$7623a,_PrevTrack	;Previous track
		PL_I	$76252			;Step a track
		PL_P	$76296,_GoToTrack0	;Go back to track 0
		PL_P	$762bc,_StoreTrackD0	;Step to track d0
		PL_P	$762d4,_StoreTrackD0	;Step to track d0
		PL_R	$762f0			;Check write protection
		PL_R	$762f8			;Turn off DF0 and deselect drive
		PL_NOP	$763bc,4	;Causes wrong track to be loaded
		PL_PS	$7646a,_StoreTrackD0
		PL_NOP	$76470,2
		PL_S	$764de,$76508-$764de
		PL_NOP	$764f8,$4	;Read track 0 looking for
		PL_NOP	$76500,$4	;original game disk
		PL_NOP	$765f8,$4	;MFM Encode data
		PL_P	$76600,_WriteTrack
		PL_P	$76632,_WriteTrack	;MFM Encode data
		PL_R	$766a8			;Don't reread the track looking for game disk
		PL_P	$766d8,_ReadTrack
		PL_END

    
    
_StoreTrackD0	move.l	a0,-(sp)
		lea	_TrackNum(pc),a0
		move.b	d0,(a0)
		move.l	(sp)+,a0
		rts

_NextTrack	move.l	a0,-(sp)
		lea	_TrackNum(pc),a0
		add.b	#2,(a0)
		move.l	(sp)+,a0
		rts

_PrevTrack	move.l	a0,-(sp)
		lea	_TrackNum(pc),a0
		sub.b	#2,(a0)
		move.l	(sp)+,a0
		rts

_GoToTrack0	move.l	a0,-(sp)
		lea	_TrackNum(pc),a0
		move.b	#0,(a0)
		move.l	(sp)+,a0
		rts

;======================================================================

_ReadTrack	movem.l	d0-d2/a0-a2,-(sp)
		move.l	_resload(pc),a2

		lea	_SaveName(pc),a0
		jsr	resload_GetFileSize(a2)
		tst.l	d0
		beq	_NoSaveFile

_FileExists	lea	_SaveName(pc),a0
		movea.l	(8,a5),a1
		move.l	#$1600,d0
		moveq	#0,d1
		move.b	_TrackNum(pc),d1
		mulu	#$1600,d1
		jsr	resload_LoadFileOffset(a2)
		bra	_LoadFinished

_NoSaveFile	movea.l	(8,a5),a1
		sub.w	#$8000,d2
		ext.l	d2
		add.l	d2,d2
		subq	#1,d2
_ClearBuf	move.b	#0,(a1)+
		dbf	d2,_ClearBuf
		
_LoadFinished	movem.l	(sp)+,d0-d2/a0-a2
		rts

_WriteTrack	movem.l	d0-d1/a0-a2,-(sp)
		move.l	a0,a1			;a1 = Address
		lea	_SaveName(pc),a0	;a0 = Filename
		move.l	#$1600,d0		;d0 = Length ($bb0)
		moveq	#0,d1
		move.b	_TrackNum(pc),d1
		mulu	#$1600,d1
		move.l	_resload(pc),a2
		jsr	resload_SaveFileOffset(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Loader		movem.l	d0-d1/a0-a2,-(sp)
		lea	_FileNumber(pc),a0
		move.l	($10,a5),a1
		move.l	_resload(pc),a2
		move.w	(12,a5),d0
		cmp.w	#56,d0			;Second load
		beq	_Load2
		cmp.w	#20,d0			;Third load
		bne	_exit
		move.b	#'3',(a0)
		bra	_LoadFile
_Load2		move.b	#'2',(a0)
_LoadFile	bsr	_FlushCache
		lea	_FileName(pc),a0
        cmp.l   #$33300,a1
        bne .lower
        sub.l   #$1000,a1
.lower
        movem.l a1,-(a7)
		jsr	resload_LoadFileDecrunch(a2)
        movem.l (a7)+,a1
        cmp.l   #$32300,a1
        bne .upper
        ; shift back the memory, avoid overflow $80000
	; < A0: source
	; < A1: destination
	; < D0: size
    move.l  a1,a0
    lea ($1000,a1),a1
    move.l  #$7FF00-$33300,d0
    bsr memcpy
.upper
       
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_FlushCache	movem.l	d0-d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_FlushCache(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_WaitButton	movem.l	d0-d1/a0-a2,-(sp)
		waitbutton
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Keybd		move.b	$bfec01,d0		;Stolen code

		move.l	d0,-(sp)
		ror.b	#1,d0
		not.b	d0
		cmp.b	_keyexit(pc),d0
		beq	_exit
		cmp.b	#$5f,d0
		bne	_NotHelp

		eor.l	#$302e000a^$70007000,$6c5c0
		bsr	_FlushCache		;Toggle mouse on/off

_NotHelp	move.l	(sp)+,d0
		rts

;======================================================================

_PatchKeyboard	movem.l	d0-d2/a0-a2,-(sp)

		clr.l	-(a7)			;Get keycode table
		clr.l	-(a7)
		pea	WHDLTAG_VERSION_GET
		move.l	a7,a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)
		move.l	(4,a7),d0		;a2 = System rawkey to Ascii table
		add.w	#12,a7

		cmp.b	#12,d0
		blt	_NotV12

		clr.l	-(a7)			;Get keycode table
		clr.l	-(a7)
		pea	WHDLTAG_KEYTRANS_GET
		move.l	a7,a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)
		move.l	(4,a7),a2		;a2 = System rawkey to Ascii table
		add.w	#12,a7

		move.l	a2,a0			;Update qwertyuiop
		add.l	#11,a0			;a0 = WHDLoad's version of qwerty...
		lea	$6bee7,a1		;a1 = Games copy of qwerty...
		move.l	#$35,d0			;Update 3 and a bit rows of keys :)
		bsr	_UpdateKeys

_NotV12		movem.l	(sp)+,d0-d2/a0-a2
		rts

;======================================================================

_UpdateKeys	movem.l	d0-d1/a0-a2,-(sp)
		subq	#1,d0			;Correct length for DBF loop

.ProcessNext	move.b	(a0)+,d2
		cmp.b	#'0',d2			;Numeric keys 0-9 are OK
		blt	.CopyIfValid
		cmp.b	#'9',d2
		ble	.CopyCharacter
		cmp.b	#'A',d2			;Uppercase letters are OK
		blt	.CopyIfValid
		cmp.b	#'Z',d2
		ble	.CopyCharacter
		cmp.b	#'a',d2			;Lowercase letters are OK
		blt	.CopyIfValid
		cmp.b	#'z',d2
		bgt	.CopyIfValid
		sub.l	#'a'-'A',d2		;Convert to uppercase
.CopyCharacter	move.b	d2,(a1)+
.NextChar	dbf	d0,.ProcessNext
		movem.l	(sp)+,d0-d1/a0-a2
		rts

.DoNotCopy	add.w	#1,a1
		bra	.NextChar

.CopyIfValid	lea	_KeysAllowed(pc),a2
.IsCharOK	move.b	(a2)+,d1
		tst.b	d1
		beq	.DoNotCopy		;End of string of characters
		cmp.b	d1,d2
		beq	.CopyCharacter		;Character is OK to copy
		bra	.IsCharOK

_KeysAllowed	dc.b	"'-=\[];#,./",0
		EVEN

;======================================================================
_resload	dc.l	0		;address of resident loader
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================

_Kickstart	dc.l	$11114EF9,$FC00D2,$FFFF,$220005,$220002
		dc.l	$FFFFFFFF,$65786563,$2033342E,$32202832,$38204F63
		dc.l	$74203139,$3837290D,$A000000,$FFFFFFFF,$D0A0A41
		dc.l	$4D494741,$20524F4D,$204F7065,$72617469,$6E672053
		dc.l	$79737465,$6D20616E,$64204C69,$62726172,$6965730D
		dc.l	$A436F70,$79726967,$68742028,$43292031,$3938352C
		dc.l	$20436F6D,$6D6F646F,$72652D41,$6D696761,$2C20496E
		dc.l	$632E0D0A,$416C6C20,$52696768,$74732052,$65736572
