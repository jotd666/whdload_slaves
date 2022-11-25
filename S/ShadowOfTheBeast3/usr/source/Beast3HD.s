;*---------------------------------------------------------------------------
;  :Program.	Beast3.asm
;  :Contents.	Slave for "Shadow Of The Beast 3" from Psygnosis
;  :Author.	Mr.Larmer of Wanted Team / JOTD / StingRay
;  :History.	10.12.99
;		02.12.00 - by Galahad: intro patched (only ntsc version)
;               01.10.01 - by Bored Seal: intro patched for pal version, decrunch added
;		13.06.16 - by StingRay: 
;			   - code optimised
;			   - ByteKiller decruncher optimised and error check
;			     added
;			   - Bplcon0 color bit fixed (x4)
;			   - patch code converted to use patch lists
;			   - disk access in intro removed
;			   - byte write to volume register fixed (menu, levels
;			     game over)
;		15.06.16   - intro in PAL version works now, Galahad's loader
;			     was buggy and has been completely recoded!
;			   - "Insert Game Disk 1" screen disabled
;			   - Intro can be skipped with CUSTOM2
;       30.08.17  - by JOTD
;               - added CD32 pad controls
;               - added CD32/joystick auto detection routine to avoid button 2 => pause
;                 on 2-buttons joystick because of CD32 joypad read
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	PhxAss/Barfly/VASM
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

;======================================================================



COMM_NONE = 0
COMM_PAUSE = 1
COMM_QUITGAME = 2
COMM_RESTART = 3

;DEBUG

; WHDLoad v18+ includes are not compatible with
; ASM-One/Pro so until I fix them this workaround must do

	IFEQ	1
	IFND	PL_IFC1

PL_IFC1		MACRO
		dc.w	1<<14+29
		ENDM
PL_IFC2		MACRO
		dc.w	1<<14+30
		ENDM
PL_ENDIF	MACRO
		dc.w	1<<14+40
		ENDM
	ENDC
	ENDC
	
; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM

USE_FASTMEM = 1

	IFND	USE_FASTMEM
CHIPMEMSIZE = $100000
FASTMEMSIZE = 0
	ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = $80000
	ENDC
	
DECL_VERSION:MACRO
	dc.b	"1.6"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	
base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem	;ws_flags
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-base	;ws_GameLoader
		IFD	DEBUGSTING
		dc.w	_dir-base	; ws_CurrentDir
		ELSE
		dc.w	0		;ws_CurrentDir
		ENDC
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = none
_keyexit	dc.b	$58		;ws_keyexit = F9
_expmem:
		dc.l	FASTMEMSIZE		;ws_ExpMem
		dc.w	_name-base	;ws_name
		dc.w	_copy-base	;ws_copy
		dc.w	_info-base	;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-base		;ws_config

_name		dc.b	'Shadow of the Beast III'
		IFD	DEBUG
		dc.b	" (debug mode)"
		ENDC
			dc.b	0
_copy		dc.b	'1992 Psygnosis',0
_info		dc.b	'Installed and fixed by Mr.Larmer',10,10
		dc.b	'Joypad/2-button controls by JOTD',10
		dc.b	'Intro sequence fixed by StingRay',10
		dc.b	"Other fixes by StingRay",10,10
		dc.b	'Version '
		DECL_VERSION
		dc.b	-1
		dc.b	0

		IFD	DEBUGSTING
_dir		
		dc.b	"SOURCES:WHD_Slaves/Beast3/PAL",0
		ENDC

		even
_config
	; Custom 1 now removed, not really useful since it just adds features
		dc.b	"C2:B:Skip Intro"
		dc.b	0

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	CNOP 0,2
	
	include	ReadJoyPad.s

;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use
		move.l	a0,a2
		
		lea	_tags(pc),a0
		jsr	(resload_Control,a2)
		
		; decide between cd32 joypad and joystick
		bsr	_detect_controller_types

		lea	$4000.w,A0
		moveq	#0,D0
		move.l	#$400,D1
		moveq	#1,d2
		bsr.w	_LoadDisk

		pea	Patch(pc)
		move.l	(A7)+,$128(A0)

		move.l	#$78004E75,$12C(A0)	; skip drive on

		move.w	#$4EF9,$26E(A0)
		pea	Load(pc)
		move.l	(A7)+,$270(A0)

		move.l	#$80000,D0
		IFND	USE_FASTMEM
		move.l	D0,D1	; 512K extstart, 512K size
		ELSE
		move.l	D0,D1	; 512K size
		move.l	_expmem(pc),D0	; fastmem extstart
		ENDC
		
		jmp	$C2(A0)

;--------------------------------

Patch	lea	PLBOOT(pc),a0		; stingray, 13-jun-2016: patch list!
	pea	$7c000
	move.l	(a7),a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	rts	


PLBOOT	PL_START
	PL_W	$136,$600a			; skip cache stuff
	
	PL_P	$242,Loader
	PL_P	$948,Decrunch			; relocate ByteKiller decruncher
	PL_P	$a30,Load2
	PL_R	$b40				; disable drive access
	PL_P	$dae,LoadDOS

; fixes by stingray
	PL_ORW	$276+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$396+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$3b8+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$464+2,1<<9			; set Bplcon0 color bit

	PL_SA	$16c,$1e6			; skip "Insert Game Disk 1"

	PL_IFC2					
	PL_S	$142,6				; skip intro if CUSTOM2<>0
	PL_ELSE
	PL_PS	$142,Intro			; patch intro
	PL_ENDIF

	PL_END


;--------------------------------

; all intro patches done by stingray, June 2016
; loader properly emulated, disk accesses disabled, full
; support for PAL and NTSC versions

Intro	lea	$8000,a1		; stingray, 13-jun-2016: patch list!
	lea	PLINTRO_PAL(pc),a0
	cmp.l	#$43faffbc,$42(a1)
	beq.b	.patch
	lea	PLINTRO_NTSC(pc),a0

.patch	move.l	a1,-(a7)
	move.l	_resload(pc),a2
	jmp	resload_Patch(a2)



PLINTRO_PAL
	PL_START
.O	= $3b00	; variables start $3b00 bytes before binary

	PL_SA	$4812-.O,$4828-.O	; skip drive access (drive on)
	PL_SA	$4830-.O,$4842-.O	; skip waiting for drive motor
	PL_SA	$484a-.O,$485c-.O	; don't step to track 0
	PL_R	$48ce-.O		; disable step
	PL_SA	$48ae-.O,$48b8-.O	; don't set side
	PL_PSA	$4912-.O,loadtrack,$4948-.O
	PL_SA	$4950-.O,$495c-.O	; fake DSKBLK interrupt
	PL_SA	$4964-.O,$4970-.O	; skip decoding pass 1
	PL_SA	$4976-.O,$4982-.O	; skip decoding pass 2
	PL_SA	$49a2-.O,$49cc-.O	; skip drive access
	PL_SA	$4988-.O,$4990-.O	; skip buggy "blitter busy" check
	PL_END


loadtrack
	move.l	#$1800,d1		; size
	move.w	$6d2(a5),d0		; track
	lsr.w	#1,d0
	mulu.w	d1,d0

	tst.w	$6ce(a5)		; side
	beq.b	.side1
	add.l	#80*$1800,d0
.side1


	move.l	$6d6(a5),a0		; destination
	add.l	d1,$6d6(a5)
	moveq	#1,d2
	move.l	_resload(pc),a2
	jmp	resload_DiskLoad(a2)



PLINTRO_NTSC
	PL_START
	PL_SA	$d7a,$d90		; skip drive access (drive on)
	PL_SA	$d98,$daa		; skip waiting for drive motor
	PL_SA	$db2,$dc4		; don't step to track 0
	PL_R	$e36			; disable step
	PL_SA	$e16,$e20		; don't set side
	PL_PSA	$e7a,loadtrack,$eb0
	PL_SA	$eb8,$ec4		; fake DSKBLK interrupt
	PL_SA	$ecc,$ed8		; skip decoding pass 1
	PL_SA	$ede,$eea		; skip decoding pass 2
	PL_SA	$f0a,$f2e		; skip drive access
	PL_SA	$ef0,$ef8		; skip buggy "blitter busy" check

	PL_SA	$3e,$52			; skip cache stuff
	PL_END


;--------------------------------




CheckJoypad:
	movem.l	D0/A0,-(sp)
	cmp.b	#$7F,($29A).W	; space pressed
	bne.b	.sksp
	lea	spaceemu(pc),A0
	tst.l	(A0)
	beq.b	.sksp
	clr.l	(A0)
	move.b	#$7E,($29A).W	; space released
.sksp

	moveq.l	#1,D0	; port 1
	bsr	_read_joystick
	;tst.w	D0
	beq	.exit

	lea	command(pc),A0

	; ** button 2: change weapon
	
	btst	#JPB_BTN_BLU,D0
	beq.b	.1

	lea	spaceemu(pc),A0
	move.l	#1,(A0)
	move.b	#$7F,($29A).W		; space pressed
	bra	.exit

	; ** start: pause
.1
	btst	#JPB_BTN_PLAY,D0
	beq.b	.2

	move.l	#COMM_PAUSE,(A0)
	bra.b	.exit

	; ** forward: cheat on
.2

	btst	#JPB_BTN_FORWARD,D0
	beq.b	.3
	btst	#JPB_BTN_REVERSE,D0
	beq.b	.3ok
	; BWD+FWD at the same time: quit game: TODO
	move.l	#COMM_QUITGAME,(A0)
	bra.b	.exit
.3ok
	move.b	#1,$2CB.W
	bra.b	.exit

	; ** back: cheat off

.3
	btst	#JPB_BTN_REVERSE,D0
	beq.b	.4
	clr.b	$2CB.W
	bra.b	.exit

	; *** green+yellow: restart part
.4
	btst	#JPB_BTN_GRN,D0
	beq.b	.5
	btst	#JPB_BTN_YEL,D0
	beq.b	.5

	move.l	#COMM_RESTART,(A0)
	bra	.exit
.5

.exit
	movem.l	(sp)+,D0/A0
	move.w	#$20,(intreq,A6)
	rts

JoyPatch:
.loop
	move.l	D0,-(sp)
	move.l	command(pc),D0
	bne.b	.action
	move.l	(sp)+,D0
.cont
	tst.b	($30E).W
	beq.b	.loop
	rts

.action
	move.l	A0,-(sp)
	lea	command(pc),A0
	clr.l	(A0)
	move.l	(sp)+,A0	

	cmp.l	#COMM_RESTART,D0
	beq.b	.rest

	cmp.l	#COMM_PAUSE,D0
	beq.b	.pause
	
	cmp.l	#COMM_QUITGAME,D0
	beq.b	.quitgame

	move.l	(sp)+,D0
	bra.b	.cont

.weapon
	move.l	(sp)+,D0
	jmp	($7E0C).W	

.pause
	move.l	(sp)+,D0
	jmp	($7DF4).W	
.rest
	move.l	(sp)+,D0
	jmp	($7E68).W
.quitgame
	move.l	(sp)+,D0
	jmp	($7E52).W	


;--------------------------------

Loader		lea	$70000,a0
		pea	Patch2(pc)
		move.l	(A7)+,$6C(a0)

		move.w	#$4EF9,$70(a0)
		pea	LoadPsyFile(pc)
		move.l	(sp)+,$72(a0)
		bsr	_flushcache
		jmp	(a0)

Patch2		cmp.b	#$11,$494.w
		beq.b	NTSC

		move.b	#$60,$48A.w	; skip region check using display mode (PAL or NTSC)
		move.l	#$4E714EF9,$6C0.w
		pea	Patch3_PAL(pc)
		move.l	(A7)+,$6C4.w

		move.w	#$4E75,$716.w	; drive off skip

		move.w	#$4EF9,$A5A.w
		pea	LoadPsyFile(pc)
		move.l	(sp)+,$A5C.w

		bra.w	game_patched


NTSC		move.w	#$4E71,$48A.w	; skip region check using display mode (PAL or NTSC)

		move.l	#$4E714EF9,$6C4.w
		pea	Patch3_NTSC(pc)
		move.l	(A7)+,$6C8.w

		move.w	#$4E75,$71A.w	; drive off skip

		move.w	#$4EF9,$A5E.w
		pea	LoadPsyFile(pc)
		move.l	(A7)+,$A60.w
		
game_patched
		pea	Patch_X(pc)
		move.l	(sp)+,$416.w

	move.w	#$6002,$42E.w	; skip set priv. viol. vector
		bsr	_flushcache
		jmp	$400.w

Patch_X
		; just before title screens (reflections / sotb title)
		movem.l	d0-d1/a0-a2,-(a7)
		lea	pl_post_intro(pc),a0
		lea	$70000,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		jmp	$7001a


pl_post_intro:
	PL_START
	PL_IFC2
	; skip reflections & sotb title screens
	PL_S	$15E,$23A-$15E		
	PL_ENDIF
	PL_END
_flushcache
	move.l	a2,-(sp)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(sp)+,a2
	rts
	
FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts


Patch3_PAL:
	jsr	$702E0
	bra.b	go

Patch3_NTSC:
	jsr	$702E4
go	
	move.w	#$6016,$857E	; drive off skip

; $67772 decrunch

	move.w	#$4E75,$6A848	; drive off skip

	move.w	#$4EF9,$6B4A8
	pea	LoadPsyFile(pc)
	move.l	(A7)+,$6B4AA

	;	jotd/stingray fixes
	
	movem.l	D0-A2,-(a7)
	move.l	_resload(pc),a2
	lea	pl_jotd(pc),a0
	sub.l	a1,a1
	jsr	resload_Patch(a2)
	movem.l	(a7)+,D0-A2
	bsr	_flushcache
	jmp	$256.W

pl_jotd
	PL_START
	; *** remove a mask of the memory zone
	; *** which overrides some of the memory
	PL_W	$4AFC,$6024
	
	; *** installs the quit patch

	PL_PS	$7BEE,kbint2

	; *** activates the original cheat keys
	; (in the key test routine)

	PL_W	$7D2C,$4E71
	
	; *** patch for joypad

	PL_IFC1
	PL_PS	$7BD0,CheckJoypad
	PL_P	$7778,JoyPatch
	PL_ENDIF


; stingray, 13-jun-2016
	PL_PS	$5632,.fixreplays
	PL_PS	$6a9f2,.fixreplay_gameover

	PL_END

.fixreplay_gameover
	pea	FixAudXVol(pc)
	move.w	#$4ef9,$b624
	move.l	(a7)+,$b624+2
	bsr	_flushcache
	jmp	$b000


.fixreplays
	move.l	$2e6.w,a0

	cmp.l	#$b000,a0
	bne.b	.out

	movem.l	d0/a0,-(a7)
	move.l	#$b62c,d0
	cmp.l	#$1b6e0003,$b62c
	beq.b	.fix
	move.l	#$b68a,d0
	cmp.l	#$1b6e0003,$b68a
	beq.b	.fix

.return	movem.l	(a7)+,d0/a0
	
	


.out	jmp	(a0)

.fix	move.l	d0,a0
	pea	FixAudXVol(pc)
	move.w	#$4ef9,(a0)+
	move.l	(a7)+,(a0)
	bsr	_flushcache
	bra.b	.return



kbint2:
	move.b	$BFEC01,D0
	move.l	D0,-(sp)
	ror.b	#1,D0
	not.b	D0
	cmp.b	_keyexit(pc),D0	; raw keycode for F5
	beq	_quit
	move.l	(sp)+,D0
	tst.b	$BFEC01
	rts

_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(sp)
	add.l	#resload_Abort,(sp)
	rts
	
LoadPsyFile	movem.l	d0-a6,-(a7)
		lea	Dir(pc),A1

		cmp.w	#5,D1
		bne.b	.skip

		move.l	#$3000,D0
		move.l	#$1000,D1

		move.l	A0,(A1)

		lea	DiskNr(pc),a1
		moveq	#2,d3
		cmp.l	#'f40'<<8,d2
		bne.b	.skip2
		moveq	#3,d3
.skip2
		move.w	d3,(a1)

		moveq	#0,d2
		move.w	(a1),D2

		bsr.w	_LoadDisk

		bra.b	.exit
.skip
		move.l	(A1),A2
		lea	$C00(A2),A3
		moveq	#0,D0
		moveq	#0,D1
		moveq	#0,D2
.loop
		movem.l	A0/A2,-(A7)
.loop2
		move.b	(A0)+,D0
 		move.b	(A2)+,D1
		cmp.b	D0,D1
		bne.b	.next
		tst.b	D0
		bne.b	.loop2
		bra.b	.ok
.next
		movem.l	(A7)+,A0/A2
		addq.b	#1,D2
		lea	$10(A2),A2
		bra.b	.loop
.ok
		movem.l	(A7)+,A0/A2

		move.l	$24(A7),A0		;dest

		move.l	#$400,D1		; track length

		move.l	$C(A2),D3		; file length
		lea	(A3),A4

		cmp.l	D1,D3
		blo.b	.loop5
		sub.l	D1,D3
		bra.b	.loop3
.loop5
		move.l	d3,d1
		moveq	#0,d3
.loop3
		cmp.b	(A4)+,D2		; search file number
		bne.b	.loop3
		move.l	A4,D0
		subq.l	#1,D0
		sub.l	A3,D0
		mulu	#$400,D0

		lea	DiskNr(pc),a1
		move.l	d2,-(A7)
		moveq	#0,d2
		move.w	(a1),D2

		bsr.w	_LoadDisk
		move.l	(a7)+,d2

		add.l	D1,a0
		tst.l	d3
		beq.b	.exit
		cmp.l	D1,D3
		bhi.b	.loop4
		move.l	D3,D1
		moveq	#0,D3
		bra.b	.loop3
.loop4
		sub.l	D1,D3
		bra.b	.loop3
.exit
		movem.l	(A7)+,d0-a6
		moveq	#0,D0
		rts

Dir		dc.l	0
DiskNr		dc.w	2

;--------------------------------
;a0 = Load at
;d0 = Start
;d1 = Length
Load2
		movem.l	d0-d2/a0-a1,-(a7)
		cmp.l	#$1800,D0
		bne.s	other_file
offset:		move.l	#$34800-$1800,d1	;Size of part 1.0
		moveq	#1,d2			;Disk 1
		bsr.s	_LoadDisk											
		add.l	offset+2(pc),a0
		move.l	#$34800+$43800,d0		
		move.l	#$4934c-$33000,d1
		bra.s	Skip

other_file:	add.l	#$43800,d0		;Get correct offset!
Skip:		moveq	#1,D2
		bsr.b	_LoadDisk
		movem.l	(A7)+,d0-d2/a0-a1
		moveq	#0,D0
		rts

LoadDOS		movem.l	d0-a6,-(a7)
		moveq	#0,D0
		move.w	D1,D0
		mulu	#512,D0
		moveq	#0,D1
		move.w	D2,D1
		mulu	#512,D1
		moveq	#2,D2
		bsr.b	_LoadDisk
		movem.l	(A7)+,d0-a6
		moveq	#0,D0
		rts

Load		movem.l	d0-a6,-(a7)
		move.l	#$A6800,D0
		move.l	#$3000,D1
		moveq	#1,D2
		bsr.b	_LoadDisk
		movem.l	(A7)+,d0-a6
		moveq	#0,D4
		rts

_resload	dc.l	0

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts



; Bytekiller decruncher
; resourced and adapted by stingray
;
Decrunch
BK_DECRUNCH
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	.ErrTxt(pc)
	pea	(TDREASON_FAILMSG).w
	move.l	_resload(pc),a0
	jmp	resload_Abort(a0)


.ok	rts

.ErrTxt	dc.b	"Decrunching failed, file corrupt!",0
	cnop	0,4

.decrunch
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d5
	move.l	a1,a2
	add.l	d0,a0
	add.l	d1,a2
	move.l	-(a0),d0
	eor.l	d0,d5
.loop	lsr.l	#1,d0
	bne.b	.nonew1
	bsr.b	.nextlong
.nonew1	bcs.b	.getcmd

	moveq	#8,d1
	moveq	#1,d3
	lsr.l	#1,d0
	bne.b	.nonew2
	bsr.b	.nextlong
.nonew2	bcs.b	.copyunpacked

; data is packed, unpack and copy
	moveq	#3,d1			; next 3 bits: length of packed data
	clr.w	d4

; d1: number of bits to get from stream
; d4: length
.packed	bsr.b	.getbits
	move.w	d2,d3
	add.w	d4,d3
.copypacked
	moveq	#8-1,d1
.getbyte
	lsr.l	#1,d0
	bne.b	.nonew3
	bsr.b	.nextlong
.nonew3	addx.l	d2,d2
	dbf	d1,.getbyte

	move.b	d2,-(a2)
	dbf	d3,.copypacked
	bra.b	.next

.ispacked
	moveq	#8,d1
	moveq	#8,d4
	bra.b	.packed

.getcmd	moveq	#2,d1			; next 2 bits: command
	bsr.b	.getbits
	cmp.b	#2,d2			; %10: unpacked data follows
	blt.b	.notpacked
	cmp.b	#3,d2			; %11: packed data follows
	beq.b	.ispacked

; %10
	moveq	#8,d1			; next byte:
	bsr.b	.getbits		; length of unpacked data
	move.w	d2,d3			; length -> d3
	moveq	#12,d1
	bra.b	.copyunpacked

; %00 or %01
.notpacked
	moveq	#9,d1
	add.w	d2,d1
	addq.w	#2,d2
	move.w	d2,d3

.copyunpacked
	bsr.b	.getbits		; get offset (d2)
;.copy	subq.w	#1,a2
;	move.b	(a2,d2.w),(a2)
;	dbf	d3,.copy

; optimised version of the code above
	subq.w	#1,d2
.copy	move.b	(a2,d2.w),-(a2)
	dbf	d3,.copy

.next	cmp.l	a2,a1
	blt.b	.loop
	rts

.nextlong
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#$10,ccr
	roxr.l	#1,d0
	rts

; d1.w: number of bits to get
; ----
; d2.l: bit stream

.getbits
	subq.w	#1,d1
	clr.w	d2
.getbit	lsr.l	#1,d0
	bne.b	.nonew
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#$10,ccr
	roxr.l	#1,d0
.nonew	addx.l	d2,d2
	dbf	d1,.getbit
	rts



_tags
;		dc.l	WHDLTAG_MONITOR_GET
;_mon		dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
_control_mode		dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
		dc.l	0
		dc.l	0
spaceemu:
	dc.l	0
command
	dc.l	0