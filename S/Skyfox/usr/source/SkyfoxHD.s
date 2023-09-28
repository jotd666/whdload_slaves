;*---------------------------------------------------------------------------
;  :Modul.	kick13.asm
;  :Contents.	kickstart 1.3 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick13.asm 1.2 2001/09/20 19:46:12 wepl Exp wepl $
;  :History.	19.10.99 started
;		20.09.01 ready for JOTD ;)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/graphics.i

	IFD BARFLY
	OUTPUT	"Skyfox.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $0000
NUMDRIVES	= 1
WPDRIVES	= %1111

DISKSONBOOT
;HDINIT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
;SETPATCH
; $1DADA: jsr protect

;============================================================================

KICKSIZE	= $40000		;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	11			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

_name		dc.b	"Skyfox",0
_copy		dc.b	"1985 Electronic Arts",0
_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version 1.0 "
		INCBIN	"T:date"
		dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

		move.l	a0,a2

	;get/set tags
;		lea	(_tag,pc),a0
;		jsr	(resload_Control,a2)

		move.l	#WCPUF_Exp_WT,d0
		move.l	#WCPUF_Exp,d1
	;	jsr	(resload_SetCPU,a2)
		move.l	a2,a0

	;initialize kickstart and environment
		bra	_boot

_bootblock:
	movem.l	a0-a2/a6/d0-d1,-(A7)

	bsr	_patch_trackdisk

	lea	_pl_bootblock(pc),a0
	move.l	a4,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,a0-a2/d0-d1
	jsr	($C,a4)
	movem.l	a0-a2/d0-d1,-(A7)
	move.l	a0,a1
	lea	_pl_boot(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,a0-a2/a6/d0-d1
	moveq.l	#0,D5
	moveq.l	#0,D7
	moveq.l	#0,D0
	rts


_protect:
	lsl.l	#2,D1
	move.l	D1,A1
	movem.l	D0-D1/A0-A2,-(A7)
	cmp.w	#$4EB9,$F0(A1)
	bne.b	.skip_protect
	pea	_emulate_protection(pc)
	move.l	(A7)+,$F2(A1)
.skip_protect
	cmp.l	#$48E7C000,$3C(A1)
	bne.b	.skip_delay
	move.w	#$4E75,$3C(A1)
.skip_delay
	movem.l	(A7)+,D0-D1/A0-A2
	bsr	_flushcache
	jmp	(A1)



_emulate_protection:
	clr.l	($10,A0)
	move.w	#$1,($14,A0)

	move.l	#$544aca15,(A1)+
	move.l	#$2a4b0573,(A1)+
	move.l	#$54949bbf,(A1)+
	move.l	#$a92ba626,(A1)+
	move.l	#$5255dd15,(A1)+
	move.l	#$a4a92b72,(A1)+
	move.l	#$4950c7bd,(A1)+
	move.l	#$92a31e22,(A1)+
	move.l	#$2544ad1d,(A1)+
	move.l	#$4a8bcb63,(A1)+
	move.l	#$9515079e,(A1)+
	move.l	#$2a289e65,(A1)+
	move.l	#$5453ad93,(A1)+
	move.l	#$a8a5ca7e,(A1)+
	move.l	#$514905a5,(A1)+
	move.l	#$a2909a12,(A1)+
	move.l	#$2295de7d,(A1)+
	move.l	#$45292da3,(A1)+
	move.l	#$8a50ca1e,(A1)+
	move.l	#$14a30565,(A1)+

	moveq	#0,D0
	rts

; --------------------------------------------------------------

_pl_bootblock:
	PL_START
	PL_W	$9C,$4E75	; avoid green screen + pause
	PL_END

_pl_protect:
	PL_START

	; remove protection

;;	PL_PS	$248,_emulate_protection


	PL_END
	
_pl_boot:
	PL_START

	; avoid long pause

	PL_W	$D4-$98,$4E75

	; decryption fix (thanks Marble Madness Derek's patch)

	PL_L	$13C0,$2F3C00FC
	PL_L	$13C4,$00004E71
	PL_L	$13C8,$4E714E71
	PL_W	$13CC,$4E71

	PL_L	$13FC,$2F3C00FC
	PL_L	$1400,$00004E71

	PL_L	$1434,$2F3C00FC
	PL_L	$1438,$00004E71

	PL_L	$1452,$2F3C00FC
	PL_L	$1456,$00004E71

	PL_L	$1468,$2F3C00FC
	PL_L	$146C,$00004E71

	; patch segment launcher

	PL_PS	$112C,_protect

	PL_END


; patches trackdisk so the game believes that track 0 head 1
; is unreadable: protection is there -> check it more thouroughfully
; (else track check is not even called)

_patch_trackdisk
	movem.l	D0-A6,-(A7)
	lea	_trackdisk_device(pc),A0
	tst.l	(A0)
	bne.b	.out		; already patched
	lea	_trdname(pc),A0

	move.l	$4.W,A6

	lea	-$30(A7),A7
	move.l	A7,A1
	moveq	#0,D0
	moveq	#0,D1
	jsr	_LVOOpenDevice(A6)
	
	lea	_trackdisk_device(pc),A1
	move.l	IO_DEVICE(A7),(A1)		; save trackdisk device pointer

	lea	$30(A7),A7

	move.l	$4.W,A0
	add.w	#_LVODoIO+2,a0
	lea	_doio_save(pc),a1
	move.l	(a0),(a1)
	lea	_doio(pc),a1
	move.l	a1,(a0)
	move.l	$4.W,A0
	add.w	#_LVOSendIO+2,a0
	lea	_sendio_save(pc),a1
	move.l	(a0),(a1)
	lea	_sendio(pc),a1
	move.l	a1,(a0)

.out
	movem.l	(A7)+,D0-A6

	rts

_doio:
	cmp.l	#$1600,$2C(a1)
	beq.b	.error			; report error on track 1 (protection)
	move.l	_doio_save(pc),-(A7)
	rts
.error
	moveq	#$15,D0
	rts

_sendio:
	cmp.l	#$1600,$2C(a1)
	beq.b	.error			; report error on track 1 (protection)
	move.l	_sendio_save(pc),-(A7)
	rts
.error
	moveq	#$15,D0
	rts


_trackdisk_device:
	dc.l	0
_doio_save:
	dc.l	0
_sendio_save:
	dc.l	0

_trdname:
	dc.b	"trackdisk.device",0
	even

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

	END

