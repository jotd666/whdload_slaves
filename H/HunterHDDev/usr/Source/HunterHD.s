; 11.11.2022, jotd
; - fixed patch offset which crashed in intro
; - relocation to fastmem for good FPS
;
; 07.10.2018, stingray
; - code optimised, quitkey SMC removed
; - default quitkey changed to F10
;
; 08.10.2018:
; - code converted to use patch lists (English version only
;   for now)
; - movep instruction in decrypter removed and emulated
; - code a lot more optimised
;
; 09.10.2018:
; - SMC which caused the graphics bugs on fast machines fixed
;
; 10.10.2018:
; - old loader patch by Harry completely redone, much shorter and easier
;   to maintain code used now
; - German and French version now adapted too
; - music and sample players now fixed using patch lists too
; - save disk is now created if it doesn't exist

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

; relocates program to another memory location
RELOC_ENABLED = 1
; uses chipmem for easier debug (addresses are shifted by $80000)
;CHIP_ONLY = 1

EXPMEMSIZE = $80000
PROGRAM_START = $800
PROGRAM_SIZE = $11800

	IFD	CHIP_ONLY
CHIPMEMSIZE = $80000+EXPMEMSIZE
FASTMEMSIZE = 0
	ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = EXPMEMSIZE
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
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

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

HEADER	SLAVE_HEADER		; ws_Security + ws_ID
	dc.w	17		; ws_Version
	dc.w	FLAGS		; ws_Flags
	dc.l	CHIPMEMSIZE		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	IFD	DEBUG
	dc.w	.dir-HEADER	; ws_CurrentDir
	ELSE
	dc.w	0		; _data-HEADER		; ws_CurrentDir
	ENDC
	DC.W	0		; ws_DontCache
	DC.B	0		; ws_keydebug
	dc.b	QUITKEY		; ws_keyexit
_expmem
	dc.l	FASTMEMSIZE		; ws_ExpMem
	dc.w	_name-HEADER	; ws_name
	dc.w	_copy-HEADER	; ws_copy
	dc.w	_info-HEADER	; ws_info
	dc.w	0                       ;ws_kickname
	dc.l	0                       ;ws_kicksize
	dc.w	0                       ;ws_kickcrc
	dc.w	_config-HEADER		;ws_config

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Hunter",0
	ENDC
	
_config
    ;dc.b    "C1:B:infinite ammo;"
    dc.b	0

	
_name	DC.B	"Hunter",0
_copy	DC.B	"1991 Activision",0
_info	dc.b	"adapted by Harry, StingRay/[S]carab^Scoopex & JOTD",10,10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version "
	DECL_VERSION
	dc.b	0
	dc.b	"$VER: Hunter "
	DECL_VERSION
	dc.b	0

	CNOP	0,2
_reloc_base
	dc.l	PROGRAM_START

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	resload(pc),a2


	IFD	RELOC_ENABLED
	IFD	CHIP_ONLY
	lea	_expmem(pc),a0
	move.l	#$80000,(a0)
	ENDC
	
	lea		_reloc_base(pc),a0
	move.l	_expmem(pc),d0
	add.l	d0,(a0)
	
	; set CPU and cache options
	move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	resload_SetCPU(a2)

	ENDC

; load boot/decryption code
	move.l	#$400,d0
	move.l	#$800,d1
	lea	$7E800,a0
	move.l	a0,a5
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)

; load encrypted main file
	move.l	#$2800,d0
	move.l	#$11800,d1
	lea	PROGRAM_START,a0
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)


; decrypt it
	movem.l	$5E(a5),d0-a7
	add.w	#$600,a0		; copy exception vectors to 8+$600
.copy	move.l	(a1)+,(a0)+
	dbf	d0,.copy
	sub.w	#$600,a0
	bsr	Decrypt

	movem.l	$128(a5),d0-a6
	move.l	a3,$10E(a5)
	movem.l	d3-a6,$6A(a5)
	bsr	Decrypt

	move.l	#$10000,d0
	lea	PROGRAM_START,a0
	move.l	resload(pc),a2
	jsr	resload_CRC16(a2)
	
	lea		_reloc_de(pc),a3
	lea	PLGAME_DE(pc),a4
	cmp.w	#$D2F2,d0		; German
	beq.b	.ok
	lea		_reloc_fr(pc),a3
	lea	PLGAME_FR(pc),a4
	cmp.w	#$F64F,d0		; French
	beq.b	.ok
	lea		_reloc_en(pc),a3
	lea	PLGAME_EN(pc),a4
	cmp.w	#$B506,d0		; English
	bne.w	Unsupported
.ok

	IFD		RELOC_ENABLED
	
	; copy program

	move.l	#PROGRAM_SIZE/4,d0
	lea		PROGRAM_START,a0
	move.l	_reloc_base(pc),A1
.copyr
	move.l	(a0)+,(a1)+
	subq.l	#1,d0
	bne.b	.copyr
	
	; load reloc table

	move.l	a3,a0		; name of reloc binary table
	lea		PROGRAM_START+PROGRAM_SIZE,a1		; use program end
	move.l	a1,a3	; save load location
	jsr		resload_LoadFileDecrunch(a2)

	; relocate
	move.l	_reloc_base(pc),a0
	lea		(-PROGRAM_START,a0),a1	; reloc base -$800
	move.l	a1,d1
	move.l	a3,a1	; reloc table location
.reloc
	move.l	(a1)+,d0
	beq.b	.end
	add.l	d1,(a0,d0.l)
	bra.b	.reloc
.end

	IFD	UNRELOC_ENABLED
	; unrelocate: cancel relocation of some data that
	; needs to be in chipmem
	move.l	a3,a1	; load location
	move.l	a5,a0	; unreloc binary offset filename (disabled in hunter)
	jsr		resload_LoadFileDecrunch(a2)
	
	; relocate
	move.l	_reloc_base(pc),a0
	lea		(-PROGRAM_START,a0),a1	; reloc base -$1000
	move.l	a1,d1
	move.l	a3,a1	; load location
.unreloc
	move.l	(a1)+,d0
	beq.b	.endu
	; correct offsets
	sub.l	d1,(a0,d0.l)
	bra.b	.unreloc
.endu
	ENDC
	
	; debug: add MMU protect on old program $ -> $ for v1
	; some code is copied by the game at the end of
	; chipmem ($1135C). Too complex/not worth fixing that
	; en: w 0 $800 $11350-$800
	; fr: w 0 $800 $11100
	ENDC
	

; check if save disk exists and create it if needed
	lea	SaveDiskName(pc),a0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	bne.b	.savedisk_exists
	lea	SaveDiskName(pc),a0
	lea	$1a000,a1
	move.l	#80*512*10,d0
	jsr	resload_SaveFile(a2)
.savedisk_exists


	move.l	a4,a0
	move.l	_reloc_base(pc),-(a7)
	move.l	(a7),a1
	jmp	resload_Patch(a2)


PLGAME_DE
	PL_START
	PL_P	$f592,Copylock
	PL_R	$10790			; disable ext. mem check
	PL_PS	$abaa,CheckQuit


; V1.30, stingray 
	PL_PS	$75da,SMC

	PL_P	$108b2,Load
	PL_P	$101b0,setdisk2
	PL_P	$101d6,setdisk1
	PL_PS	$ff92,.setdisk2_2

	PL_PS	$c5ec,emulate_dbf

; V2.0 jotd
	PL_B	$1ed8-PROGRAM_START,$60	; disable program loading address check
	PL_PS	$0d01a-PROGRAM_START,.unreloc_program_end_de

	PL_END

.unreloc_program_end_de
	lea	$11954,a0		; end of program, start of chipmem data
	moveq	#0,d0
	rts

.setdisk2_2
	bsr	setdisk2
	move.l	_reloc_base(pc),a0
	move.l	($7be6,a0),a0
	rts


Copylock
	move.l	a0,-(a7)
	move.l	_reloc_base(pc),a0
	move.l	#$cc0c62c0,($16a,a0)
	move.l	(a7)+,a0
	rts

PLGAME_EN
	PL_START
	;;PL_PS	$01ec2-$800,set_stack
	
	PL_P	$efea,.Copylock_en
	PL_R	$101a8			; disable ext. mem check
	PL_PS	$a9da,CheckQuit


; V1.30, stingray 
	PL_PS	$751e,SMC	

	PL_P	$10ab8-PROGRAM_START,Load
	PL_P	$fbb6,setdisk2
	PL_P	$fbdc,setdisk1
	PL_PS	$f9c2,.setdisk2_2

; V.20, jotd
	PL_B	$1ed8-PROGRAM_START,$60	; disable program loading address check
	PL_PS	$c85e-PROGRAM_START,emulate_dbf	; previous delay fix was wrong
	; ensure that data block is in chipmem even if program is relocated
	PL_PS	$ca8a-PROGRAM_START,.unreloc_program_end_en
	PL_END

	
.unreloc_program_end_en
	lea	$1135c,a0		; end of program, start of chipmem data
	moveq	#0,d0
	rts
	
.Copylock_en
	move.l	a0,-(a7)
	move.l	_reloc_base(pc),a0
	move.l	#$7b8669f8,($16a,a0)
	move.l	(a7)+,a0
	rts


.setdisk2_2
	bsr.b	setdisk2
	move.l	_reloc_base(pc),a0
	move.l	($7b2a,a0),a0
	rts
	
; < D0: value of D0 in line
; .x: DBF D0,x
emulate_dbf
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beamdelay
	move.w	#$FFFF,d0
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
	
setdisk1
	bclr	#5,$9b(a5)
	rts

setdisk2
	bset	#5,$9b(a5)
	rts


PLGAME_FR
	PL_START
	PL_B	$01eda-PROGRAM_START,$60	; disable program loading address check

	PL_P	$f552,Copylock
	PL_R	$10750			; disable ext. mem check
	PL_PS	$ab14,CheckQuit


; V1.30, stingray 
	PL_PS	$75e4,SMC

	PL_P	$10872,Load
	PL_P	$10170,setdisk2
	PL_P	$10196,setdisk1
	PL_PS	$ff52,.setdisk2_2

	PL_PS	$cdae-PROGRAM_START,emulate_dbf
	
	PL_PS	$0cfda-PROGRAM_START,.unreloc_program_end_fr
	
	PL_END

.setdisk2_2
	bsr.w	setdisk2
	move.l	_reloc_base(pc),a0
	move.l	($7bf0,a0),a0
	rts


.unreloc_program_end_fr
	lea	$11914,a0		; end of program, start of chipmem data
	moveq	#0,d0
	rts
	
; d0.w: track
; d1.w: # of tracks
; d2.l: file size in bytes
; a0.l: destination

Load:
	movem.l	d0-a6,-(a7)
	move.l	a0,a4

	cmp.w	#80,d0
	blt.b	.ok
	subq.w	#1,d0

.ok	mulu.w	#512*10,d0
	move.l	d2,d1

	moveq	#1,d2
	btst	#5,$9b(a5)
	beq.b	.nodisk2
	moveq	#2,d2
.nodisk2
	move.l	resload(pc),a2
	lea	resload_DiskLoad(a2),a3
	tst.b	$1622(a5)
	bne.b	.nosave

	exg	d0,d1
	move.l	a0,a1
	lea	SaveDiskName(pc),a0
	lea	resload_SaveFileOffset(a2),a3
.nosave

	jsr	(a3)

	subq.w	#1,d2			; only if current disk is game disk
	bne.b	.skip
	move.w	$1602(a5),d0		; file number
	move.l	a4,a1			: destination
	cmp.w	#4,d0
	bne.b	.nosound
	bsr.b	FixSamplePlayer
.nosound

	cmp.w	#3,d0
	bne.b	.nomusic
	bsr.b	FixMusicPlayer
.nomusic

.skip
	movem.l	(a7)+,d0-a6
	moveq	#0,d0
	rts

	

SMC	move.l	a0,-(a7)
	move.l	resload(pc),a0
	jsr	resload_FlushCache(a0)
	move.l	(a7)+,a0

	move.l	$48(a5),d3
	clr.w	d2
	rts


FixSamplePlayer
	movem.l	d0-d1/a0-a1,-(a7)
	lea	PLSAMPLEPLAYER(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a1
	rts

FixMusicPlayer
	movem.l	d0-d1/a0-a1,-(a7)
	lea	PLMUSICPLAYER(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a1
	rts
	

PLMUSICPLAYER
	PL_START
	PL_PSS	$2312a-$22EDA,.fix3,2
	PL_PSS	$55c,.fix1,4
	PL_PS	$58c,.fix2
	PL_END

.fix1	moveq	#5,d0
	bra.b	FixDMAWait

.fix2	moveq	#5,d0
	bra.b	FixDMAWait	

.fix3
	MOVE.W	14(A0,D2.W),_custom+dmacon
	move.l	D0,-(a7)
	moveq	#7,d0
	bsr.b	FixDMAWait
	move.l	(a7)+,d0
	rts
	
PLSAMPLEPLAYER
	PL_START
	PL_PSS	$21a,.fix1,4
	PL_PS	$22c,.fix2
	PL_END
	
.fix1	moveq	#6,d0
	bra.b	FixDMAWait


.fix2	moveq	#1,d0


FixDMAWait
	move.w	d1,-(a7)
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	dbf	d0,.loop
	move.w	(a7)+,d1
	rts


Decrypt	clr.w	d6
	move.b	-(a6),d6
	add.b	d6,d6
	move.l	(a5,d6.w),d6
	movem.l	(a3),d0/d1
	eor.l	d4,d0
	eor.l	d5,d1
	and.l	#15,d3
	add.w	d3,d3
	move.l	d3,a2
	add.w	d3,d3
	add.l	(a4,d3.w),d6
	eor.l	d6,d1
	eor.w	d7,d1
	swap	d6
	eor.l	d6,d0

	add.w	#$600,a2

	;movep.l	8(a2),d6

	move.b	8+0(a2),d6
	rol.l	#8,d6
	move.b	8+2(a2),d6
	rol.l	#8,d6
	move.b	8+4(a2),d6
	rol.l	#8,d6
	move.b	8+6(a2),d6

	sub.w	#$600,a2

	eor.w	d6,d0
	add.l	a0,d4
	add.l	a1,d4
	add.l	a2,d4
	add.l	a3,d4
	add.l	a4,d4
	add.l	a5,d4
	add.l	a6,d4
	subq.w	#1,d5
	bgt.b	.skip
	move.l	d5,d6
	swap	d6
	add.w	d6,a6
	move.w	d6,d5

.skip	move.l	d0,(a3)+
	eor.l	d1,d2
	move.l	a3,d3
	add.l	d0,d2
	movem.l	d3-a6,$6A(a5)
	move.l	d1,(a3)+
	dbf	d7,Decrypt
	rts





resload		dc.l	0

CheckQuit
	movem.l	d0/d1,-(a7)

	move.l	d0,-(a7)
	moveq	#3-1,d0
	bsr	FixDMAWait
	move.l	(a7)+,d0


	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	QUIT
	movem.l	(a7)+,d0/d1
	rts

	
Unsupported
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

QUIT	pea	(TDREASON_OK).w

EXIT	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
	
_reloc_en
	dc.b	"hunter_en.reloc",0
_reloc_de
	dc.b	"hunter_de.reloc",0
_reloc_fr
	dc.b	"hunter_fr.reloc",0
SaveDiskName	dc.b	"disk.2",0

	