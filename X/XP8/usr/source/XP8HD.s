;*---------------------------------------------------------------------------
;  :Program.	XP8HD.asm
;  :Contents.	Slave for "XP8"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: XP8HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;CHIP_ONLY

;============================================================================

NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
;DEBUG
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
FORCEPAL
	IFD	AGAVER
INITAGA
	ELSE
NO68020
	ENDC
	
;============================================================================

slv_Version=17
slv_Flags_base	= WHDLF_NoError|WHDLF_EmulPriv|WHDLF_Examine
	IFD	AGAVER
PASSWORD_OFFSET = $050ec
	IFD	CHIP_ONLY
FASTMEMSIZE = $000
CHIP_ALIGN = $20000-$1da40
	ELSE
FASTMEMSIZE = $80000
	ENDC
CHIPMEMSIZE = $200000
slv_Flags = slv_Flags_base|WHDLF_ReqAGA|WHDLF_Req68020
	ELSE
PASSWORD_OFFSET = $133d8 ; ecs
	IFD	CHIP_ONLY
FASTMEMSIZE = $0
CHIPMEMSIZE = $100000
CHIP_ALIGN = $20000-$1D8F0
	ELSE
FASTMEMSIZE = $80000
CHIPMEMSIZE = $80000
	ENDC
	
slv_Flags = slv_Flags_base	
	ENDC
slv_keyexit	= $5D	; num '*'

	include 	whdload/kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"2.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	
	IFD	AGAVER
_assign_1
	dc.b	"xp8di1",0
_assign_2
	dc.b	"xp8di2",0
_assign_3
	dc.b	"xp8di3",0
_assign_4
	dc.b	"xp8di4",0
	ELSE
_assign_1
	dc.b	"xp8df1",0
_assign_2
	dc.b	"xp8df2",0
_assign_3
	dc.b	"xp8df3",0
	ENDC
slv_name:		
		dc.b	"XP8 ("
	IFD	AGAVER
		dc.b	"AGA"
	ELSE
		dc.b	"ECS"
	ENDC
		dc.b	")"
	IFD	CHIP_ONLY
		dc.b	" (debug/chip mode)"
	ENDC
		dc.b	0
slv_copy		dc.b	"1996 Weathermine Software",0
slv_info		dc.b	"adapted by JOTD",10,10
	IFND	AGAVER
		dc.b	"Thanks to C. Lennard for diskimages",10,10
	ENDC
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	IFD	AGAVER
	dc.b	"XP8.b212",0
	ELSE
	dc.b	"XP8.exe",0
	ENDC
_args		dc.b	10
_args_end
	dc.b	0
slv_config:
	;dc.b	"BW;"
	dc.b    "C1:X:Trainer Infinite Lives:0;"
	;dc.b    "C2:X:Sound effects only (no music):0;"
	dc.b    "C3:L:Start level:1,2,3,4,5;"			
	dc.b	0
	
	EVEN


_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload

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
		lea	_assign_1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		IFD	AGAVER
		lea	_assign_4(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		
		ENDC
        ;get tags
		lea     (_tag,pc),a0
		jsr     (resload_Control,a2)
		
        IFD CHIP_ONLY
        movem.l a6,-(a7)
		move.l	$4.w,a6
        move.l  #CHIP_ALIGN,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
        ENDC
		
	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found

	;patch here
		bsr	_patch_exe
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
	jsr	(_LVOIoErr,a6)
	pea	_program(pc)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_patch_exe
	move.l	d7,a1
	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr		resload_PatchSeg(a2)
	
	move.l	start_level(pc),d0
	beq.b	.out
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.w	#4,a1
	add.l	#PASSWORD_OFFSET,a1
	add.w	d0,d0
	lea		codes(pc),a0
	move.w	(a0,d0.w),d0
	add.w	d0,a0
	; 3 words
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
.out

	rts
	
pl_main
	PL_START
	IFD	AGAVER
	PL_IFC1X	0	; infinite lives
	PL_NOP	$17128,6
	PL_B	$17128+6,$60
	PL_ENDIF
	
	PL_PS	$13cdc,blitwait_1
	PL_P	$1BF70,end_letter_blit
	PL_PS	$DEC6,avoid_af
	ELSE
	; ECS
	PL_B	$167E,$60	; manual protection
	PL_B	$A60E,$60	; manual protection
	PL_IFC1X	0	; infinite lives
	PL_NOP	$0e6a2,4
	PL_B	$0e6a2+4,$60
	PL_ENDIF
	ENDC
	PL_END
	
avoid_af:
	MOVE.W	D2,D0			;0dec6: 3002
	bmi.b	.avoid
	MULU	#$001c,D0		;0dec8: c0fc001c
	rts
.avoid
	; value is going to be too important because of bogus input
	; clear it, it's bogus anyway
	clr.l	d0
	rts
	
end_letter_blit
	; without this wait, the letters may be trashed
	; because some blitter registers are changed in between letter writes
	; even if waitblits are done between letter planes within routine
	bsr	wait_blit
	MOVEM.L	(A7)+,D0-D5/A1-A2	;1bf70: 4cdf063f
	RTS				;1bf74: 4e75
	
blitwait_1
	; blit wait was done a little too late
	bsr	wait_blit
	MOVE.L	A6,(72,A0)		;13cdc: 214e0048
	MOVE.L	A1,(76,A0)		;13ce0: 2149004c
	add.l	#$13cf6-$13ce0,(a7)
	rts
	
wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts
	
_tag:		dc.l	WHDLTAG_CUSTOM3_GET
start_level	dc.l	0

		dc.l	0
		
codes:
	dc.w	0,l2pw-codes,l3pw-codes,l4pw-codes,l5pw-codes

l2pw:  dc.l  $070A0E0D,$040B0203,$040D0202
l3pw:  dc.l  $0F0A0E0D,$040B0203,$040D0202
l4pw:  dc.l  $070A0C0F,$040B0203,$04090000
l5pw:  dc.l  $0F0A0C0F,$040B0203,$04090000