;*---------------------------------------------------------------------------
;  :Program.	NigelMansellWorldChampHD.asm
;  :Contents.	Slave for "NigelMansellWorldChamp"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: NigelMansellWorldChampHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"NigelMansellWC.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;CHIP_ONLY

    IFD AGA
	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $00000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $100000
	ENDC
    ELSE
	; ECS
	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $120000
FASTMEMSIZE	= $00000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC
    
    ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
HDINIT
;IOCACHE		= 1000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
BOOTDOS

STACKSIZE = 10000

;============================================================================


slv_Version	= 16
slv_BaseFlags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
	IFD	AGA
slv_Flags	= slv_BaseFlags|WHDLF_ReqAGA
	ELSE
slv_Flags   = slv_BaseFlags
	ENDC
	
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s

;============================================================================

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


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,0

_assign1
	dc.b	"MANSELL_DISK1",0
_assign2
	dc.b	"MANSELL_DISK2",0

slv_name		dc.b	"Nigel Mansell World Champion"
        IFD AGA
        dc.b    " AGA"
        ELSE
        dc.b    " ECS"
        ENDC
slv_copy		dc.b	"1992 Gremlin",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Thanks to C.Vella and C.Pirri for disk images",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"Mansell",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

   ; for kick 3.1 use for dos too
PATCH_XXXLIB_OFFSET:MACRO
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
	
;============================================================================

	;initialize kickstart and environment

_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload

	lea		saved_level6_vector(pc),a0
	move.l	$78.W,(a0)
	
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
	
		IFND	AGA
		; align exe memory on round value
        IFD CHIP_ONLY
        movem.l a6,-(a7)
		move.l	$4.w,a6
        move.l  #$20000-$0001AC48,d0
        move.l  #$20000-$0001AC20,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
		
		PATCH_XXXLIB_OFFSET	AllocMem
		
        movem.l (a7)+,a6
        ENDC
        ENDC
		
	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found


	;patch here
		bsr	_patchrnc
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
		jsr	(_LVOIoErr,a6)
		move.l	d0,-(a7)
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

		IFND	AGA
        IFD CHIP_ONLY

new_AllocMem
	pea		.next(pc)
	move.l	old_AllocMem(pc),-(a7)
	rts
.next:
	tst.l	d0
	bne.b	.ok
	;blitz
	nop
.ok
	rts
	ENDC
	ENDC
	
_patchrnc
	movem.l	D0-A6,-(A7)

	; intercept program after the RNC executable decrunch
	; strange thing: one executable is decrunched OK with XFDDecrunch
	; but the other version is not (needs ProPack, so it's simpler to
	; support the crunched exe directly)

	move.l	d7,a5
	add.l	a5,A5
	add.l	a5,A5

	lea	$260(a5),a4
	cmp.l	#$4CDF7FFF,(a4)
	beq.b	.patch

	lea	$200(a5),a4
	cmp.l	#$4CDF7FFF,(a4)
	beq.b	.patch

	; unsupported version or decrunched exe

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts	
.patch
	pea	_patchexe(pc)
	move.w	#$4EF9,(a4)+
	move.l	(a7)+,(a4)+

	bsr	_flushcache
	movem.l	(a7)+,D0-A6
	rts

_patchexe:
	move.l	$3C(a7),a1	; return address
	move.l	a1,a0
	move.l	a1,a3
	move.l	a3,a4
	move.l	_resload(pc),a2
	add.l	#$8000,a3
	move.l	#$51C8FFFE,d2
	cmp.l	$A(a3),d2
	beq.b	.v1_ecs
	IFD	AGA
	cmp.l	$A02(a3),d2
	beq.b	.v2_aga
	;cmp.l	$9FE(a3),d2
	;beq.b	.v3_aga
	cmp.l	$a64(a3),d2
	beq.b	.vaga
	ENDC
	
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts	

	; ECS version #1
.v1_ecs
	lea	_pl_v1(pc),a0
	move.l	$00a6e+4(a1),a3	; get bplcon address #1
	or.w	#$200,(a3)
	move.l	$00a66+4(a1),a3	; get bplcon address #2
	or.w	#$200,(a3)
	bra.b	.patch
	bra.b	.patch
.v2_aga
	; AGA version #2

	lea	_pl_v2(pc),a0
	move.l	$abe+4(a1),a3	; get bplcon address #1
	or.w	#$200,(a3)
	move.l	$ac6+4(a1),a3	; get bplcon address #2
	or.w	#$200,(a3)
	bra.b	.patch
.v3_aga
	; AGA version #3 (newly adapted from a Quartex cracked version)
	; fails with "not enough memory no matter how much memory we configure!)
	lea	_pl_v3(pc),a0
	bra.b	.patch
.vaga
	; AGA version

	lea	_pl_vaga(pc),a0
.patch
	jsr	resload_Patch(a2)

	patch	$100,_emulate_dbf
	pea	_trap_clist(pc)
	move.l	(a7)+,$BC.W

	movem.l	(a7)+,D0-A6
	rts

_pl_v1:
	PL_START
	PL_L	$800A,$4EB80100	; dbf
	PL_L	$801E,$4EB80100	; dbf
	PL_L	$0834c,$323C0012	; fixes access fault
	PL_NOP	$08350,2	; af
	PL_B	$EDE,$60	; skips protection
	PL_PS	$EA10,_ack_kb
	PL_W	$EA10+$14,$6004	; keyboard ack start
	PL_W	$EA10+$34,$6004	; keyboard ack end

	PL_P	$17282,blit_fix_1
	PL_PSS	$17898,blit_fix_2,2

	;PL_W	$01074,$4E4F	; sets copperlist
	;PL_W	$01080,$4E4F	; sets copperlist

	; enable color burst
	PL_ORW	$00a6e+2,$200
	PL_ORW	$00f20+2,$200
	PL_ORW	$01498+2,$200
	PL_ORW	$014ca+2,$200
	PL_ORW	$01598+2,$200
	PL_ORW	$015bc+2,$200
	PL_ORW	$016b2+2,$200
	PL_ORW	$01770+2,$200
	PL_ORW	$01896+2,$200
	PL_ORW	$018b2+2,$200
	PL_ORW	$019ee+2,$200
	PL_ORW	$08fa6+2,$200
	PL_ORW	$091fe+2,$200
	PL_ORW	$09264+2,$200
	PL_ORW	$0e184+2,$200
	PL_ORW	$0e19e+2,$200
	PL_ORW	$16fee+2,$200
	PL_ORW	$1710c+2,$200
	PL_ORW	$17b44+2,$200
	PL_ORW	$17d08+2,$200
	PL_ORW	$18186+2,$200
	PL_ORW	$18306+2,$200
	PL_ORW	$1934a+2,$200
	PL_ORW	$19d7e+2,$200
	PL_ORW	$19de2+2,$200

	PL_ORW	$00a66+2,$200
	PL_ORW	$00f18+2,$200
	PL_ORW	$01490+2,$200
	PL_ORW	$014c2+2,$200
	PL_ORW	$01590+2,$200
	PL_ORW	$015b4+2,$200
	PL_ORW	$016aa+2,$200
	PL_ORW	$01768+2,$200
	PL_ORW	$0188e+2,$200
	PL_ORW	$018aa+2,$200
	PL_ORW	$019e6+2,$200
	PL_ORW	$08f9e+2,$200
	PL_ORW	$091f6+2,$200
	PL_ORW	$0925c+2,$200
	PL_ORW	$0e17a+2,$200
	PL_ORW	$0e194+2,$200
	PL_ORW	$16fe6+2,$200
	PL_ORW	$17104+2,$200
	PL_ORW	$17b3c+2,$200
	PL_ORW	$17cfe+2,$200
	PL_ORW	$1817e+2,$200
	PL_ORW	$182fc+2,$200
	PL_ORW	$1935a+2,$200
	PL_ORW	$19d76+2,$200
	PL_ORW	$19dda+2,$200

	PL_END

_pl_v2:
	PL_START
	PL_L	$8A02,$4EB80100	; dbf
	PL_L	$8A16,$4EB80100	; dbf
	PL_L	$8D44,$323C0012	; fixes access fault
	PL_NOP	$8D48,2	; af
	PL_B	$F36,$60	; skips protection
	PL_PS	$F486,_ack_kb
	PL_W	$F486+$14,$6004	; keyboard ack start
	PL_W	$F486+$34,$6004	; keyboard ack end

	PL_P	$180b0,blit_fix_1
	PL_PSS	$1888a,blit_fix_2,2
	
	;PL_W	$108C,$4E4F	; sets copperlist
	;PL_W	$1098,$4E4F	; sets copperlist
	
	; enable color burst
	
	PL_ORW	$00abe+2,$200
	PL_ORW	$00f70+2,$200
	PL_ORW	$015c6+2,$200
	PL_ORW	$015f8+2,$200
	PL_ORW	$016ca+2,$200
	PL_ORW	$016ee+2,$200
	PL_ORW	$017f4+2,$200
	PL_ORW	$018b8+2,$200
	PL_ORW	$01a36+2,$200
	PL_ORW	$01a52+2,$200
	PL_ORW	$01b8e+2,$200
	PL_ORW	$09994+2,$200
	PL_ORW	$09be2+2,$200
	PL_ORW	$09c44+2,$200
	PL_ORW	$0e964+2,$200
	PL_ORW	$0ebcc+2,$200
	PL_ORW	$0ebe6+2,$200
	PL_ORW	$17e14+2,$200
	PL_ORW	$17f32+2,$200
	PL_ORW	$18952+2,$200
	PL_ORW	$18b14+2,$200
	PL_ORW	$18e4c+2,$200
	PL_ORW	$18fca+2,$200
	PL_ORW	$19d86+2,$200
	PL_ORW	$1ab84+2,$200
	PL_ORW	$1abe8+2,$200

	PL_ORW	$00ac6+2,$200
	PL_ORW	$00f78+2,$200
	PL_ORW	$015ce+2,$200
	PL_ORW	$01600+2,$200
	PL_ORW	$016d2+2,$200
	PL_ORW	$016f6+2,$200
	PL_ORW	$017fc+2,$200
	PL_ORW	$018c0+2,$200
	PL_ORW	$01a3e+2,$200
	PL_ORW	$01a5a+2,$200
	PL_ORW	$01b96+2,$200
	PL_ORW	$0999c+2,$200
	PL_ORW	$09bea+2,$200
	PL_ORW	$09c4c+2,$200
	PL_ORW	$0e96c+2,$200
	PL_ORW	$0ebd6+2,$200
	PL_ORW	$0ebf0+2,$200
	PL_ORW	$17e1c+2,$200
	PL_ORW	$17f3a+2,$200
	PL_ORW	$1895a+2,$200
	PL_ORW	$18b1e+2,$200
	PL_ORW	$18e54+2,$200
	PL_ORW	$18fd4+2,$200
	PL_ORW	$19d76+2,$200
	PL_ORW	$1ab8c+2,$200
	PL_ORW	$1abf0+2,$200


	PL_END

_pl_v3:
	PL_START
	PL_L	$08a64,$4EB80100	; dbf
	PL_L	$08a78,$4EB80100	; dbf

	PL_B	$00f2c,$60	; skips protection
	PL_PS	$0f48e,_ack_kb
	PL_W	$0f48e+$14,$6004	; keyboard ack start
	PL_W	$0f48e+$34,$6004	; keyboard ack end

	PL_W	$01082,$4E4F	; sets copperlist
	PL_W	$0108e,$4E4F	; sets copperlist
	PL_END


_pl_vaga:
	PL_START
	PL_L	$89FE,$4EB80100	; dbf
	PL_L	$8A12,$4EB80100	; dbf
	PL_L	$8D40,$323C0012	; fixes access fault
	PL_NOP	$8D44,2	; access fault 2
	PL_B	$F36,$60	; skips protection
	PL_PS	$F482,_ack_kb	; replaces keyboard ack with handshake timing
	PL_W	$F482+$14,$6004	; keyboard ack start
	PL_W	$F482+$34,$6004	; keyboard ack end
	PL_PS	$672,alloc_aga_1
;	PL_PS	$6EE,alloc_aga_2

	; some code overwrites level 6 saved vector
	; I don't know where it happens, but never mind,
	; lets overwrite it with the proper value
	PL_P	$0087e,fix_restore_interrupt
	PL_END


wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts
	
; gremlin title screwed up
blit_fix_1:
	MOVE.W	#$7d28,88(A6)		;: 3d7c7d280058
	bra.b	wait_blit

; menu screwed up
blit_fix_2:
	bsr.b	wait_blit
	LEA	2(A1),A1		;1888a: 43e90002
	CMPI.W	#$0001,D7		;1888e: 0c470001
	rts
	

fix_restore_interrupt:
	move.l	saved_level6_vector(pc),$78.W
	ORI.W	#$c000,D0		;0087e: 0040c000
	MOVE.W	D0,(intena,A6)		;00882: 3d40009a
	RTS				;00886: 4e75
	
alloc_aga_1
	MOVE.L	(A4)+,D1		;00672: 221C
	cmp.l	#$E99A,d0	; alloc size matching music module "mod.results.30"
	bne.b	.skip

	; module results30 was loaded in fastmem: buggy music on result screen

	or.l	#MEMF_CHIP,d1
.skip
	JSR	_LVOAllocMem(A6)	;(exec.library)
	rts


alloc_aga_2
	JSR	_LVOAllocMem(A6)	;(exec.library)
	TST.L	D0			;006F2: 4A80
	rts

_trap_clist:
	movem.l	a1,-(a7)
	move.l	6(a7),a1
	move.l	(a1),a1

	; a1: copperlist pointer
	; patch copperlist now

	move.w	#$01FE,$40(a1)
	move.l	#$01FE0000,$44(a1)
	move.l	#$FFFFFFFE,$0.W

	move.l	a1,$dff080
	movem.l	(a7)+,a1
	addq.l	#8,2(a7)
	rte

_emulate_dbf:
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	_beamdelay
	rts

_ack_kb
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	rts

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

saved_level6_vector
	dc.l	0
;============================================================================

	END
