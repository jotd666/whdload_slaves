;*---------------------------------------------------------------------------
;  :Program.	CartonRougeHD.asm
;  :Contents.	Slave for "CartonRouge"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: CartonRougeHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"AnstossAGA.slave"
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
FASTMEMSIZE	= $100000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
;DEBUG
HDINIT
;HRTMON
IOCACHE		= 10000	; german saves are big
;MEMFREE	= $200
;NEEDFPU
SETPATCH
INITAGA
HD_Cyls = 10000		; game believes it runs from HD
BOOTDOS
STACKSIZE = 8000
CACHE
CBDOSLOADSEG

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ReqAGA
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

slv_config
	dc.b    "C2:B:no keyboard changes;"
	dc.b	0

d_assign1
	dc.b	"ANSTOSS1",0
d_assign2
	dc.b	"ANSTOSS2",0
d_assign3
	dc.b	"ANSTOSS3",0
d_assign4
	dc.b	"ANSTOSS4",0
d_assign5
	dc.b	"ANSTOSS5",0
d_assign6:
	dc.b	"ANSTOSS6",0
d_score:
	dc.b	"spielstandanstoss",0
		
gb_assign1
	dc.b	"OTB1",0
gb_assign2
	dc.b	"OTB2",0
gb_assign3
	dc.b	"OTB3",0
gb_assign4
	dc.b	"OTB4",0
gb_assign5
	dc.b	"OTB5",0
gb_assign6:
	dc.b	"OTB6",0
gb_score:
    dc.b    "scorediskotb",0


f_assign1
	dc.b	"c-r1",0
f_assign2
	dc.b	"c-r2",0
f_assign3
	dc.b	"c-r3",0
f_assign4
	dc.b	"c-r4",0
f_assign5
	dc.b	"c-r5",0
f_assign6:
	dc.b	"c-r6",0
f_score:
	dc.b	"scorediskotb",0
	
savedir
	dc.b	"save",0

_assign7:
	dc.b	"FONTS",0
_assign8:
	dc.b	"LIBS",0
_assign9:
	dc.b	"ENV",0

_ramname
    dc.b    "RAM:",0
    
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

slv_name		dc.b	"Anstoss/Carton Rouge/On The ball league edition AGA",0
slv_copy		dc.b	"1993 Ascon",0
slv_info		dc.b	"adapted by JOTD",10,10
			dc.b	"Version "
			DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN



setmap
	dc.b	"setmap",0
args		dc.b	"LIBS",10
args_end
	dc.b	0
; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION

		dc.b	0

	EVEN

;============================================================================



CHECK_AND_ASSIGN:MACRO
		lea	.keymap_\1(pc),a0
		move.l	a0,d1
		move.l	#ACCESS_READ,d2
		jsr	_LVOLock(a6)
		move.l	d0,d1
		beq	.out_\1
		jsr	_LVOUnLock(a6)

		lea	.keymaparg_\1(pc),a0
		lea	active_keymap(pc),a1
		move.l	a0,(a1)
        lea _keyboard_type(pc),a1
        move.l  #\2,(a1)
		lea	\1_program(pc),a0
		lea	active_program(pc),a1
		move.l	a0,(a1)		
	;assigns
		lea	\1_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	\1_assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	\1_assign3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	\1_assign4(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	\1_assign5(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	\1_assign6(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	\1_score(pc),a0
		lea	savedir(pc),a1
		bsr	_dos_assign

		bra.b	.out_\1
.keymap_\1
	dc.b	"DEVS:Keymaps/\1",0,0
.keymaparg_\1
	dc.b	"\1",10,0
.keymaparg_end_\1
		even
.out_\1
	ENDM

PATCH_DOSLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
	lea	old_\1(pc),a0
	move.l	2(A1),(A0)
	move.w	#$4EF9,(A1)+	
	pea	new_\1(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
old_\1:
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1

	ENDM

_bootdos
	move.l	(_resload,pc),a2		;A2 = resload

	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

    bsr install_kbint
    
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;patch dos lib: Open
		PATCH_DOSLIB_OFFSET	Open

	;test (and create) hd file flag

		bsr	check_vonplatte

	; assigns

		lea	_assign7(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign8(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign9(pc),a0
		lea _ramname(pc),a1
		bsr	_dos_assign

	;check which version we have and perform the necessary assigns

		CHECK_AND_ASSIGN	gb,0
		CHECK_AND_ASSIGN	f,1
		CHECK_AND_ASSIGN	d,2

		move.l	active_keymap(pc),d0
		bne.b	.ok

		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
.ok


; calling setmap doesn't work: crashes kickemu
;		move.l	active_keymap(pc),a1
;		lea	setmap(pc),a0
;		move.l  keymap_arglen(pc),d0
;		sub.l	a5,a5
;		bsr	_load_exe




	include shared.s
	END
