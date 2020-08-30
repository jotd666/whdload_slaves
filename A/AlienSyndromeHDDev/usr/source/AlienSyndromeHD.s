;*---------------------------------------------------------------------------
;  :Program.	AlienSyndromeHD.asm
;  :Contents.	Slave for "AlienSyndrome" from 
;  :Author.	JOTD
;  :Original	v1 jffabre@free.fr
;  :Version.	$Id: battleisle.asm 0.5 2000/11/26 21:13:41 jah Exp $
;  :History.	23.05.01 started
;		23.05.01 finished
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

	IFD BARFLY
	OUTPUT	"AlienSyndrome.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

PATCH_DIRECTORY_STUFF = 0

UPPER	MACRO
		cmp.b	#"a",\1
		blo	.l\@
		cmp.b	#"z",\1
		bhi	.l\@
		sub.b	#$20,\1
.l\@
	ENDM

;============================================================================

; number of floppy drives:
;	sets the number of floppy drives, valid values are 0-4.
;	0 means that the number is specified via option Custom1/N
NUMDRIVES=1

; protection state for floppy disks:
;	0 means 'write protected', 1 means 'read/write'
;	bit 0 means drive DF0:, bit 3 means drive DF3:
WPDRIVES=%1111

; enable SetPatch
;	include all patches (nearly all) done by the SetPatch program, usually
;	that is not neccessary and disabling that option makes the Slave
;	around 400 bytes shorter
;SETPATCH

; enable debug support for hrtmon:
;	hrtmon reads to much from the stackframe if entered, if the ssp is at
;	the end hrtmon will create a access fault.
;	for better compatibility this option should be disabled
;HRTMON

; calculate minimal amount of free memory
;	if the symbol MEMFREE is defined after each call to exec.AllocMem the
;	size of the largest free memory chunk will be calculated and saved at
;	the specified address if lower than the previous saved value (chipmem
;	at MEMFREE, fastmem at MEMFREE+4)
;MEMFREE=$100

; amount of memory available for the system
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $20000
;FASTMEMSIZE	= $0

;============================================================================

KICKSIZE	= $40000			;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	13			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_Req68020|WHDLF_EmulPriv	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_data		dc.b	"data",0
_name		dc.b	"Alien Syndrome",0
_copy		dc.b	"1987 Sega",0
_info		dc.b	"Installed by JOTD",10
		dc.b	"Thanks to Bored Seal, Carlo Pirri",10,10
		dc.b	"Set CUSTOM5=1 to activate trainer",10
		dc.b	"Using the TAB key then toggles",10
		dc.b	"infinite time and lives",10,10
		dc.b	"Version 1.1 ",10
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0

_bcpl_exename:
	dc.b	5
_exename:
	dc.b	"alien",0
_lf:
	dc.b	10,0
	even

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	;initialize kickstart and environment
		bra	_boot

_bootearly	move.l	(_resload,pc),a2	;a2 = resload

	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)
		
	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
		

	bsr	DosLibInit

	;load program

	lea	_exename(pc),A0

	bsr	LoadExecutable

	move.l	a1,a5

	; patch program

	; ** reads score file (does not work in game)

	move.l	A5,A0
	move.l	A5,A1
	add.l	#$10000,A1
	lea	.scorepattern(pc),A2
	move.l	#10,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skiphs
	move.l	A0,A1
	lea	_hiscore_name(pc),A0
	move.l	#162,D0
	moveq.l	#0,D1
	move.l	_resload(pc),A2
	jsr	(resload_LoadFileOffset,a2)
.skiphs
	; ** allows to skip screens with fire button

	move.l	a5,a0
	move.l	a5,a1
	add.l	#$10000,a1
	lea	.beamdelaypattern(pc),a2
	move.l	#10,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skipxx
	move.w	#$4EB9,4(A0)
	pea	_waitbeam(pc)
	move.l	(A7)+,6(A0)
.skipxx

	; ** fixes blit wait

	move.l	a5,a0
	move.l	a5,a1
	add.l	#$10000,a1
	lea	.bltwaitpattern(pc),a2
	move.l	#10,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip
	patch	0(A0),_waitblit
.skip

	; ** trainer

	move.l	_custom5(pc),D0
	beq.b	.skiptrain

	; ** stores old kb int for later

	move.l	$68.W,A0
	lea	_oldkbint(pc),A1
	move.l	A0,(A1)

	; ** look up lives and time

	move.l	a5,a0
	move.l	a5,a1
	add.l	#$10000,a1
	lea	.sublivepattern(pc),a2
	move.l	#6,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip2
	lea	_lives_test(pc),a1
	move.l	A0,(A1)

.skip2
	move.l	a5,a0
	move.l	a5,a1
	add.l	#$10000,a1
	lea	.subtimepattern(pc),a2
	move.l	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip3

	lea	_time_test(pc),a1
	move.l	A0,(A1)
.skip3
	lea	_newkbint(pc),A1
	move.l	A1,$68.W

.skiptrain
	; ** look up hiscore write routine address

	move.l	a5,a0
	move.l	a5,a1
	add.l	#$10000,a1
	lea	.writepattern(pc),a2
	move.l	#12,D0
	bsr	_hexsearch
	lea	_write_address(pc),A1
	move.l	A0,(A1)

	; ** protection
	
	move.l	a5,a0
	move.l	a5,a1
	add.l	#$20000,a1
	lea	.drivestuff(pc),A2
	move.l	#12,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.quitds
	move.w	#$4E75,-$2E(A0)
.quitds
	move.l	a5,a0
	move.l	a5,a1
	add.l	#$10000,a1
	lea	.infloop(pc),a2
	moveq.l	#2,D0
.loopprot
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.quitprot
	move.w	#$4E71,(A0)+
	bra.b	.loopprot
.quitprot:

	; ** BCPL stuff

	move.l	_resload(pc),a2
	move.l	a5,a1
	lea	_patchlist(pc),a0
	jsr	(resload_Patch,a2)
	
	;disable cache
	move.l	#WCPUF_Exp_NCS,d0
	move.l	#WCPUF_Exp,d1
	jsr	(resload_SetCPU,a2)

	lea	_lf(pc),A0
	moveq	#1,D0

	;start
	sub.l	A6,A6
	sub.l	A4,A4
	sub.l	A3,A3
	sub.l	A2,A2
	sub.l	A1,A1
	moveq.l	#0,D1
	moveq.l	#0,D2
	moveq.l	#0,D3
	moveq.l	#0,D4
	moveq.l	#0,D5
	moveq.l	#0,D6
	moveq.l	#0,D7

	jsr	(a5)


	;quit
.quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

.bltwaitpattern:
	dc.l	$303900DF,$F0020800
	dc.w	$000E
.drivestuff:
	dc.l	$4CDF7CFC,$4E752C7C,$DFF000

.sublivepattern:
	dc.w	$536E,$0C18,$6A2A
.subtimepattern:
	dc.w	$536E,$0BF2,$4A16,$6B20
.beamdelaypattern:
	dc.l	$2013E080,$02800000
	dc.w	$1FF
.writepattern:
	dc.l	$4E55FFF8,$48E73012,$267C00BF
.infloop:
	dc.w	$66FE
.scorepattern:
	dc.b	"Hs"
	dc.l	$64
	dc.b	"TENT"
;---------------

_patchlist	PL_START
		PL_PS	$54,_loadprogname
		PL_W	$5A,$4E71
		PL_END

_newkbint:
	movem.l	D0/A0,-(A7)
	move.b	$BFEC01,D0
	ror.b	#1,D0
	not.b	D0
	cmp.b	#$42,D0		; TAB
	bne.b	.quit

	move.l	_write_address(pc),D0
	beq.b	.skippw
	move.l	D0,A0
	move.l	#$70004E75,(A0)		; sets MOVEQ #0,D0 + RTS to remove hiscore save
.skippw

	move.l	_lives_test(pc),D0
	beq.b	.skiplives
	
	move.l	D0,A0

	move.w	(A0),D0
	cmp.w	#$4A6E,D0
	beq.b	.restorelives

	move.w	#$0F0,$DFF180
	move.w	#$4A6E,(A0)
	bra.b	.skiplives
.restorelives:
	move.w	#$536E,(A0)
	move.w	#$FF0,$DFF180
.skiplives
	move.l	_time_test(pc),D0
	beq.b	.skiptime
	
	move.l	D0,A0
	move.w	(A0),D0
	cmp.w	#$4A6E,D0
	beq.b	.restoretime

	move.w	#$4A6E,(A0)
	bra.b	.skiptime

.restoretime:
	move.w	#$536E,(A0)

.skiptime
	movem.l	A2,-(A7)
	move.l	_resload(pc),A2
	jsr	(resload_FlushCache,A2)
	movem.l	(A7)+,A2

.quit:
	movem.l	(A7)+,D0/A0
	move.l	_oldkbint(pc),-(A7)
	rts				; jumps to original kb int

_waitbeam:
	and.l	#$1FF,D0	; stolen code
	btst	#7,$BFE001
	bne.b	.quit
	move.l	(8,A5),D0	; exits beam delay loop
.quit
	rts

_waitblit:
	move.l	A0,-(A7)
	; restore DMA bitplane first time called
	; (bug in kick13.s?)
	lea	.firsttime(pc),A0
	tst.b	(A0)
	bne.b	.skip
	st.b	(A0)
	move.w	#$A3D0,$dff096
.skip
	lea	$DFF000,A0
	TST.B	dmaconr(A0)
	BTST	#6,dmaconr(A0)
	BNE.S	.wait
	bra.s	.end
.wait
	TST.B	$BFE001
	TST.B	$BFE001
	BTST	#6,dmaconr(A0)
	BNE.S	.wait
	TST.B	dmaconr(A0)
.end
	move.l	(A7)+,A0
	rts
.firsttime:
	dc.w	0
	

_loadprogname:
	lea	_bcpl_exename(pc),A1
	rts


;---------------

_write_address:
	dc.l	0
_oldkbint:
	dc.l	0

_lives_test:
	dc.l	0

_time_test:
	dc.l	0

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
_custom5	dc.l	0
		dc.l	0
_hiscore_name:
	dc.b	"ASCORE.OBJ",0
	even

;============================================================================

	INCLUDE	kickdos.s
	INCLUDE	kick13.s

;============================================================================

	END
