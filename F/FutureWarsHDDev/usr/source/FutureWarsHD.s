;*---------------------------------------------------------------------------
;  :Program.	FutureWarsHD.asm
;  :Contents.	Slave for "FutureWars"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: FutureWarsHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	FutureWars.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;;DEBUG

;============================================================================

	IFD	DEBUG
CHIPMEMSIZE	= $110000
FASTMEMSIZE	= $0
HRTMON
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $90000
BLACKSCREEN
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 30000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 8000
;BOOTDOS
CBDOSLOADSEG
MUST_HAVE_STARTUP_SEQUENCE

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	include	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"4.3-B"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

df0_assign
	dc.b	"DF0",0

slv_name		dc.b	"Future Wars - Les Voyageurs du Temps",0
slv_copy		dc.b	"1990 Delphine",0
slv_info		dc.b	"adapted & fixed by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Thanks to C.Vella/O.Schott/C.Sauer/J.Borgmeyer/Tolkien for diskimages",10,10

		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"delphine",0
	EVEN

	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

;============================================================================

my_delete:
	moveq.l	#-1,D0		; always OK, but don't perform the delete
	rts

; us: mouse flag: A3E8.W
; memconfig: all chip: 19491: letter - 'A', 19493: digit - 1, 1947D: page (1=4, 2=14, 3=7)

patch_dos:
	movem.l	d0-d7/a0-a6,-(a7)

	MOVE.L	$4.W,A6			;OPEN DOSLIB FOR USE (THE EMU
	MOVEQ.L	#0,D0			;PROVIDES THE FUNCTIONS)
	LEA	.dosname(PC),A1
	jsr	_LVOOpenLibrary(a6)
	MOVE.L	d0,a1
	move.l	d0,a3
	lea	my_delete(pc),a0
	move.l	a0,d0
	move.l	#_LVODeleteFile,A0
	move.l	$4.W,A6
	jsr	_LVOSetFunction(a6)

	move.l	a3,a6
	lea	df0_assign(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign

.skip
	movem.l	(a7)+,d0-d7/a0-a6

	rts
.dosname
	dc.b	"dos.library",0
	even

VERSION_PL:MACRO
.\1
	lea	pl_\1(pc),a0
	bra	.out
	ENDM


get_version:
	movem.l	d0-d1/a1,-(a7)
	lea	_program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#73388,D0
	beq.b	.french

	cmp.l	#73208,d0
	beq.b	.english

	cmp.l	#73628,d0
	beq.b	.german

	cmp.l	#73484,d0
	beq.b	.us
	
	cmp.l	#73696,d0
	beq.b	.spanish
	
	cmp.l	#73548,d0
	beq.b	.italian

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

	VERSION_PL	us
	VERSION_PL	spanish
	VERSION_PL	italian
	VERSION_PL	english
	VERSION_PL	french
	VERSION_PL	german


.out
	movem.l	(a7)+,d0-d1/a1
	rts

; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	

	; now D1 is seglist APTR

	lsl.l	#2,d0
	move.l	d0,a0

	; skip Kixx intro program

	cmp.b	#'d',1(a0)
	bne.b	.skip_delphine

	move.l	d1,a3

	addq.l	#4,a3	; code segment
	lea	start_jump(pc),a4
	move.l	2(a3),(a4)		; save start jump for later

	pea	patch_start(pc)
	move.l	(a7)+,2(a3)

	patch	$300.W,dbf_loop_d0
	patch	$306.W,dbf_loop_d1
	patch	$30C.W,dbf_loop_d7

	bsr	get_version

	move.l	a3,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

.skip_delphine
	rts

patch_start
	bsr	patch_dos
	move.l	start_jump(pc),-(a7)
	rts

start_jump
	dc.l	0

intena_and_flush
	bsr	_flushcache
	move.w	#$C000,$DFF09A
	add.l	#2,(a7)
	rts



pl_german
	PL_START
	; crack (how they do that!!)
	PL_B	$1C05,4

	; cache problem fixed
	PL_PS	$D7F0,intena_and_flush
	PL_PS	$D812,intena_and_flush

	; removes "Insert Backup disk in drive" request

	PL_W	$2FAC,$6018
	PL_W	$31D6,$6018

	; remove save disk request (else game loops)
	; and all disk changes tests (I think)

	PL_W	$DBC2,$4E71
	PL_W	$DCA8,$4E71

	; fix dbf delays D0/D1/D7
	PL_L	$E342,$4EB80300
	PL_L	$E890,$4EB80300

	PL_L	$00EC,$4EB80306

	PL_L	$E4A8,$4EB8030C
	PL_END


pl_us
	PL_START
	; adapted crack from puzzle to paintspot and it works!!!!
	; I'm sooo glad that it took me long hours to crack both versions,
	; not succeeding really (at least for puzzle version), whereas I had
	; the german crack which can be adapted for all versions and it exactly
	; 1 byte long !!!!!!!!!

	PL_B	$1C05,4

	; cache problem fixed
	PL_PS	$D766,intena_and_flush
	PL_PS	$D788,intena_and_flush

	; removes "Insert Backup disk in drive" request

	PL_W	$2FA0,$6018
	PL_W	$31CA,$6018

	; remove save disk request (else game loops)
	; and all disk changes tests (I think)

	PL_W	$DB38,$4E71
	PL_W	$DC08,$4E71

	; fix dbf delays D0/D1/D7
	PL_L	$E2AE,$4EB80300
	PL_L	$E808,$4EB80300

	PL_L	$00EC,$4EB80306

	PL_L	$E414,$4EB8030C
	PL_END

pl_english
	PL_START
	; crack (how they do that!!)
	PL_B	$1C05,4

	; cache problem fixed
	PL_PS	$D66E,intena_and_flush
	PL_PS	$D690,intena_and_flush

	; removes "Insert Backup disk in drive" request

	PL_W	$2FA6,$6018
	PL_W	$31D0,$6018

	; remove save disk request (else game loops)
	; and all disk changes tests (I think)

	PL_W	$DA40,$4E71
	PL_W	$DB10,$4E71

	; fix dbf delays D0/D1/D7
	PL_L	$E1AA,$4EB80300
	PL_L	$E6F8,$4EB80300

	PL_L	$00EC,$4EB80306

	PL_L	$E310,$4EB8030C
	PL_END


pl_spanish
	PL_START
	; crack (how they do that!!)
	PL_B	$1C2F,4

	; cache problem fixed
	PL_PS	$d824,intena_and_flush
	PL_PS	$d846,intena_and_flush

	; removes "Insert Backup disk in drive" request

	PL_W	$2fd2,$6018
	PL_W	$31fc,$6018

	; remove save disk request (else game loops)
	; and all disk changes tests (I think)

	PL_W	$dbf6,$4E71
	PL_W	$dcce,$4E71

	; fix dbf delays D0/D1/D7
	PL_L	$e6ca,$4EB80300
	PL_L	$ec24,$4EB80300

	PL_L	$00EC,$4EB80306

	PL_L	$e830,$4EB8030C
	PL_END


pl_italian
	PL_START
	
	; crack (how they do that!!)
	PL_B	$1C05,4		; correct way to crack the game
	PL_B	$1c06,$64	; restore BCC (crack inserted BRA but it made the game fail afterwards)

	; cache problem fixed
	PL_PS	$d7b0,intena_and_flush
	PL_PS	$d7d2,intena_and_flush

	; removes "Insert Backup disk in drive" request

	PL_W	$2fa6,$6018
	PL_W	$31d0,$6018

	; remove save disk request (else game loops)
	; and all disk changes tests (I think)

	PL_W	$db82,$4E71
	PL_W	$dc5c,$4E71

	; fix dbf delays D0/D1/D7
	PL_L	$e2f6,$4EB80300
	PL_L	$e844,$4EB80300

	PL_L	$00EC,$4EB80306

	PL_L	$e45c,$4EB8030C
	PL_END

pl_french
	PL_START
	; crack (how they do that!!)
	PL_B	$1C05,4

	; cache problem fixed
	PL_PS	$D71E,intena_and_flush
	PL_PS	$D740,intena_and_flush

	; removes "Insert Backup disk in drive" request

	PL_W	$2FA8,$6018
	PL_W	$31D2,$6018

	; remove save disk request (else game loops)
	; and all disk changes tests (I think)

	PL_W	$DAF0,$4E71
	PL_W	$DBC4,$4E71

	; fix dbf delays D0/D1/D7
	PL_L	$E5B6,$4EB80300
	PL_L	$EB04,$4EB80300

	PL_L	$00EC,$4EB80306

	PL_L	$E71C,$4EB8030C
	PL_END

; used to fix music, sound...

DBFLOOPDX:MACRO
dbf_loop_d\1:
	MOVE.L	D0,-(a7)
	move.l	D\1,D0
	bsr	dbf_loop_d0
	MOVE.L	(a7)+,D0
	rts
	ENDM

	DBFLOOPDX	1
	DBFLOOPDX	7
	
dbf_loop_d0:
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	_beamdelay
	rts

; ----------- UTILITY FUNCTIONS -----------

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
