;*---------------------------------------------------------------------------
;  :Program.	geebeeairrallyhd.asm
;  :Contents.	Slave for "Gee Bee Air Rally" from Activision
;  :Author.	Wepl
;  :Original	v1 
;  :Version.	$Id: wildwestworld.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	07.08.00 started
;		03.08.01 some steps forward ;)
;		30.01.02 final beta
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
	OUTPUT	"GeeBeeAirRally.slave"
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

BLACKSCREEN
;DEBUG
;DISKSONBOOT
DOSASSIGN
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;HRTMON

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
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

	CNOP 0,4
_geebee:
	dc.b	17,"Gee Bee Air Rally",0
	CNOP 0,4
_racer
	dc.b	5,"racer",0
	CNOP 0,4
_fff
	dc.b	3,"fff",0
	CNOP 0,4
_hiscore
	dc.b	7,"hiscore",0
	CNOP 0,4
_level
	dc.b	5,"level",0

_name		dc.b	"Gee Bee Air Rally",0
_copy		dc.b	"1987 Activision",0
_info		dc.b	"adapted & fixed by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version 1.1 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_data:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"AIR_RALLY",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	;initialize kickstart and environment
		bra	_boot


_bootdos	move.l	(_resload),a2		;A2 = resload

	;enable cache
		move.l	#WCPUF_Base_WT|WCPUF_Exp_NC|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)
		

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_racer(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_geebee(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_fff(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_hiscore(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_level(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end


	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1

		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check

		movem.l	d0/d7/a2/a6,-(a7)

		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

_end		moveq	#0,d0
		rts

_patch_audio:
	movem.l	A5/A6,-(A7)
	move.l	(IO_DEVICE,A1),A6
	move.l	LN_NAME(A6),A5
	cmp.b	#'a',(A5)
	bne.b	.skip

	tst.b	$22(a1)
	beq.b	.skip
;;;	move.l	$20(a1),$22(a1)	; correct IO request to avoid access fault
	clr.l	$22(A1)
.skip
	jsr	-30(a6)
	movem.l	(A7)+,A5/A6
	rts

_cb_dosLoadSeg
	bsr	_patch_dos
	tst.l	D0
	beq.b	_patch1		; patch overlay part
	add.l	d0,d0
	add.l	d0,d0
	move.l	d0,a0
	cmp.b	#'A',1(a0)
	beq.b	_patch2
	rts

_patch1
.loop
	move.l	d1,a0
	add.l	a0,a0
	add.l	a0,a0

	move.l	A0,-(A7)
	lea	4000(A0),A1
	lea	.alloc_table(pc),a2
	moveq.l	#12,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip
	move.l	$D8(A0),A0
	move.l	#$100,(A0)		; replace $0 by $100: avoid reading in vectors
	move.l	(A7)+,A0
	bra.b	.out
.skip
	move.l	(A7)+,A0
	move.l	(a0),d1
	bne.b	.loop
.out
	rts

.alloc_table:
	dc.l	$588F6100,$01AA4E71,$4E7123FC

_patch2
.loop
	move.l	d1,a0
	add.l	a0,a0
	add.l	a0,a0

	move.l	A0,-(A7)
	lea	10000(A0),A1
	lea	.audio_call(pc),a2
	moveq.l	#12,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip

	move.w	#$4EF9,(A0)+
	pea	_patch_audio(pc)
	move.l	(A7)+,(A0)

	move.l	(A7)+,A0
	bra.b	.out
.skip
	move.l	(A7)+,A0
	move.l	(a0),d1
	bne.b	.loop
.out
	rts

.audio_call:
	dc.l	$2F0E2C69,$00144EAE,$FFE22C5F

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



PATCH_OFFSET:MACRO
	move.l	A3,A1
	add.l	#_LVO\1,A1
	moveq	#0,D0
	move.w	4(A1),D0
	addq.l	#4,D0
	add.l	D0,A1

	lea	_old\1(pc),a0
	move.l	A1,(A0)+

	move.l	A3,A1
	add.l	#_LVO\1,A1
	move.b	1(A1),D0
	ext.w	D0
	ext.l	D0
	move.l	D0,(A0)

	move.w	#$4EF9,(A1)+	
	pea	_new\1(pc)
	move.l	(A7)+,(A1)+
	bra.b	_end_patch\1
_old\1:
	dc.l	0
_d0_value_\1
	dc.l	0
_end_patch\1:
	ENDM

_patch_dos:
	movem.l	D0-A6,-(A7)
	lea	_local_dosbase(pc),a2
	tst.l	(a2)
	bne.b	_pout		; already patched

	lea	_local_dosname(pc),a1
	move.l	$4.W,a6
	moveq.l	#0,D0
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,a3
	move.l	d0,(A2)
	PATCH_OFFSET	Lock
	bsr	_flushcache
_pout
	movem.l	(A7)+,D0-A6
	rts
_local_dosbase:
	dc.l	0
_local_dosname:
	dc.b	"dos.library",0
	even

_newLock:
	move.l	D1,A0
	bsr	_fix_last_slash
	move.l	A0,D1
	moveq	#0,D0
	move.l	_d0_value_Lock(pc),d0
	move.l	_oldLock(pc),-(A7)
	rts

_fix_last_slash:
	movem.l	A2,-(A7)
	lea	.buffer(pc),a2
	move.l	A0,A1
.loop
	move.b	(a1)+,(a2)+
	bne.b	.loop
	subq.l	#2,a2
	cmp.b	#'/',(a2)
	bne.b	.skip
	clr.b	(a2)
	lea	.buffer(pc),a0
.skip
	movem.l	(A7)+,A2
	rts

.buffer:
	blk.b	$30,0

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

	END
