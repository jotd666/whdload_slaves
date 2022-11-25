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
	INCLUDE	lvo/dos.i
	INCLUDE	lvo/exec.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"KGB.Slave"
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
FASTMEMSIZE	= $80000
NUMDRIVES	= 2
WPDRIVES	= %0111

BLACKSCREEN
DISKSONBOOT
;HDINIT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
SETPATCH
CBDOSLOADSEG

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s



;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM


slv_name	dc.b	"KGB",0
slv_copy	dc.b	"1992 Cryo",0
slv_info	dc.b	"adapted & fixed by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		DECL_VERSION
		dc.b	0

slv_CurrentDir
	dc.b	0

	dc.b	"$","VER: slave "
	DECL_VERSION
		dc.b	$A,$D,0

	EVEN

;============================================================================

; disable caches in fast memory

		move.l	a0,a2
		move.l	#WCPUF_Exp_WT,d0
		move.l	#WCPUF_Exp,d1
		jsr	(resload_SetCPU,a2)
		move.l	a2,a0

	;initialize kickstart and environment

; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	
	addq.l	#4,d1	

	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0

	cmp.b	#'k',1(A0)
	bne.b	.skip
	cmp.b	#'g',2(A0)
	bne.b	.skip

	move.l	d1,a0
	add.l	#$36+$28,a0
	move.w	#$4EF9,(A0)+
	pea	_patch_main(pc)
	move.l	(a7)+,(a0)
.skip
	rts

_patch_main:
	; patch the keyboard

	bsr	_patchkb

	move.l	60(A7),A3	; return address, only chip: 1D478

	; fix cpu dependent dbf loops

	move.l	A3,A0
	move.l	A0,A1
	add.l	#120000,A1
	move.l	#$51C8FFFE,D0
	move.l	#$4EB80100,D1
	bsr	_hexreplacelong

	; remove password protection (1)

	move.l	A3,A0
	add.l	#$14000,a0
	lea	$7000(a0),a1
	; english/french version
	move.l	#$FEB43003,D0
	move.l	#$FEB4701D,D1
	bsr	_hexreplacelong
	; german version
	move.l	#$FEA43003,D0
	move.l	#$FEA4701D,D1
	bsr	_hexreplacelong

	; remove password protection (2)
	; common to both english and german version

	move.l	A3,A0
	add.l	#$C000,A0
	lea	$5000(A0),A1
	moveq.l	#4,D0
	lea	.crack(pc),A2
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipcrk
	cmp.l	#$524033C0,-8(A0)
	bne.b	.skipcrk
	move.l	#$60000004,(A0)
	move.w	#$7004,-8(A0)
.skipcrk

	; set disk changer

	move.l	A3,A0
	add.l	#$16000,A0
	lea	$2000(A0),A1
	lea	.set_disk(pc),a2
	moveq.l	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipdn
	lea	_disknum_address(pc),a1
	move.l	-4(a0),(a1)
.skipdn
	; set disk changer (2)

	move.l	A3,A0
	add.l	#$18000,A0
	lea	$3000(A0),A1
	lea	.swap_disks(pc),a2
	moveq.l	#10,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipdc

	lea	_saved_address(pc),a1
	move.l	-4(A0),(a1)		; save address
	pea	_swap_and_call(pc)
	move.l	(a7)+,-4(A0)
	move.l	#$4E714E71,2(A0)

.skipdc	

	; set copper fix

	move.l	A3,A0
	add.l	#$14000,A0
	lea	$3000(A0),A1
	lea	.set_copper(pc),a2
	moveq.l	#6,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipcop

	lea	_saved_copperlist(pc),a1
	move.l	-4(A0),(a1)		; save address
	pea	_set_copperlist(pc)
	move.l	(a7)+,-4(A0)
	move.l	#$4E714E71,(a0)
	move.w	#$4EB9,-6(A0)

.skipcop

	; set blitter fix

	move.l	A3,A0
	add.l	#$14000,A0
	lea	$3000(A0),A1
	lea	.set_dff040(pc),a2
	moveq.l	#10,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipblit1
	move.l	#$4E714EB9,(A0)
	pea	_set_dff040(pc)
	move.l	(a7)+,4(a0)
	move.w	#$4E71,8(a0)

	move.l	#$4E714EB9,$15C(A0)
	pea	_set_dff064(pc)
	move.l	(a7)+,$160(a0)
	move.l	#$4E714EB9,$25A(A0)
	pea	_set_dff064(pc)
	move.l	(a7)+,$25E(a0)
.skipblit1
	move.l	A3,A0
	add.l	#$17000,A0
	lea	$2000(a0),a1
	lea	.close_lib(pc),a2
	moveq.l	#12,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipcl
	move.w	#$4EF9,(A0)+
	pea	_quit(pc)
	move.l	(A7)+,(A0)
.skipcl
	; fix VBL set

	lea	.vblset(pc),a2
	move.l	A3,A0
	add.l	#$13000,A0
	lea	$4000(a0),a1
	moveq.l	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skvbl
	move.l	#$4E714EB9,(A0)+
	pea	_setvbl(pc)
	move.l	(A7)+,(A0)+
.skvbl
	; fix SMC

	lea	.smc1(pc),a2
	lea	_fix_smc1(pc),a4
	bsr	_smc_lookup

	lea	.smc2(pc),a2
	lea	_fix_smc2(pc),a4
	bsr	_smc_lookup

	lea	.smc3(pc),a2
	lea	_fix_smc3(pc),a4
	bsr	_smc_lookup

	lea	.smc4(pc),a2
	lea	_fix_smc4(pc),a4
	bsr	_smc_lookup

	lea	.smc5(pc),a2
	lea	_fix_smc5(pc),a4
	bsr	_smc_lookup

	lea	.smc6(pc),a2
	lea	_fix_smc6(pc),a4
	bsr	_smc_lookup

;	lea	.smc6(pc),a2
;	lea	_fix_smc6(pc),a4
;	bsr	_smc_lookup

	lea	.smc7(pc),a2
	bsr	_smc_lookup_2

	lea	.smc8(pc),a2
	bsr	_smc_lookup_2

	pea	_fix_smc7(pc)
	move.l	(A7)+,$BC.W	; trap #15

	bsr	_flushcache
	movem.l	(A7)+,D0-A6
	rts



.set_dff040:
	dc.l	$23FC09F0,$000000DF
	dc.w	$F040

.set_copper
	dc.l	$DFF084
	dc.w	$2A79

.set_disk:
	dc.l	$8006E34E,$06450001

.crack
	dc.l	$C0C5E088

.close_lib:
	dc.l	$4EAEFE62,$2C790000,$00042279
.swap_disks:
	dc.l	$4A006700,$FFF62A3C
	dc.w	$0000

.vblset:
	dc.l	$33FC87F0,$DFF096
.smc1:
	dc.l	$E94FD5C7,$70002248
.smc2:
	dc.l	$24482649,$2A4C7800
.smc3:
	dc.l	$24482649,$78007E00
.smc4:
	dc.l	$24482649,$284BD9FC
.smc5:
	dc.l	$24482A4C,$78007E00
.smc6:
	dc.l	$24482649,$78007E00
.smc7:
	dc.l	$48E700C0,$78003E28
	dc.w	0
.smc8:
	dc.l	$48E700C2,$78003E28
	dc.w	0

_setvbl:
	move.w	#$87F0,$DFF096
	bsr	_flushcache
	rts

_fix_smc7:
	moveq.l	#0,D4
	bsr	_flushcache
	RTE

; < A2: lookup string
; < A4: patch routine

_smc_lookup:
	move.l	A3,A0
	add.l	#$E000,A0
	lea	$5000(A0),A1
	moveq.l	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.notfound

	move.l	(A0),(A4)	; copy overwritten code
	move.w	4(A0),4(A4)

	move.w	#$4EB9,(A0)
	move.l	a4,2(a0)
	rts
.notfound
	ILLEGAL
	rts

; < A2: lookup string
; < A4: patch routine

_smc_lookup_2:
	move.l	A3,A0
	add.l	#$E000,A0
	lea	$5000(A0),A1
	moveq.l	#10,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.notfound
	move.w	#$4E4F,4(A0)
	rts
.notfound
	ILLEGAL
	rts

DECL_FIX_SMC:MACRO
_fix_smc\1:
	dc.w	$4AFC,$4AFC,$4AFC
	bsr	_flushcache
;	move.w	#$\1\1\1,$DFF180
	rts
	ENDM

	DECL_FIX_SMC	1
	DECL_FIX_SMC	2
	DECL_FIX_SMC	3
	DECL_FIX_SMC	4
	DECL_FIX_SMC	5
	DECL_FIX_SMC	6


_quit
	PEA	TDREASON_OK
	MOVE.L	_resload(PC),-(A7)
	add.l	#resload_Abort,(a7)
	rts

_set_dff040:
	bsr	_waitblit
	move.l	#$09F00000,$DFF040
	rts

_set_dff064:
	bsr	_waitblit
	move.w	#$B4,$DFF064
	rts


_set_copperlist:
	move.l	A0,-(A7)
	move.l	_saved_copperlist(pc),a0
	move.l	(a0),a0
	cmp.l	#$01000000,$17C(a0)
	bne.b	.nofix
	move.w	#$200,$17E(a0)
.nofix
	move.l	a0,$dff084
	move.l	(A7)+,a0
	rts

_swap_and_call
	movem.l	D0/A0/A1,-(A7)
	lea	_trd_disk(pc),a0
	move.l	_disknum_address(pc),a1
	move.b	(A1),D0
	sub.b	#'0',D0
	move.b	D0,1(a0)

	lea	_trd_chg(pc),a0
	st.b	(a0)
	
	movem.l	(A7)+,D0/A0/A1
	rts
	
	move.l	_saved_address(pc),-(a7)
	rts

_saved_address:
	dc.l	0
_saved_copperlist:
	dc.l	0
_disknum_address:
	dc.l	0

_emulate_dbf:
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	_beamdelay
	rts

_waitblit:
	TST.B	dmaconr+_custom
	BTST	#6,dmaconr+_custom
	BNE.S	.wait
	bra.s	.end
.wait
	TST.B	$BFE001
	TST.B	$BFE001
	BTST	#6,dmaconr+_custom
	BNE.S	.wait
	TST.B	dmaconr+_custom
.end
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


_patchkb
	movem.l	A0-A1,-(A7)
	lea	.ackkb(pc),A0
	lea	.oldkb(pc),A1
	move.l	$68.W,(A1)
	move.l	A0,$68.W
	bsr	_flushcache
	movem.l	(A7)+,A0-A1
	rts

.ackkb:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)

;	move.b	$bfec01,d0
;	ror.b	#1,D0
;	not.b	D0
;	cmp.b	#$40,D0
;	bne.b	.noswap
;	bsr	_swap_disks
;.noswap

	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	move.l	.oldkb(pc),-(A7)
	rts

.oldkb:
	dc.l	0

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

;============================================================================


;============================================================================

	END

