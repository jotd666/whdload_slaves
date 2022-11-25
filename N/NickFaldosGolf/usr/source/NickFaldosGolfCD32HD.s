;*---------------------------------------------------------------------------
;  :Program.	NickFaldosGolfHD.asm
;  :Contents.	Slave for "NickFaldosGolf"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: NickFaldosGolfHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

DEBUG

	IFD BARFLY
	OUTPUT	"NickFaldosGolfCD32.slave"
	IFND	DEBUG
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	ENDC
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================


	IFD	DEBUG
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $0
HRTMON
	ELSE
RELOC_TO_FAST = 1
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $200000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
HDINIT
INITAGA
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'


;DUMMY_CD_DEVICE = 1
;USE_DISK_LOWLEVEL_LIB
USE_DISK_NONVOLATILE_LIB ; unused

;============================================================================

	INCLUDE	kick31cd32.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	incbin	slave_version
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

_assign1
	dc.b	"CD0",0

slv_name		dc.b	"Nick Faldo's Championship Golf CD³²",0
slv_copy		dc.b	"1994 Grandslam",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"golf/main",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN


;============================================================================

	;initialize kickstart and environment

_bootdos
	clr.l	$0.W

	move.l	_resload(pc),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		bsr	_patch_cd32_libs

		IFD	RELOC_TO_FAST
		bsr	patch_alloc
		ENDC
	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_main(pc),a5
		bsr	_load_exe
	;quit
quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist

patch_main
	IFD	RELOC_TO_FAST
	bsr	rem_patch_alloc
	ENDC

	pea	fix_smc_1(pc)
	move.l	(a7)+,$BC.W	; trap #$F

	patch	$100,emulate_dbf


	move.l	d7,a1
	addq.l	#4,a1

	lea	program_start(pc),a3
	move.l	a1,(a3)

	move.l	a1,a3
	add.l	#$1080C,a3
	move.l	(A3),d0	; install interrupt address
	lea	install_interrupt(pc),a3
	move.l	d0,(a3)

	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	IFD	RELOC_TO_FAST
	bsr	reloc_chip_data
	ENDC
	rts

fix_smc_1
	movem.l	d0/a0,-(a7)
	move.l	10(a7),a0	; return address
	moveq	#0,d0
	move.w	(a0),d0		; address offset to add
	ext.l	d0
	add.l	d0,10(a7)
	movem.l	(a7)+,d0/a0
	rte

install_interrupt
	dc.l	0

install_interrupt_and_flush
	pea	.rval(pc)
	move.l	install_interrupt(pc),-(a7)
	rts
.rval
	bsr	_flushcache
	rts

pl_main
	PL_START
	; read VBR in A0
	PL_L	$17672,$91C84E71
	; dos.Delay() argument bug: D1=$00400019 !!
	PL_S	$1D35E,$66-$5E
	
	; cache issue with interrupts

	PL_PS	$1080A,install_interrupt_and_flush

	; empty dbf delays

	PL_L	$17936,$4EB80100
	PL_L	$1E09E,$4EB80100
	PL_L	$1E0B4,$4EB80100
	PL_L	$1E800,$4EB80100
	PL_L	$1E816,$4EB80100
	
	PL_I	$1F47E	; another active loop

	; copper list errors

	PL_L	$D3A60+$A8,$01FE0000
	PL_L	$D3A60+$AC,$01FE0000

	; self-modifying code (causes gfx corrupt on trees with fastmem/caches on)

	PL_W	$19A2A,$4E4F	; TRAP #$F

	; blitter shit

	PL_PS	$19828,wait_blit_1
	PL_PS	$1836C,wait_blit_2

	; check that no fastmem shit is passed to blit routine

	PL_PS	$0197FE,check_blit_bounds

	PL_END

wait_blit_1
	bsr	wait_blit
	MOVE	#$FFFF,68(A6)		;019828: 3D7CFFFF0044
	rts

wait_blit_2
	LEA	_custom,A6
	bsr	wait_blit
	rts

wait_blit
	TST.B	dmaconr+$DFF000
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	bra.s	.end
.wait
	TST.B	$BFE001
	TST.B	$BFE001
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	TST.B	dmaconr+$DFF000
.end
	rts

check_blit_bounds
	LEA	_custom,A6
	cmp.l	#CHIPMEMSIZE,A0
	bcs.b	.ok

	; I'm too lazy to find the last relocs,
	; this should do the trick...

	sub.l	program_start(pc),a0
;	ILLEGAL
;	ILLEGAL
;	ILLEGAL
.ok
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

patch_alloc:
	movem.l	a0/a1,-(a7)
	move.l	$4.W,A0
	add.w	#_LVOAllocMem+2,a0
	lea	alloc_save(pc),a1
	move.l	(a0),(a1)
	lea	my_alloc(pc),a1
	move.l	a1,(a0)
	bsr	_flushcache
	movem.l	(a7)+,a0/a1
	rts

rem_patch_alloc:
	movem.l	a0,-(a7)
	move.l	$4.W,A0
	add.w	#_LVOAllocMem+2,a0
	move.l	alloc_save(pc),(A0)
	bsr	_flushcache
	move.l	(a7)+,a0
	rts

HUNK_SIZE = $152A00
CHIP_DATA_OFFSET = $111DC
CHIP_DATA_SIZE = HUNK_SIZE-CHIP_DATA_OFFSET+$100

my_alloc:
	btst	#MEMB_CHIP,d1
	beq.b	.out
	cmp.l	#HUNK_SIZE,d0
	beq.b	.fix
	bra.b	.out
.fix
	bclr	#MEMB_CHIP,d1
.out
	move.l	alloc_save(pc),-(A7)
	rts

alloc_save
	dc.l	0

; < D7: seglist

reloc_chip_data:
	movem.l	D0-A6,-(a7)
	move.l	$4.W,a6
	moveq.l	#MEMF_CHIP,d1
	move.l	#CHIP_DATA_SIZE,d0
	jsr	_LVOAllocMem(a6)
	tst.l	d0
	bne.b	.okalloc
	ILLEGAL
.okalloc
	; first, relocate

	move.l	d0,a3		; start of chipmem

	move.l	d7,a1
	addq.l	#4,a1
	add.l	#CHIP_DATA_OFFSET,a1	; offset to change
	sub.l	a3,a1		; a1: offset to substract

	lea	offsets(pc),a0
	move.l	d7,a2
	addq.l	#4,a2
.reloc:
	move.l	(a0)+,d0
	bmi.b	.out

	move.l	(a2,d0.l),d1
	cmp.l	#CHIPMEMSIZE,d1
	bcc.b	.ok
	ILLEGAL		; to early detect double entry in list
.ok
	move.l	(a2,d0.l),d1

	sub.l	a1,d1
	move.l	d1,(a2,d0.l)
	bra.b	.reloc
.out
	; then copy the data with corrected relocs into chipmem

	move.l	d7,a1
	addq.l	#4,a1
	
	add.l	#CHIP_DATA_OFFSET,a1	; offset to change
	move.l	#CHIP_DATA_SIZE/4,d1
.copycl
	move.l	(a1)+,(a3)+
	subq.l	#1,d1
	bne.b	.copycl

	bsr	_flushcache
	movem.l	(a7)+,d0-a6
	rts

program_start
	dc.l	0

offsets:
	; copperlists

	; LAB_06xx

	dc.l	$01A000+2       ; 6
	dc.l	$01A00C+2       ; 6
	dc.l	$01A29A+2       ; 6
	dc.l	$01A374+2       ; 6
	dc.l	$01A384+2       ; 6

	; LAB_09xx >= LAB_094E+2

	dc.l	$00ECB6+2	; 10
	dc.l	$00ECEC+2	; 6
	dc.l	$00ECF2+2	; 6
	dc.l	$01B4A0+2	; 6
	dc.l	$01B4C0+2	; 6
	dc.l	$01B600+2	; 6
	dc.l	$01B612+2	; 6
;;	dc.l	$01B670+2	; 6
	dc.l	$01B726+2	; 6
	dc.l	$01B738+2	; 6

	; LAB_0[BC]xx

	dc.l	$00E886+2	; 6
	dc.l	$0104AE+2	; 6
	dc.l	$010630+2	; 6
	dc.l	$010686+2	; 6
	dc.l	$010A7E+2	; 10
	dc.l	$010ABA+2	; 10
	dc.l	$010ACC+2	; 10
	dc.l	$010C50+2	; 6
	dc.l	$010C66+2	; 6
	dc.l	$010F5C+2	; 10
	dc.l	$012156+2	; 6
	dc.l	$01217A+2	; 6
	dc.l	$01219A+2	; 6
	dc.l	$01231C+2	; 6
	dc.l	$01232C+2	; 6
	dc.l	$01299E+2	; 6
	dc.l	$012A12+2	; 6
	dc.l	$012A2E+2	; 6
	dc.l	$012A46+2	; 6
	dc.l	$012A88+2	; 6
	dc.l	$012AA4+2	; 6
	dc.l	$0134C8+2	; 6
	dc.l	$0135F8+2	; 6
	dc.l	$013646+2	; 6
	dc.l	$013922+2	; 6
	dc.l	$013934+2	; 6
	dc.l	$0145B0+2	; 10
	dc.l	$0145BA+2	; 10
	dc.l	$0145CC+2	; 10
	dc.l	$0145D6+2	; 10
	dc.l	$0145E2+2	; 10
	dc.l	$0145EC+2	; 10
	dc.l	$0146DC+2	; 6
	dc.l	$0146F8+2	; 6
	dc.l	$01588C+2	; 6
	dc.l	$015B06+2	; 10
	dc.l	$015B1A+2	; 10
	dc.l	$015B2E+2	; 10
	dc.l	$016064+2	; 6
	dc.l	$016078+2	; 6
	dc.l	$016B32+2	; 6
	dc.l	$019C90+2	; 10
	dc.l	$019CDC+2	; 10
	dc.l	$019CF0	; 4, dc.l
	dc.l	$01AEA0+2	; 6
	dc.l	$01AEB6+2	; 6
	dc.l	$01AEDE+2	; 6
	dc.l	$01AF04+2	; 6
	dc.l	$01AF16+2	; 6
	dc.l	$01AF20+2	; 6
	dc.l	$01AF2E+2	; 6
	dc.l	$01AF98+2	; 6
	dc.l	$01AFC2+2	; 6
	dc.l	$01B0DE+2	; 6
	dc.l	$01B132+2	; 6
	dc.l	$01B164+2	; 6
	dc.l	$01B7D4+2	; 6
	dc.l	$01B90E+2	; 6
	dc.l	$01BA38+2	; 6
	dc.l	$01BA52+2	; 6
	dc.l	$01BA64+2	; 6
	dc.l	$01BD3E+2	; 6
	dc.l	$01BD4A+2	; 6
	dc.l	$01BD66+2	; 6
	dc.l	$01BD82+2	; 6
	dc.l	$01C1CE+2	; 6
	dc.l	$01C1EA+2	; 6
	dc.l	$01C246+2	; 6
	dc.l	$01C26E+2	; 6
	dc.l	$01C5D8+2	; 6
	dc.l	$01CAA6+2	; 6
	dc.l	$01CC22+2	; 6
	dc.l	$01CC3C+2	; 10
	dc.l	$01CC68+2	; 10
	dc.l	$01CC94+2	; 10
	dc.l	$01EF2C	; 4, dc.l
	dc.l	$01EF36	; 4, dc.l
	dc.l	$01EF40	; 4, dc.l
	dc.l	$01EF4A	; 4, dc.l
	dc.l	$01EF54	; 4, dc.l
	dc.l	$01EF5E	; 4, dc.l
	dc.l	$01EF68	; 4, dc.l
	dc.l	$01EF74	; 4, dc.l
	dc.l	$01EF7E	; 4, dc.l
	dc.l	$01EF88	; 4, dc.l
	dc.l	$01EF92	; 4, dc.l
	dc.l	$01EF9C	; 4, dc.l
	dc.l	$01EFA6	; 4, dc.l
	dc.l	$01EFB0	; 4, dc.l
	dc.l	$01EFBA	; 4, dc.l
	dc.l	$01EFC4	; 4, dc.l
	dc.l	$01EFCE	; 4, dc.l buggy disass doesn't show it
	dc.l	$01EFDA	; 4, dc.l
	dc.l	$01EFE4	; 4, dc.l
	dc.l	$01EFEE	; 4, dc.l
	dc.l	$01EFF8	; 4, dc.l
	dc.l	$01F002	; 4, dc.l
	dc.l	$01F00C	; 4, dc.l
	dc.l	$01F016	; 4, dc.l
	dc.l	$01F020	; 4, dc.l
	dc.l	$01F02A	; 4, dc.l
	dc.l	$01F034	; 4, dc.l
	dc.l	$01F03E	; 4, dc.l
	dc.l	$01F048	; 4, dc.l
	dc.l	$01F052	; 4, dc.l
	dc.l	$01F05E	; 4, dc.l
	dc.l	$01F068	; 4, dc.l
	dc.l	$01F072	; 4, dc.l
	dc.l	$01F07C	; 4, dc.l
	dc.l	$01F086	; 4, dc.l
	dc.l	$01F090	; 4, dc.l
	dc.l	$01F09A	; 4, dc.l
	dc.l	$01F0A4	; 4, dc.l
	dc.l	$01F0B0	; 4, dc.l
	dc.l	$01F0BA	; 4, dc.l
	dc.l	$01F0C4	; 4, dc.l
	dc.l	$01F0CE	; 4, dc.l
	dc.l	$01F0D8	; 4, dc.l
	dc.l	$01F0E0+2	; 8
	dc.l	$01F0EA+2	; 8
	dc.l	$01F0F4+2	; 8
	dc.l	$01F100	; 4, dc.l
	dc.l	$01F108+2	; 8
	dc.l	$01F114	; 4, dc.l
	dc.l	$01F11C+2	; 8
	dc.l	$01F128	; 4, dc.l
	dc.l	$01F134	; 4, dc.l
	dc.l	$01F13E	; 4, dc.l
	dc.l	$01F148	; 4, dc.l
	dc.l	$01F152	; 4, dc.l
	dc.l	$01F164+2	; 6
	dc.l	$01F172	; 4, dc.l
	dc.l	$01F17C	; 4, dc.l
	dc.l	$01F186	; 4, dc.l
	dc.l	$01F18E+2	; 6
	dc.l	$01F19C	; 4, dc.l
	dc.l	$01F1A6	; 4, dc.l
	dc.l	$01F1B0	; 4, dc.l
	dc.l	$01F1BA	; 4, dc.l
	dc.l	$01F1C2+2	; 6
	dc.l	$01F1CC+2	; 6
	dc.l	$01F1DA	; 4, dc.l
	dc.l	$01F1E4	; 4, dc.l
	dc.l	$01F1EE	; 4, dc.l
	dc.l	$01F1F8	; 4, dc.l
	dc.l	$01F202	; 4, dc.l
	dc.l	$01F20C	; 4, dc.l
	dc.l	$01F216	; 4, dc.l
	dc.l	$01F222	; 4, dc.l
	dc.l	$01F22C	; 4, dc.l
	dc.l	$01F236	; 4, dc.l
	dc.l	$01F240	; 4, dc.l
	dc.l	$01F24A	; 4, dc.l
	dc.l	$01F254	; 4, dc.l
	dc.l	$01F25E	; 4, dc.l
	dc.l	$01F26A	; 4, dc.l
	dc.l	$01F274	; 4, dc.l
	dc.l	$01F27E	; 4, dc.l
	dc.l	$01F288	; 4, dc.l
	dc.l	$01F298+2	; 10
	dc.l	$01F3BE+2	; 6
	dc.l	$01F3DC+2	; 6
	dc.l	$01F42C+2	; 6
	dc.l	$01F442+2	; 6

	; LAB_0Dxx

	dc.l	$0121B6	; 4, dc.l
	dc.l	$0121BA	; 4, dc.l
	dc.l	$0121BE	; 4, dc.l
	dc.l	$0121C2	; 4, dc.l
	dc.l	$0121C6	; 4, dc.l
	dc.l	$019CFE	; 4, dc.l
	dc.l	$019CF6	; 4, dc.l
	dc.l	$017658	; 4, dc.l
	dc.l	$017662	; 4, dc.l
	dc.l	$012BE0+2	; 6
	dc.l	$0123DA+2	; 6
	dc.l	$0129E4+2	; 6
	dc.l	$0129F6+2	; 6
	dc.l	$012ABC+2	; 6
	dc.l	$0120C6+2	; 6
	dc.l	$0120BA+2	; 6
	dc.l	$0120AE+2	; 6
	dc.l	$012E00+2	; 6
	dc.l	$012E3A+2	; 6
	dc.l	$012106+2	; 6
	dc.l	$01212C+2	; 6
	dc.l	$012148+2	; 6
	dc.l	$012200+2	; 6
	dc.l	$012212+2	; 6
	dc.l	$01229A+2	; 6
	dc.l	$0122AC+2	; 6
	dc.l	$012B80+2	; 6
	dc.l	$012B94+2	; 6
	dc.l	$012284+2	; 6
	dc.l	$0122EE+2	; 6
	dc.l	$01230A+2	; 6
	dc.l	$011F16+2	; 6
	dc.l	$012096+2	; 6
	dc.l	$01240C+2	; 6
	dc.l	$01262C+2	; 6
	dc.l	$012424+2	; 6
	dc.l	$012446+2	; 6
	dc.l	$01246C+2	; 6
	dc.l	$012500+2	; 6
	dc.l	$01255A+2	; 6
	dc.l	$012570+2	; 6
	dc.l	$01271E+2	; 6
	dc.l	$01273E+2	; 6
	dc.l	$01280A+2	; 6
	dc.l	$012864+2	; 6
	dc.l	$01287A+2	; 6
	dc.l	$0124B4+2	; 6
	dc.l	$012522+2	; 6
	dc.l	$012538+2	; 6
	dc.l	$012590+2	; 6
	dc.l	$012690+2	; 6
	dc.l	$0126D4+2	; 6
	dc.l	$01274C+2	; 6
	dc.l	$01282C+2	; 6
	dc.l	$012842+2	; 6
	dc.l	$01289A+2	; 6
	dc.l	$01272C+2	; 6
	dc.l	$0124E0+2	; 6
	dc.l	$0126C0+2	; 6
	dc.l	$0125D2+2	; 6
	dc.l	$0128DC+2	; 6
	dc.l	$0125FA+2	; 6
	dc.l	$0127E6+2	; 6
	dc.l	$012904+2	; 6
	dc.l	$0125E6+2	; 6
	dc.l	$0127B4+2	; 6
	dc.l	$0128F0+2	; 6
;;	dc.l	$015EF4+2	; 6
	dc.l	$018546+2	; 6
	dc.l	$01083A+2	; 6
	dc.l	$010BA8+2	; 6
	dc.l	$011116+2	; 6
	dc.l	$0111D2+2	; 6
	dc.l	$018406+2	; 6
	dc.l	$01842A+2	; 6
	dc.l	$01B5DE+2	; 6
	dc.l	$01854C+2	; 6
	dc.l	$01B542+2	; 6
	dc.l	$01B586+2	; 6
	dc.l	$01CA44+2	; 6
	dc.l	$01CA6E+2	; 6
	dc.l	$01D15A+2	; 6
	dc.l	$01D1F4+2	; 6
	dc.l	$01D23A+2	; 6
	dc.l	$01D28C+2	; 6
	dc.l	$01D2EC+2	; 6
	dc.l	$01D154+2	; 6
	dc.l	$01D1B8+2	; 6
	dc.l	$01D1EE+2	; 6
	dc.l	$01D214+2	; 6
	dc.l	$01D234+2	; 6
	dc.l	$01D2E6+2	; 6
	dc.l	$01D2C6+2	; 6
	dc.l	$01A278+2	; 6
	dc.l	$0160A8+2	; 6
	dc.l	$0160CE+2	; 6
	dc.l	$012E90+2	; 6
	dc.l	$012EBC+2	; 6
	dc.l	$012E88+2	; 6
	dc.l	$012EB4+2	; 6
	dc.l	$01B51A+2	; 6
	dc.l	$01B55E+2	; 6
	dc.l	$012EAE+2	; 6
	dc.l	$018540+2	; 6
	dc.l	$015B78+2	; 10
	dc.l	$015B68+2	; 10
	dc.l	$015C52+2	; 10
	dc.l	$015BFA+2	; 10
	dc.l	$015BEA+2	; 10
	dc.l	$015D44+2	; 10
	dc.l	$015D94+2	; 10
	dc.l	$017BF8+2	; 8
	dc.l	$0111DC+2	; 10
	dc.l	$01B5EC+2	; 10
	dc.l	$01B4EC+2	; 10
	dc.l	$01788C+2	; 6
	dc.l	$019F56+2	; 6
	dc.l	$0178A4+2	; 6
	dc.l	$019F68+2	; 6
	dc.l	$01A25E+2	; 6
	dc.l	$01B47C+2	; 10
	dc.l	$01B48C+2	; 10
	dc.l	$01CAA0+2	; 6
	dc.l	$019740+2	; 6
	dc.l	$01972C+2	; 6
	dc.l	$01B486+2	; 6
	dc.l	$019BB0+2	; 6

	; ,LAB_0Dxx

	dc.l	$013412+4	; 8
	dc.l	$01319C+4	; 8
	dc.l	$0131E4+4	; 8
	dc.l	$0131A8+4	; 8
	dc.l	$0131F0+4	; 8
	dc.l	$01341E+4	; 8
	dc.l	$017BAA+4	; 8
	dc.l	$017BB2+4	; 8
	dc.l	$017BBA+6	; 10

	; ,LAB_0Fxx

	dc.l	$0160D8+2	; 6
	dc.l	$011566+4	; 8
	dc.l	$01156E+4	; 8
	dc.l	$011576+4	; 8
	dc.l	$01157E+4	; 8
	dc.l	$015B06+6	; 10
	dc.l	$015B1A+6	; 10
	dc.l	$015B2E+6	; 10
	dc.l	$01F298+6	; 10

	; LAB_0Fxx

	dc.l	$0103CA+2	; 6
	dc.l	$010822+2	; 10
	dc.l	$010BBC+2	; 6
	dc.l	$010C28+2	; 10
	dc.l	$010F12+2	; 10
	dc.l	$010F36+2	; 6
	dc.l	$011008+2	; 10
	dc.l	$011128+2	; 10
	dc.l	$011234+2	; 10
	dc.l	$01125A+2	; 6
	dc.l	$01126C+2	; 10
	dc.l	$0112D4+2	; 10
	dc.l	$01135E+2	; 10
	dc.l	$0113F8+2	; 10
	dc.l	$011470+2	; 10
	dc.l	$0114CA+2	; 10
	dc.l	$011586+2	; 10
	dc.l	$01161C+2	; 10
	dc.l	$011642+2	; 6
	dc.l	$011654+2	; 10
	dc.l	$011782+2	; 10
	dc.l	$011A8C+2	; 10
	dc.l	$011AB2+2	; 6
	dc.l	$011E20+2	; 6
	dc.l	$011E2A+2	; 6
	dc.l	$011F72+2	; 6
	dc.l	$011F8A+2	; 6
	dc.l	$011FAE+2	; 6
	dc.l	$01609E+2	; 10
	dc.l	$0160DE+2	; 6
	dc.l	$018DF8+2	; 6
	dc.l	$019174+2	; 6
	dc.l	$0192D2+2	; 6
	dc.l	$0192F0+2	; 6
	dc.l	$019E90+2	; 6
	dc.l	$01B19C+2	; 6
	dc.l	$01B202+2	; 10
	dc.l	$01B704+2	; 10
	dc.l	$01CBFC+2	; 10
	dc.l	$01CCBE+2	; 10
	dc.l	$01CD32+2	; 10
	dc.l	$01CD80+2	; 10

	; DC.Ls in "data" section

	dc.l	$035418	; 4, dc.l
	dc.l	$03541C	; 4, dc.l
	dc.l	$035420	; 4, dc.l
	dc.l	$035424	; 4, dc.l
	dc.l	$035428	; 4, dc.l
	dc.l	$03D78A	; 4, dc.l
	dc.l	$03D78E	; 4, dc.l
	dc.l	$03D792	; 4, dc.l
	dc.l	$03D796	; 4, dc.l
	dc.l	$03D79A	; 4, dc.l
	dc.l	$03D79E	; 4, dc.l
	dc.l	$03D7A2	; 4, dc.l
	dc.l	$071E34	; 4, dc.l
	dc.l	$071E38	; 4, dc.l
	dc.l	$071E3C	; 4, dc.l
	dc.l	$071E40	; 4, dc.l
	dc.l	$071E44	; 4, dc.l
	dc.l	$0BA6F6	; 4, dc.l
	dc.l	$0BA6FA	; 4, dc.l
	dc.l	$0BA6FE	; 4, dc.l
	dc.l	$0BA702	; 4, dc.l
	dc.l	$0BA706	; 4, dc.l
	dc.l	$0BA70A	; 4, dc.l
	dc.l	$0CABE6	; 4, dc.l
	dc.l	$0CABEA	; 4, dc.l
	dc.l	$0CABEE	; 4, dc.l
	dc.l	$0CABF2	; 4, dc.l
	dc.l	$0CABF6	; 4, dc.l
	dc.l	$0CABFA	; 4, dc.l
	dc.l	$0CCFFE	; 4, dc.l
	dc.l	$0CD002	; 4, dc.l
	dc.l	$0CD006	; 4, dc.l
	dc.l	$0CD00A	; 4, dc.l
	dc.l	$0CD00E	; 4, dc.l
	dc.l	$0CD012	; 4, dc.l
	dc.l	$0CD1B2	; 4, dc.l
	dc.l	$0CD1B6	; 4, dc.l
	dc.l	$0CD1BA	; 4, dc.l
	dc.l	$0CD1BE	; 4, dc.l
	dc.l	$0CD1C2	; 4, dc.l
	dc.l	$0CD1C6	; 4, dc.l
	dc.l	$0CD9A2	; 4, dc.l
	dc.l	$0CD9A6	; 4, dc.l
	dc.l	$0CD9AA	; 4, dc.l
	dc.l	$0CD9AE	; 4, dc.l
	dc.l	$0CD9B2	; 4, dc.l
	dc.l	$0CD9B6	; 4, dc.l
	dc.l	$0CD9BA	; 4, dc.l
	dc.l	$0CD9BE	; 4, dc.l
	dc.l	$0CE57E	; 4, dc.l
	dc.l	$0CE582	; 4, dc.l
	dc.l	$0CE586	; 4, dc.l
	dc.l	$0CE58A	; 4, dc.l
	dc.l	$0CE58E	; 4, dc.l
	dc.l	$0CE7AC	; 4, dc.l
	dc.l	$0CE7B0	; 4, dc.l
	dc.l	$0CE7B4	; 4, dc.l
	dc.l	$0CE7B8	; 4, dc.l
	dc.l	$0CE7BC	; 4, dc.l
	dc.l	$0CF142	; 4, dc.l
	dc.l	$0CF146	; 4, dc.l
	dc.l	$0CF14A	; 4, dc.l
	dc.l	$0CF14E	; 4, dc.l
	dc.l	$0CF152	; 4, dc.l
	dc.l	$0CF156	; 4, dc.l
	dc.l	$0CF212	; 4, dc.l
	dc.l	$0CF216	; 4, dc.l
	dc.l	$0CF21A	; 4, dc.l
	dc.l	$0CF21E	; 4, dc.l
	dc.l	$0CF222	; 4, dc.l
	dc.l	$0CF226	; 4, dc.l
	dc.l	$0CF22A	; 4, dc.l
	dc.l	$0CF22E	; 4, dc.l
	dc.l	$0CF232	; 4, dc.l
	dc.l	$0CF236	; 4, dc.l
	dc.l	$0CF23A	; 4, dc.l
	dc.l	$113F22	; 4, dc.l
	dc.l	$113F26	; 4, dc.l
	dc.l	$113F2A	; 4, dc.l
	dc.l	$113F2E	; 4, dc.l
	dc.l	$113F32	; 4, dc.l
	dc.l	$113F36	; 4, dc.l
	dc.l	$113F3A	; 4, dc.l
	dc.l	$113F3E	; 4, dc.l
	dc.l	$113F42	; 4, dc.l
	dc.l	$113F46	; 4, dc.l
	dc.l	$113F4A	; 4, dc.l
	dc.l	$113F4E	; 4, dc.l
	dc.l	$113F52	; 4, dc.l
	dc.l	$113F56	; 4, dc.l
	dc.l	$113F5A	; 4, dc.l
	dc.l	$113F5E	; 4, dc.l
	dc.l	$113F62	; 4, dc.l
	dc.l	$113F66	; 4, dc.l
	dc.l	$113F6A	; 4, dc.l
	dc.l	$113F6E	; 4, dc.l
	dc.l	$113F72	; 4, dc.l
	dc.l	$113F76	; 4, dc.l
	dc.l	$113F7A	; 4, dc.l
	dc.l	$113F7E	; 4, dc.l
	dc.l	$113F82	; 4, dc.l
	dc.l	$113F86	; 4, dc.l
	dc.l	$113F8A	; 4, dc.l
	dc.l	$113F8E	; 4, dc.l
	dc.l	$113F92	; 4, dc.l
	dc.l	$113F96	; 4, dc.l
	dc.l	$113F9A	; 4, dc.l
	dc.l	$113F9E	; 4, dc.l
	dc.l	$113FA2	; 4, dc.l
	dc.l	$113FA6	; 4, dc.l
	dc.l	$113FAA	; 4, dc.l
	dc.l	$113FAE	; 4, dc.l
	dc.l	$113FB2	; 4, dc.l
	dc.l	$113FB6	; 4, dc.l
	dc.l	$113FBA	; 4, dc.l
	dc.l	$113FBE	; 4, dc.l
	dc.l	$113FC2	; 4, dc.l
	dc.l	$113FC6	; 4, dc.l
	dc.l	$113FCA	; 4, dc.l
	dc.l	$113FCE	; 4, dc.l
	dc.l	$113FD2	; 4, dc.l
	dc.l	$113FD6	; 4, dc.l
	dc.l	$113FDA	; 4, dc.l
	dc.l	$113FDE	; 4, dc.l
	dc.l	$113FE2	; 4, dc.l
	dc.l	$113FE6	; 4, dc.l
	dc.l	$113FEA	; 4, dc.l
	dc.l	$113FEE	; 4, dc.l
	dc.l	$113FF2	; 4, dc.l
	dc.l	$113FF6	; 4, dc.l
	dc.l	$113FFA	; 4, dc.l
	dc.l	$113FFE	; 4, dc.l
	dc.l	$114002	; 4, dc.l
	dc.l	$114006	; 4, dc.l
	dc.l	$11400A	; 4, dc.l
	dc.l	$11400E	; 4, dc.l
	dc.l	$114012	; 4, dc.l
	dc.l	$114016	; 4, dc.l
	dc.l	$11401A	; 4, dc.l
	dc.l	$11401E	; 4, dc.l
	dc.l	$114022	; 4, dc.l
	dc.l	$114026	; 4, dc.l
	dc.l	$11402A	; 4, dc.l
	dc.l	$11402E	; 4, dc.l
	dc.l	$114032	; 4, dc.l
	dc.l	$114036	; 4, dc.l
	dc.l	$11403A	; 4, dc.l
	dc.l	$11403E	; 4, dc.l
	dc.l	$114042	; 4, dc.l
	dc.l	$114046	; 4, dc.l
	dc.l	$11404A	; 4, dc.l
	dc.l	$11404E	; 4, dc.l
	dc.l	$114052	; 4, dc.l
	dc.l	$114056	; 4, dc.l
	dc.l	$11405A	; 4, dc.l
	dc.l	$11405E	; 4, dc.l
	dc.l	$114062	; 4, dc.l
	dc.l	$114066	; 4, dc.l
	dc.l	$11406A	; 4, dc.l
	dc.l	$11406E	; 4, dc.l
	dc.l	$114072	; 4, dc.l
	dc.l	$114076	; 4, dc.l
	dc.l	$11407A	; 4, dc.l
	dc.l	$11407E	; 4, dc.l
	dc.l	$114082	; 4, dc.l
	dc.l	$114086	; 4, dc.l
	dc.l	$11408A	; 4, dc.l
	dc.l	$11408E	; 4, dc.l
	dc.l	$114092	; 4, dc.l
	dc.l	$114096	; 4, dc.l
	dc.l	$11409A	; 4, dc.l
	dc.l	$11409E	; 4, dc.l
	dc.l	$1140A2	; 4, dc.l
	dc.l	$1140A6	; 4, dc.l
	dc.l	$1140AA	; 4, dc.l
	dc.l	$1140AE	; 4, dc.l
	dc.l	$1140B2	; 4, dc.l
	dc.l	$1140B6	; 4, dc.l
	dc.l	$1140BA	; 4, dc.l
	dc.l	$1140BE	; 4, dc.l
	dc.l	$1140C2	; 4, dc.l
	dc.l	$1140C6	; 4, dc.l
	dc.l	$1140CA	; 4, dc.l
	dc.l	$1140CE	; 4, dc.l
	dc.l	$1140D2	; 4, dc.l
	dc.l	$1140D6	; 4, dc.l
	dc.l	$1140DA	; 4, dc.l
	dc.l	$1140DE	; 4, dc.l
	dc.l	$1140E2	; 4, dc.l
	dc.l	$1140E6	; 4, dc.l
	dc.l	$1140EA	; 4, dc.l
	dc.l	$1140EE	; 4, dc.l
	dc.l	$1140F2	; 4, dc.l
	dc.l	$1140F6	; 4, dc.l
	dc.l	$1140FA	; 4, dc.l
	dc.l	$1140FE	; 4, dc.l
	dc.l	$114102	; 4, dc.l
	dc.l	$114106	; 4, dc.l
	dc.l	$11410A	; 4, dc.l
	dc.l	$11410E	; 4, dc.l
	dc.l	$114112	; 4, dc.l
	dc.l	$114116	; 4, dc.l
	dc.l	$11411A	; 4, dc.l
	dc.l	$11411E	; 4, dc.l
	dc.l	$114122	; 4, dc.l
	dc.l	$114126	; 4, dc.l
	dc.l	$114EEC	; 4, dc.l

	dc.l	-1

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

	add.l	d7,d7
	add.l	d7,d7

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	a4-a6/d7,-(a7)
	jsr	(a5)
	movem.l	(a7)+,a4-a6/d7
.skip
	;call
	move.l	d7,a1

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
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

;============================================================================
