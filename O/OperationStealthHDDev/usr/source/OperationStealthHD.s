;*---------------------------------------------------------------------------
;  :Program.	OperationStealthHD.asm
;  :Contents.	Slave for "OperationStealth"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: OperationStealthHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"OperationStealth.slave"
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
NUMDRIVES	= 1
WPDRIVES	= %1111

;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
;DEBUG
;INITAGA
HDINIT
HRTMON
IOCACHE		= 20000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000

;============================================================================

KICKSIZE	= $40000			;34.005
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

_name		dc.b	"Operation Stealth / The Stealth Affair",0
_copy		dc.b	"1990 Delphine",0
_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Thanks to Tony Aksnes for U.S. version",10,10
		dc.b	"Version 2.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_data:
	dc.b	"data",0
	CNOP 0,4
_assign0
	dc.b	3,"DF0",0
	even

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	;initialize kickstart and environment
		bra	_boot


; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	move.l	d1,d7
	
	move.l	d0,a0
	add.l	a0,a0
	add.l	a0,a0
	cmp.b	#8,(a0)
	beq.b	.chk_prog
	cmp.b	#4,(a0)
	beq.b	.chk_prog2
	bra.b	.skip_prog
.chk_prog
	cmp.b	#'d',1(a0)
	beq.b	.prog
.chk_prog2
	cmp.b	#'b',1(a0)
	beq.b	.prog
	bra.b	.skip_prog
.prog
	clr.l	$0.W

	bsr	_patchkb

	move.l	(_resload),a2		;A2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)

	bsr	_patch_main
.skip_prog
	rts


_patchkb
	IFEQ	KICKSIZE-$40000

	lea	.ackkb(pc),A0
	lea	.oldkb(pc),A1
	move.l	$68.W,(A1)
	move.l	A0,$68.W
	rts

.ackkb:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	move.l	.oldkb(pc),-(A7)
	rts

.oldkb:
	dc.l	0

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
	ELSE
	rts
	ENDC


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0


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

_game_start:
	; assign DF0 to root dir, so game saves work

	movem.l	D0-A6,-(a7)
	lea	_dosname(pc),a1
	move.l	$4.W,a6
	moveq.l	#0,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,a6

	lea	_assign0(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign
	movem.l	(a7)+,D0-A6
	
	move.l	_saved_jmp(pc),-(a7)
	rts

_saved_jmp
	dc.l	0

; < D7: seglist

_patch_main
	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3

	; execute some stuff just before start

	lea	4(a3),a0
	lea	_saved_jmp(pc),a1
	move.l	2(a0),(a1)
	pea	_game_start(pc)
	move.l	(A7)+,2(a0)

	; fix cache problem (interrupt vector change)

	move.l	A3,A0
	move.l	A0,A1
	add.l	#100000,A1
	lea	.intena(pc),A2
	moveq.l	#8,D0
.loop
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipi
	move.l	#$4E714EB9,(a0)+
	pea	_intena_and_flush(pc)
	move.l	(a7)+,(a0)
	bra.b	.loop
.skipi
	; fix dbf delays

	move.l	A3,A0
	move.l	A0,A1
	add.l	#100000,A1
	move.l	#$51C8FFFE,D0
	move.l	#$4EB80300,D1
	bsr	_hexreplacelong
	patch	$300.W,_dbf_loop_d0
	move.l	A3,A0
	move.l	A0,A1
	add.l	#100000,A1
	move.l	#$51CFFFFE,D0
	move.l	#$4EB80306,D1
	bsr	_hexreplacelong
	patch	$306.W,_dbf_loop_d7

	; V3.7 specific, no need for that in V4.0

	; remove save disk request (else game loops)
	; and all disk changes tests (I think)

	move.l	A3,A0
	move.l	A0,A1
	add.l	#100000,A1
	lea	.isd(pc),A2
	move.l	#12,D0
.loopisd
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipisd
	move.w	#$4E71,(A0)
	bra.b	.loopisd
.skipisd
	; insert disk 1 requester removal

	move.l	A3,A0
	move.l	A0,A1
	add.l	#100000,A1
	lea	.id1(pc),A2
	move.l	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipid1
	move.w	#$600A,6(A0)
.skipid1
	move.l	A3,A0
	move.l	A0,A1
	add.l	#100000,A1
	lea	.id2(pc),A2
	move.l	#12,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipid2
	move.b	#$60,11(A0)
.skipid2

	; branch offset error (happened in the RMB menu)
	; strange! maybe a compiler bug, undetected under slow CPU
	; because of CPU dependent test ?
	; forced the test to always false (by a NOP), anyway it never
	; branches in a normal 68000, otherwise it would not have worked!

	move.l	A3,A0
	move.l	A0,A1
	add.l	#100000,A1
	lea	.berr(pc),A2
	move.l	#12,D0
.berrloop
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipberr
	move.w	#$4E71,10(A0)
	bra.b	.berrloop
.skipberr
	; end V3.7 specific

	; removes "Insert Backup disk in drive" request

	move.l	A3,A0
	move.l	A0,A1
	add.l	#100000,A1
	lea	.isdreq(pc),A2
	move.l	#10,D0
.isdreqloop
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipisdreq
	move.w	#$6018,(A0)
	bra.b	.isdreqloop
.skipisdreq

	; copy protection removal

	move.l	A3,A0
	move.l	A0,A1
	add.l	#100000,A1
	lea	.branch(pc),A2
	moveq.l	#6,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipprot
	move.w	#$4E4F,(A0)
	lea	_crackit(pc),A0
	move.l	A0,$BC.W
.skipprot
	rts

.branch:	
	dc.l	$60000878
	dc.W	$4EBA
.id1:
	dc.l	$B87C0010,$6DEA3F2C	;$80204EB9 (8026 for US)
.id2:
	dc.l	$426C8258,$0C6CFFFF,$F9CC660C
.isd:
	dc.l	$66044E5D,$4E753F2D
	dc.l	$00084ebA
.berr:
	dc.l	$426c8258,$0c6cffff,$f9cc6660
.intena:
	dc.l	$33FCC000,$DFF09A
.isdreq:
	dc.l	$3F2DFFF8,$486DFF76
	dc.w	$4EBA

_intena_and_flush:
	bsr	_flushcache
	move.w	#$C000,$DFF09A
	rts

_crackit:
	movem.l	D0/A0,-(A7)

	move.l	10(A7),A0	; gets return pc
	moveq.l	#0,D0
	move.w	(A0),D0		; gets BRA offset
	add.l	D0,A0
	move.l	A0,10(A7)	; changes return pc

	; now the crack stuff...

	cmp.w	#$1063,-4(A5)
	bne.b	.nocrack_europe
	move.w	#$1093,-4(A5)	; crack it !!!
	bra.b	.out
.nocrack_europe
	cmp.w	#$1074,-4(A5)
	bne.b	.tryprot
	bra.b	.out
.tryprot
	cmp.w	#$108C,-4(A5)
	bne.b	.nocrack_us
	move.w	#$110F,-4(A5)
.nocrack_us
.out
	movem.l	(A7)+,D0/A0
	rte

; used to fix music

_dbf_loop_d7:
	movem.l	D0,-(a7)
	move.l	D7,D0
	bsr	_dbf_loop_d0
	movem.l	(a7)+,D0
	rts

; used for ??

_dbf_loop_d0:
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	_beamdelay
	rts


;============================================================================

	INCLUDE	kick13.s

;============================================================================
