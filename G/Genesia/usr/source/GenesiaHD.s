;*---------------------------------------------------------------------------
;  :Program.	GenesiaHD.asm
;  :Contents.	Slave for "Genesia"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: GenesiaHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"Genesia.slave"
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
;CHIPMEMSIZE	= $100000
;FASTMEMSIZE	= $00000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 30000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
CBDOSREAD
BOOTDOS
CACHE

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s


;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_assign
	dc.b	"Genesia",0
_assign_0
	dc.b	"Disk",0
_assign_1
	dc.b	"Disk_I",0
_assign_2
	dc.b	"Disk_II",0
_assign_3
	dc.b	"DF0",0


DECL_VERSION:MACRO
	dc.b	"1.5"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

slv_name		dc.b	"Genesia",0
slv_copy		dc.b	"1994 Microids",0
slv_info		dc.b	"adapted by JOTD",10
			dc.b	"from Wepl excellent KickStarter 34.005",10,10
			dc.b	"Set CUSTOM1=1 for game configuration",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_rtdd:
	dc.b	"c/rtdd",0
_program:
	dc.b	"genesia",0
_loader:
	dc.b	"loader",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================


; < d1 - file pos
; < a0 - name
; < a1 - buffer

_cb_dosRead
	cmp.b	#'R',(a0)
	bne.b	.skip
	cmp.l	#$18,d0
	bne.b	.skip
	move.w	#$4EF9,(a1)+
	pea	_restart(pc)
	move.l	(a7)+,(a1)+
	bsr	_flushcache
.skip
	rts

_restart
	lea	_custom1(pc),a0
	clr.l	(a0)		; next time boots on game directly
	lea	.svmode(pc),a5
	move.l	$4.W,a6
	jsr	_LVOSupervisor(a5)
.svmode
	ori	#$700,SR
	bra	kick_reboot

_bootdos
		move.l	(_resload),a2		;A2 = resload

	;get tags first
		lea	(_tag,pc),a0
		tst.l	(a0)
		beq.b	.skiptag
		jsr	(resload_Control,a2)		

	;do not get the tags at reboot
		lea	(_tag,pc),a0
		clr.l	(a0)

.skiptag
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;dos patch (for the paths starting with '/')

		bsr	_patch_dos

	;assigns
		lea	_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_0(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load real time data decruncher

		lea	_rtdd(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		sub.l	a5,a5
		bsr	_load_exe

		move.l	_custom1(pc),d0
		beq.b	.main
	;load config
		lea	_loader(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_loader(pc),a5
		bsr	_load_exe

.main
	;load main
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_main(pc),a5
		bsr	_load_exe
_quit
		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

_patch_main:
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	move.l	(a1),a1
	add.l	a1,a1
	add.l	a1,a1
	move.l	a1,a3

	move.l	_buttonwait(pc),d0
	beq.b	.skipwait
	; segment 2

	move.l	a3,a1
	move.l	a1,a0
	add.l	#$2000,a1
	lea	.config_fr(pc),a2
	moveq	#8,d0
	bsr	_hexsearch
	cmp.l	#0,a0
	beq.b	.skipconfig_fr
	move.w	#$4EB9,(a0)+
	pea	_waitconfig_fr(pc)
	move.l	(a7)+,(a0)
.skipconfig_fr
	move.l	a3,a1
	move.l	a1,a0
	add.l	#$2000,a1
	lea	.config_uk(pc),a2
	moveq	#8,d0
	bsr	_hexsearch
	cmp.l	#0,a0
	beq.b	.skipconfig_uk
	move.w	#$4EB9,(a0)+
	pea	_waitconfig_uk(pc)
	move.l	(a7)+,(a0)
.skipconfig_uk
.skipwait

	move.l	a3,a1
	add.l	#$1E000,a1
	move.l	a1,a0
	add.l	#$3000,a1
	lea	.protect_uk(pc),a2
	moveq	#8,d0
	bsr	_hexsearch
	cmp.l	#0,a0
	beq.b	.skipprot_uk
	move.l	#$4E714E71,(a0)
	bra.b	.skipprot_fr
.skipprot_uk:
	move.l	a3,a1
	add.l	#$1E000,a1
	move.l	a1,a0
	add.l	#$3000,a1
	lea	.protect_fr(pc),a2
	moveq	#8,d0
	bsr	_hexsearch
	cmp.l	#0,a0
	beq.b	.skipprot_fr
	move.l	#$4E714E71,(a0)
.skipprot_fr:
	rts

.protect_uk:
	dc.l	$6700FE22,$76024EAC
.protect_fr:
	dc.l	$6700FE44,$76024EAC
.config_fr:
	dc.l	$76114EAC,$1BE6760C
.config_uk:
	dc.l	$76114EAC,$1BF8760C

_waitconfig_fr
	moveq	#$11,d3
	jsr	7142(a4)
.loop
	btst	#6,$bfe001
	bne.b	.loop
	rts

_waitconfig_uk
	MOVEQ	#17,D3			;013DA: 7611
	JSR	7160(A4)		;013DC: 4EAC1BF8
.loop
	btst	#6,$bfe001
	bne.b	.loop
	rts

_patch_loader:
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	move.l	a1,a0
	add.l	#$2000,a1
	lea	.protect(pc),a2
	moveq	#8,d0
	bsr	_hexsearch
	cmp.l	#0,a0
	beq.b	.skipprot
	move.l	#$4E714E71,2(a0)
.skipprot:
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	add.l	#$18000,a1
	move.l	a1,a0
	add.l	#$3000,a1
	lea	.msg_uk(pc),a2
	moveq	#10,d0
	bsr	_hexsearch
	cmp.l	#0,a0
	beq.b	.skipmsg_uk
	addq.l	#4,a0
	move.b	#'S',(a0)+
	move.b	#'T',(a0)+
	move.b	#'A',(a0)+
	move.b	#'R',(a0)+
	move.b	#'T',(a0)+
	move.b	#' ',(a0)+
	bra	.out
.skipmsg_uk
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	add.l	#$18000,a1
	move.l	a1,a0
	add.l	#$3000,a1
.msgloop
	lea	.msg_fr(pc),a2
	moveq	#10,d0
	bsr	_hexsearch
	cmp.l	#0,a0
	beq.b	.out
	lea	.new_msg_fr(pc),a3
	lea	.end_fr(pc),a2
.cpfr
	move.b	(a3)+,(a0)+
	cmp.l	a3,a2
	bne.b	.cpfr
	bra.b	.msgloop
.out
	rts

.msg_uk
	dc.b	"NOW REBOOT"
.msg_fr:
	dc.b	"PATIENTEZ APRES LE RESET"
.new_msg_fr:
	dc.b	"   LE JEU VA DEMARRER   "
.end_fr
	even
.protect:
	dc.l	$48C36700,$00066000


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


; < A6: dosbase

_patch_dos:
	movem.l	D0-A6,-(A7)
	move.l	A6,A3
	move.l	$4.W,A6
	PATCH_OFFSET	Lock
	PATCH_OFFSET	Open
	bsr	_flushcache
	movem.l	(A7)+,D0-A6
	rts

_newLock:
	bsr	_fix_slash
	moveq	#0,D0
	move.l	_d0_value_Lock(pc),d0
	move.l	_oldLock(pc),-(A7)
	rts

_newOpen:
	bsr	_fix_slash
	moveq	#0,D0
	move.l	_d0_value_Open(pc),d0
	move.l	_oldOpen(pc),-(A7)
	rts


_fix_slash:
	move.l	D1,A0
	cmp.l	#0,a0
	beq.b	.skip
.loop1
	cmp.b	#':',(a0)
	beq.b	.colon
	tst.b	(a0)+
	bne.b	.loop1
	bra.b	.skip		; colon not found
.colon
	cmp.b	#'/',1(a0)
	bne.b	.skip		; no problemo

	
	lea	.buffer(pc),a0
	move.l	d1,a1

	; copy and replace ':/' by ':'
.loop
	move.b	(a1)+,(a0)+
	beq.b	.out
	cmp.b	#':',-1(a1)
	bne.b	.loop
	addq	#1,a1	; skip next '/'
	bra.b	.loop
	
.out
	lea	.buffer(pc),a0
	move.l	A0,D1
.skip
	rts

.buffer:
	blk.b	$20,0


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
	movem.l	d0-a6,-(a7)
	jsr	(a5)
	movem.l	(a7)+,d0-a6
	bsr	_flushcache
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


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	WHDLTAG_BUTTONWAIT_GET
_buttonwait	dc.l	0
		dc.l	0

;============================================================================


;============================================================================

	END
