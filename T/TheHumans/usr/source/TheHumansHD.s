;*---------------------------------------------------------------------------
;  :Program.	TheHumans.asm
;  :Contents.	Slave for "The Humans" from Imagitec Design
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	14.03.2001 - german version supported
;		01.04.2001 - english version supported
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Asm-One 1.44
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i


	IFD BARFLY
	OUTPUT	TheHumans.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER

	DOSCMD	"WDate  >T:date"

	ENDC


;cannot set this flag because game uses some stupid address mask
;(like in Midwinter 2 or Pinball Fantasies AGA/CD³²)
;some patching would be necessary, maybe one day...

;USE_FASTMEM

;======================================================================

_base
		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		IFD	USE_FASTMEM
		dc.l	$80000		;ws_BaseMemSize
		ELSE
		dc.l	$100000
		ENDC
		dc.l	0			;ws_ExecInstall
		dc.w	start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = '*'
_expmem	
	IFD	USE_FASTMEM	
	dc.l	$80000			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.6-B"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_name		dc.b	"The Humans / Human Race : Jurassic Levels",0
_copy		dc.b	"1992 Imagitec Design",0
_info		dc.b	"adapted by Mr.Larmer & JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	-1
		dc.b	"Greetings to Helmut Motzkau",10
		dc.b	"Carlo Pirri",0


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

		even

;======================================================================
start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	move.l	a0,a2
	;get tags
	lea	(tag,pc),a0
	jsr	(resload_Control,a2)

	lea	_expbase(pc),a0
	IFD	USE_FASTMEM
	move.l	_expmem(pc),(a0)
	ELSE
	move.l	#$80000,(a0)
	ENDC

	lea	$7FFF0,a7

	lea	$2000.w,a0
	move.l	#-2,(a0)
	move.l	a0,$DFF080

	lea	$200.w,a0
	move.l	#$400,d0
	move.l	#$400,d1
	moveq	#1,d2
	bsr.w	_LoadDisk

	lea	$200.w,a0
	move.l	#$400,d0
	jsr	resload_CRC16(a2)
	move.l	d0,d3

	lea	$200.w,a0
	move.l	#$1600,d0
	move.l	#$1600,d1
	moveq	#1,d2
	bsr.w	_LoadDisk

	move.l	d3,d0

	cmp.w	#$072D,d0
	beq	english_v1	; and Jurassic Levels english
	cmp.w	#$EAB5,d0
	beq.b	german
	cmp.w	#$95FE,d0
	beq	french_v1
	cmp.w	#$6A3D,d0
	beq	english_v2	; version from Xavier

	cmp.w	#$6621,d0
	beq.b	german_v2	; Jurassic Levels

	bra	wrong_version

; Ungi version, extra levels

german_v2
	movem.l	a0,-(a7)
	pea	patch_german_v2_part_1(pc)
	move.l	(a7)+,$26A.w
	sub.l	a1,a1
	lea	pl_boot_german_v2_000(pc),a0
	move.l	attnflags(pc),d0
	btst	#AFB_68010,d0
	beq.b	.68k
	lea	pl_boot_german_v2_010(pc),a0
.68k	
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,a0

	bra	boot

german
	movem.l	a0,-(a7)
	pea	patch_german_part_1(pc)
	move.l	(a7)+,$26A.w
	sub.l	a1,a1
	lea	pl_boot_german_000(pc),a0
	move.l	attnflags(pc),d0
	btst	#AFB_68010,d0
	beq.b	.68k
	lea	pl_boot_german_010(pc),a0
.68k	
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,a0
	
	bra	boot

;--------------------------------

english_v1
	movem.l	a0,-(a7)
	pea	patch_english_v1_part_1(pc)
	move.l	(a7)+,$26A.w
	sub.l	a1,a1
	lea	pl_boot_english_000(pc),a0
	move.l	attnflags(pc),d0
	btst	#AFB_68010,d0
	beq.b	.68k
	lea	pl_boot_english_010(pc),a0
.68k	
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,a0

	bra	boot

;--------------------------------

french_v1
	movem.l	a0,-(a7)
	pea	patch_french_v1_part_1(pc)
	move.l	(a7)+,$26A.w
	
	sub.l	a1,a1
	lea	pl_boot_french_000(pc),a0
	move.l	attnflags(pc),d0
	btst	#AFB_68010,d0
	beq.b	.68k
	lea	pl_boot_french_010(pc),a0
.68k	
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,a0

	bra	boot

;--------------------------------

english_v2
	movem.l	a0,-(a7)
	pea	patch_english_v2_part_1(pc)
	move.l	(a7)+,$26A.w
	sub.l	a1,a1
	lea	pl_boot_french_000(pc),a0
	move.l	attnflags(pc),d0
	btst	#AFB_68010,d0
	beq.b	.68k
	lea	pl_boot_french_010(pc),a0
.68k	
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,a0

	bra	boot

;--------------------------------

boot
	move.l	_expbase(pc),d0
	moveq	#1,d1

	jmp	(a0)


wrong_version
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
pl_boot_french_010
pl_boot_german_010
	PL_START
	PL_W	$802,$508F		; fix stack frame format
	PL_NEXT	pl_boot_french_000
	
pl_boot_french_000
pl_boot_german_000
	PL_START

	PL_R	$DB8		; disable Atari ST code

	PL_L	$FCE,$70004E75		; disable disk drive access
	PL_L	$1022,$70004E75
	PL_L	$104C,$70004E75
	PL_L	$108A,$70004E75
	PL_L	$1178,$70004E75
	PL_W	$10DE,$606E

	PL_P	$1348,Load

	PL_P	$1458,Save

	PL_P	$15D4,Format
	PL_PSS	$691A,kbint,2
	PL_END


pl_boot_german_v2_010
pl_boot_english_010
	PL_START
	PL_W	$812,$508F		; fix stack frame format
	PL_NEXT	pl_boot_english_000
	
pl_boot_german_v2_000
pl_boot_english_000
	PL_START

	PL_R	$DC8		; disable Atari ST code

	PL_L	$FDE,$70004E75		; disable disk drive access
	PL_L	$1032,$70004E75
	PL_L	$105C,$70004E75
	PL_L	$109A,$70004E75
	PL_L	$1188,$70004E75
	PL_W	$10EE,$606E

	PL_P	$1358,Load

	PL_P	$1468,Save

	PL_P	$15E4,Format
	PL_END

;--------------------------------

patch_german_v2_part_1
	move.w	#$4E71,$678C.w		; removed one intro
	patch	$67AC,patch_german_v2_part_2
	patchs	$692A,kbint
	bsr	_flushcache
	jmp	$6736.W

;--------------------------------

patch_german_part_1
	patch	$679C,patch_german_part_2
	patchs	$691A,kbint
	bsr	_flushcache
	jmp	$6726.W

;--------------------------------

patch_english_v1_part_1
	move.w	#$4E71,$678C.w		; removed one intro
	patch	$67AC,patch_english_v1_part_2
	patchs	$692A,kbint
	bsr	_flushcache
	jmp	$6736.W

;--------------------------------

patch_french_v1_part_1
	patchs	$691A,kbint
	patch	$679C,patch_french_v1_part_2
	bsr	_flushcache
	jmp	$6726.W

;--------------------------------

patch_english_v2_part_1
	patchs	$692A,kbint
	patch	$679C,patch_english_v1_part_2
	bsr	_flushcache
	jmp	$6726.W

	
;--------------------------------

patch_german_part_2

	move.l	(a7),a1
	lea	pl_german(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	lea	$6A64.W,a0
	rts				; go to $80000

;--------------------------------

patch_english_v1_part_2
	move.l	(a7),a1
	move.l	#$3D7C0001,d0
	lea	pl_english(pc),a0
	cmp.l	$598(a1),d0
	beq.b	.patch
	lea	pl_english_jl(pc),a0
	cmp.l	$59C(a1),d0
	beq.b	.patch
	bra	wrong_version
.patch
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	lea	$6A74.W,a0
	rts				; go to $80000

;--------------------------------

patch_german_v2_part_2
	move.l	(a7),a1
	lea	pl_german_v2(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	lea	$6A74.W,a0
	rts				; go to $80000

;--------------------------------

patch_french_v1_part_2
	move.l	(a7),a1
	lea	pl_french_v1(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	lea	$6A64.W,a0
	rts				; go to $80000

pl_german	
	PL_START
	PL_W	$3DE,$7000		; disable manual protection

	PL_L	$3E2,$72204E75	; remove stupid randomize proc
				; which made access fault

	PL_PS	$598,Copper

	PL_W	$3F00,$4E71
	PL_PS	$3F02,change_disk_german
	PL_B	$3F08,$60		; skip wait for joystick
	PL_END

pl_german_v2
	PL_START
	PL_W	$3E2,$7000		; disable manual protection

	PL_L	$3E6,$72204E75	; remove stupid randomize proc
					; which made access fault

	PL_PS	$59C,Copper

	PL_W	$3FAA,$4E71
	PL_PS	$3FAC,change_disk_german_v2
	PL_B	$3FB2,$60		; skip wait for joystick
	PL_END

pl_english
	PL_START
	PL_W	$3DE,$7000		; disable manual protection

	PL_L	$3E2,$72204E75	; remove stupid randomize proc
				; which made access fault
	PL_PS	$598,Copper

	PL_W	$3F7A,$4E71
	PL_PS	$3F7C,change_disk_english
	PL_B	$3F82,$60		; skip wait for joystick
	PL_END

pl_english_jl
	PL_START
	PL_W	$3DE,$7000		; disable manual protection

	PL_L	$3E2,$72204E75	; remove stupid randomize proc
				; which made access fault
	PL_PS	$59C,Copper

	PL_W	$3F7A+$38,$4E71
	PL_PS	$3F7C+$38,change_disk_english_jl
	PL_B	$3F82+$38,$60		; skip wait for joystick
	PL_END

pl_french_v1
	PL_START
	PL_W	$3DE,$7000		; disable manual protection

	PL_L	$3E2,$72204E75	; remove stupid randomize proc
				; which made access fault
	PL_PS	$598,Copper

	PL_W	$3F4C,$4E71
	PL_PS	$3F4E,change_disk_french
	PL_B	$3F54,$60		; skip wait for joystick
	PL_END

;--------------------------------

kbint
	lea	$DFF000,A6	; stolen
	movem.l	D0,-(a7)
	MOVE.B	$BFEC01,D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here
	cmp.b	_keyexit(pc),d0
	beq.b	quit
	; do NOT acknowledge keyboard, or keyboard presses won't work in the game
.nokey
	movem.l	(a7)+,d0
	rts
	

quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts	
Copper:
	move.l	#-2,(a1)		; set end of copperlist
	move.w	#1,$88(a6)
	rts

CHANGE_DISK:MACRO
	movem.l	a0-a1,-(a7)
	lea	DiskNr(pc),a0
	move.l	_expbase(pc),a1
	add.l	#\1,a1
	move.w	(a1),(a0)
	addq.w	#1,(a0)
	movem.l	(a7)+,a0-a1
	rts
	ENDM

;--------------------------------

change_disk_german_v2
	CHANGE_DISK	$3EDC

;--------------------------------

change_disk_german
	CHANGE_DISK	$3E32


;--------------------------------

change_disk_english
	CHANGE_DISK	$3EAC

;--------------------------------

change_disk_english_jl
	CHANGE_DISK	$3EAC+$38

;--------------------------------

change_disk_french
	CHANGE_DISK	$3E7E

;--------------------------------

Load
	movem.l	d0-d2/a0-a1,-(a7)

	moveq	#0,d1
	move.w	$38(a6),d1		; track nr
	mulu	#$1600,d1
	mulu	#$200,d0		; block nr * $200
	add.l	d1,d0
	tst.w	$2C(a6)
	beq.b	.skip2
	add.l	#$DC000/2,d0
.skip2
	move.l	#$200,d1

	lea	DiskNr(pc),a1
	moveq	#0,d2
	move.w	(a1),d2

	bsr.b	_LoadDisk

	movem.l	(a7)+,d0-d2/a0-a1
	moveq	#0,d0
	rts

DiskNr		dc.w	1

;--------------------------------

; a0 - source ; d0 - block as in load proc
Save

; d0 - track ; d1 - blocks in track ; d2 - tracks ; d3 - ??
Format
	moveq	#0,d0
	rts

;--------------------------------

_resload	dc.l	0		;address of resident loader
_expbase	dc.l	-1

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	rts

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts
tag		dc.l	WHDLTAG_ATTNFLAGS_GET
attnflags	dc.l	0
		dc.l	0

;======================================================================

	END
