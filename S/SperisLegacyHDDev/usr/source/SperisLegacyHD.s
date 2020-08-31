;*---------------------------------------------------------------------------
;  :Program.	SperisLegacyHD.asm
;  :Contents.	Slave for "SperisLegacy"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: SperisLegacyHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"SperisLegacy.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $80000
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
DEBUG
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH

;============================================================================

KICKSIZE	= $80000			;40.068
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	15			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv|WHDLF_Examine	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

	CNOP 0,4
_assign1
	dc.b	8,"speris-1",0
	CNOP 0,4
_assign2
	dc.b	8,"speris-2",0
	CNOP 0,4
_assign3
	dc.b	8,"speris-3",0
	CNOP 0,4
_assign4
	dc.b	8,"speris-4",0

_name		dc.b	"The Speris Legacy",0
_copy		dc.b	"1996 Binary Emotions",0
_info		dc.b	"Installed by JOTD",10,10
		dc.b	"Thanks to Tony Aksnes for disk images",10,10		
		dc.b	"Version 1.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_data:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"speris.exe",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	;initialize kickstart and environment
		bra	_boot

_bootdos
	clr.l	$0.W

	move.l	(_resload),a2		;A2 = resload

	;enable cache
	;	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	;	move.l	#WCPUF_All,d1
	;	jsr	(resload_SetCPU,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign4(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found

	;patch here
		lea	_program(pc),a0
		jsr	resload_GetFileSize(a2)
		cmp.l	#1660796,d0
		beq.b	.cd32
		cmp.l	#864,d0
		beq.b	.floppy

		; unsupported "speris.exe" file
		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

.floppy
		bsr	_patchexe
		bra.b	.cont
.cd32
		move.l	A2,-(A7)
		move.l	d7,a2
		add.l	a2,a2
		add.l	a2,a2
		bsr	_patchmain
		move.l	(A7)+,a2
.cont
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
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_end
		pea	_program(pc)
		pea	205			; file not found
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts



_patchexe:
	movem.l	d0-a6,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	move.l	d7,A0
	move.l	A0,A1
	add.l	#800,A1
	lea	.bytes(pc),A2
	moveq.l	#4,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip
	move.w	#$4EF9,(A0)+
	pea	_patchmain_and_jmp(pc)
	move.l	(A7)+,(A0)
.skip
	movem.l	(a7)+,d0-a6
	rts
.bytes:
	dc.w	$4EAA,$0020,$6000,$FF78


_patchmain_and_jmp:
	bsr	_patchmain
	jsr	$20(a2)
	bra	_quit

_patchmain:
	movem.l	D0-A6,-(A7)
	move.l	A2,A3

	move.l	A3,A0
	move.l	A0,A1
	add.l	#$20000,A1
	move.l	#$4E7A0801,D0
	move.l	#$70004E71,D1
	bsr	_hexreplacelong

	move.l	A3,A0
	move.l	A0,A1
	add.l	#$20000,A1
	lea	.floppystuff(pc),a2
	moveq.l	#10,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.sk0
	move.w	#$4E75,(A0)
.sk0
	lea	$7000(A3),A0
	move.l	A0,A1
	add.l	#$20000,A1
	lea	.floppystuff_2(pc),a2
	moveq.l	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.sk1
	move.l	#$70FE4E75,(A0)
.sk1
	move.l	A3,A0
	move.l	A0,A1
	add.l	#$20000,A1

	lea	.decrunch(pc),a2
	moveq.l	#6,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.sk2
	move.w	#$4EF9,(A0)+
	pea	_decrunch_and_patch(pc)
	move.l	(a7)+,(A0)
.sk2
	move.l	A3,A0
	add.l	#$20000,A0
	lea	$3000(A0),A1
	lea	.floppystuff_3(pc),a2
	moveq.l	#10,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.sk3

	; called in "FORMAT" menu

	move.w	#$4E75,2(A0)
.sk3

	bsr	_flushcache
	movem.l	(A7)+,D0-A6
	rts

.floppystuff_3:
	dc.l	$908048E7,$FFFE615A
	dc.w	$6178
.floppystuff_2:
	dc.l	$48E7FFFE,$610000AE
.floppystuff:
	dc.l	$48E7C004,$4BF900BF
	dc.w	$D100
.decrunch:
	dc.w	$0C90
	dc.b	"ATN!"

_decrunch_and_patch:
	move.l	A0,A1
	movem.l	D1/A0-A2,-(A7)
	MOVE.L	_resload(PC),A2
	JSR	(resload_Decrunch,a2)
	movem.l	(A7)+,D1/A0-A2

	; file check

	move.l	A1,-(A7)

	cmp.l	#$9D202239,$1230(a0)	; floppy
	beq.b	.crk
	cmp.l	#$9D702239,$1236(a0)	; cd32
	bne.b	.nocrk
	move.w	#$23C0,$1238(a0)
	move.w	#$B080,$123E(a0)
	bra.b	.nocrk
.crk
	move.w	#$23C0,$1232(a0)
	move.w	#$B080,$1238(a0)
.nocrk
	move.l	A0,A1
	add.l	#$41000,A1
	cmp.l	#$48E7FFFE,$FA0(A1)
	beq.b	.floppy
	subq.l	#4,a1				; try file from CD32 version
	cmp.l	#$48E7FFFE,$FA0(A1)
	bne.b	.nofloppy
	bra.b	.floppy2			; only 2nd patch is performed

.floppy
	move.l	#$70FE4E75,$F4C(A1)
.floppy2
	move.l	#$70FE4E75,$FA0(A1)
.nofloppy
	move.l	(A7)+,A1
	bsr	_flushcache
	rts


;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

_hexsearch:
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


_hexreplacelong:
	movem.l	A0-A1/D0-D1,-(A7)
.srch
	cmp.l	(A0),D0
	beq.b	.found
.next
	addq.l	#2,A0
	cmp.l	A1,A0
	bcc.b	.exit
	bra.b	.srch
.found
	move.l	D1,(A0)+
	bra	.next
.exit
	movem.l	(A7)+,A0-A1/D0-D1
	rts

;============================================================================

	IFEQ	KICKSIZE-$40000
	INCLUDE	kick13.s
	ELSE
	INCLUDE	kick31.s
	ENDC

;============================================================================

	END
