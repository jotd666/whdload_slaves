;*---------------------------------------------------------------------------
;  :Program.	GunshipHD.asm
;  :Contents.	Slave for "Gunship"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: GunshipHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"Gunship.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

	IFD	CHIPONLY
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
DEBUG
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
CBDOSLOADSEG

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC



DECL_VERSION:MACRO
	dc.b	"1.2"
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
_assign
	dc.b	"Gunship",0

slv_name		dc.b	"Gunship",0
slv_copy		dc.b	"1987-1989 Microprose",0
slv_info		dc.b	"adapted & fixed by JOTD",10
			dc.b	"from Wepl excellent KickStarter 34.005",10,10
			dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"Gunship",0
_args		dc.b	10
_args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN


PATCH_EXE:MACRO
.\1
	lea	pl_\1(pc),a0
	jsr	resload_Patch(a2)
	bra	.out
	ENDM


CMP_EXE:MACRO
	cmp.l	#$\1,$\2(a1)
	beq.b	.\3
	ENDM

; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	
	move.l	_resload(pc),a2

	; now D1 is ptr on seg 0

	lsl.l	#2,d0
	move.l	d0,a0

	move.l	d1,a1
	add.l	#4,a1	; first segment

	cmp.b	#$10,(a0)
	bne	.out
	cmp.b	#'T',9(a0)
	beq.b	.titlmule
	cmp.b	#'G',9(a0)
	beq.b	.gamemule
	cmp.b	#'S',9(a0)
	beq	.scrnmule
	bra	.out
.titlmule
	CMP_EXE	52802202,2F18,titlmule_1489
	CMP_EXE	4EAEFDDE,2F18,titlmule_658
	CMP_EXE	4EAEFDDE,2F1A,titlmule_xavier
	CMP_EXE	243508E4,2F1A,titlmule_german	; also german

	bra	wrong_version

	PATCH_EXE	titlmule_1489
	PATCH_EXE	titlmule_658
	PATCH_EXE	titlmule_xavier
	PATCH_EXE	titlmule_german

.gamemule
	CMP_EXE	4CDF4CFC,2F2A,gamemule_1489	; OK for Xavier version
	CMP_EXE	51CFFFCE,2F2A,gamemule_658
	CMP_EXE	201AD089,2F2A,gamemule_german	; also german

	bra.b	wrong_version

	PATCH_EXE	gamemule_1489
	PATCH_EXE	gamemule_658
	PATCH_EXE	gamemule_german

.scrnmule
	CMP_EXE	7013BE80,5AB0,scrnmule_1489	; OK for Xavier version
	CMP_EXE	4EBA071A,5AB0,scrnmule_658
	CMP_EXE	486C2A50,5AB2,scrnmule_german	; also german

	bra.b	wrong_version

	PATCH_EXE	scrnmule_1489
	PATCH_EXE	scrnmule_658
	PATCH_EXE	scrnmule_german


.out
	rts

wrong_version
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

; password protection in scrnmule
;	CMP.L	D6,D7			;05AAC: BE86
;	BEQ.S	LAB_02A3		;05AAE: 6758 -> BRA
;	MOVEQ	#19,D0			;05AB0: 7013
;	CMP.L	D0,D7			;05AB2: BE80
;	BLE.S	LAB_02A2		;05AB4: 6F0A

_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload


	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_gunship(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)

patch_gunship:
	move.l	d7,a1
	addq.l	#4,a1
	cmp.l	#$48E73002,$1A06(a1)
	bne.b	.nodiskprot
	lea	pl_gunship_658(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

.nodiskprot
	rts

; -------- version 658 --------

pl_gunship_658
	PL_START
	; disk protection
	PL_S	$1A0A,$128
	PL_END

pl_scrnmule_658
	PL_START
	; password protection
	PL_B	$5A6E,$60
	PL_END

pl_titlmule_xavier
	PL_START
	; disk copy protection is not here

	PL_B	$EA,$60		; BRA
	PL_W	$23D2,$601E	; skips disk protection

	; skips the bltbitmap call (was for MPS logo that does not
	; appear anyway in this version!!

	PL_P	$5E0E,bltbitmap	
	PL_END

pl_titlmule_658
	PL_START
	; disk copy protection is not here

	PL_B	$EA,$60		; BRA
	PL_END

pl_gamemule_658
	PL_START
	; lockpick indicates that patch

	PL_W	$8168,$4E71

	; fix access fault

	PL_PS	$826A,avoid_af_game

	PL_END

; -------- version 1489 --------

pl_titlmule_1489
	PL_START
	; removes disk protection

	PL_B	$EA,$60		; BRA
	PL_L	$2e68,$303c86e9	; MOVE    #$86E9,D0
	PL_L	$2e98,$303c86e9	; ""

	PL_L	$2edc,$203c0400 ; MOVE    #$0400,D0
	PL_L	$2ee8,$303c0400 ; ""
	PL_NOP	$2f28,2	; NOP
	PL_L	$2f3e,$3c3c0200 ; MOVE    #$0200,D6
	PL_END

pl_gamemule_1489
	PL_START
	; lockpick indicates that patch

	PL_W	$8180,$4E71

	; fix access fault

	PL_PS	$8282,avoid_af_game

	PL_END

pl_scrnmule_1489
	PL_START

	; remove password protection (Lockpick overlooked that one!
	; fortunately it's always the same old Microprose shit)

	PL_B	$5AAE,$60
	PL_END

; german version
pl_scrnmule_german
	PL_START

	; remove password protection (Lockpick overlooked that one!
	; fortunately it's always the same old Microprose shit)

	PL_B	$05a92,$60
	
	; adding the other crack patches (cracked version) just for safety
	PL_B	$012ec,$60

	PL_END

pl_titlmule_german
	PL_START

	PL_B	$03c0,$60		; BRA
	
	PL_L	$2E74,$303c86e9	; MOVE    #$86E9,D0
	PL_L	$2ea4,$303c86e9	; ""

	PL_L	$2ee8,$203c0400 ; MOVE    #$0400,D0
	PL_L	$2ef4,$303c0400 ; ""
	PL_NOP	$2f34,2	; NOP
	PL_L	$2f4a,$3c3c0200 ; MOVE    #$0200,D6
	PL_END

	PL_END

pl_gamemule_german
	PL_START

	; protection
	PL_B	$009b8,$60
	PL_NOP	$0818c,2
	
	; fix access fault

	PL_PS	$828E,avoid_af_game

	PL_END

bltbitmap
; call BltBitMap: crash/freeze the amiga on return to the OS
; reason: blit is too large (dixit snoop)
; AND not calling it changes nothing to the game graphics!!

;;	jsr	_LVOBltBitMap(a6)
	movem.l	(a7)+,d2-d7/a2/a6
	rts

avoid_af_game:
	MOVEA.L	(A1),A0			;08282: 2051
	and.l	#$0FFFFFFF,d5	; D5 can be = $2000xxxx
	ADDA.L	D5,A0
	BTST	D0,(A0)
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
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

	move.l	a4,a0
	move.l	($44,a7),d0		;stacksize
	sub.l	#5*4,d0			;required for MANX stack check
	movem.l	d0/d7/a2/a6,-(a7)
	move.l	d2,d0			; argument string length
	jsr	(4,a1)
	movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)

	movem.l	(a7)+,d0-a6
	rts

.end
	move.l	a3,-(a7)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
