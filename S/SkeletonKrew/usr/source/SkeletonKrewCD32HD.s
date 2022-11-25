;*---------------------------------------------------------------------------
;  :Program.	SkeletonKrewCD32HD.asm
;  :Contents.	Slave for "SkeletonKrewCD32" from
;  :Author.	JOTD
;  :History.	28.01.05
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	SkeletonKrewCD32.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;USE_FASTMEM
CHIPMEMSIZE = $1FF000
EXPMEMSIZE = $0

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoKbd|WHDLF_NoError|WHDLF_ReqAGA	;ws_flags
		IFD	USE_FASTMEM
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE+EXPMEMSIZE
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	dir-_base	;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem	
	IFD	USE_FASTMEM	
	dc.l	EXPMEMSIZE			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
    dc.w    _config-_base
;---
_config
	dc.b    "C1:B:trainer infinite lives;"
	dc.b    "C2:B:joystick controls;"
	dc.b    "C3:L:Start level:Monstrocity,Lift Shaft,"
	dc.b	"Clear All Aliens,Clear All Aliens 2,Clear All Aliens 3,"
	dc.b	"Clear All Aliens 4,Jungle,Mars,Venus,Kadaver,End sequence;"			
	dc.b	0
_start_level
	dc.b	0	; monstrocity
	dc.b	3	; lift shaft
	dc.b    4,6,8,10 ; clear all aliens
	dc.b	13	; jungle
	dc.b	$19	; mars
	dc.b	$13	; venus
	dc.b	$1B	; kadaver
	dc.b	$1D	; end sequence
_start_level_end
	dc.b	$1D	; just in case..
_nb_levels:
	dc.b	_start_level_end-_start_level
	even
; 101546 write: endseq
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"3.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

dir
	dc.b	"data",0

_name		dc.b	"Skeleton Krew CD³²"
		dc.b	0
_copy		dc.b	"1995 Core Design",0
_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
		even

BASE_ADDRESS = $180000
; check CD audio???
; level select


;======================================================================
start	;	A0 = resident loader
;======================================================================
	move.w	#$2700,SR

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	move.l	a0,a2
	lea	(_tags,pc),a0
	jsr	(resload_Control,a2)

	lea	CHIPMEMSIZE-$100,a7

	; load & version check


	lea	$17FD1A,A1
	lea	loadername(pc),A0
	bsr	read_file

	lea	BASE_ADDRESS,a1
	lea	pl_boot(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	jmp	BASE_ADDRESS

read_file
	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_LoadFile(a2)
	movem.l	(a7)+,d0-a6
	rts

read_a_file:
	cmp.w	#5,D0
	bne.b	.bypass

	bsr	read_file

.exit
	moveq.l	#0,D0
	rts

.bypass
	illegal

pl_boot
	PL_START	
	PL_P	$AE,read_a_file
	PL_P	$5C,patch_prog
	PL_END

patch_prog:
	movem.l	d0-a6,-(a7)
	move.l	_start_level_index(pc),d0
	cmp.b	_nb_levels(pc),d0
	bcc.b	.skip
	lea	_start_level(pc),a0
	move.b	(a0,d0.l),$20036+3
.skip
	lea	pl_prog(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	
	jmp	$500.W


pl_prog
	PL_START
	PL_IFC1
	PL_NOP	$A5CC,4
	PL_B	$A5D0,$60
	PL_ENDIF
	PL_IFC2
	PL_P	$200D0,PatchJoy0
	PL_P	$20040,PatchJoy1
	PL_ENDIF
	
	; ** the file reader

	PL_P	$23814,read_a_file

	; ** read music tracks?? (removed)

	PL_R	$202A2

	; ** install quit key

	PL_PS	$1334,kbread
	PL_W	$133A,$6008

	PL_PS	$950A,fix_af
	
	; fastram decrunch
	
	PL_P	$24B64,decrunch
	
	; end sequence
	PL_P	$14E8A,end_sequence
	PL_END

end_sequence
	lea	$100000,a1
	lea	pl_endseq(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$100000

pl_endseq:
	PL_START
	PL_P	$2660,decrunch
	PL_P	$1486,read_a_file
	PL_END
	
decrunch
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	jsr	(resload_Decrunch,a2)
	movem.l	(a7)+,d0-d1/a0-a2
	rts
	
fix_af
	; rarely happens: access fault on A1
	; emulating by masking highest byte
	; (24 bit address looks okay)
	move.l	D0,-(a7)
	move.l	a1,d0
	and.l	#$FFFFFF,d0
	move.l	d0,a1
	move.l	(a7)+,d0
	CLR.B (A1)
	CLR.B (A2)
	CLR.B (A3)
	RTS
	
; < A0: points on controls variable
; < A1: keytable
; < D2: bit to test for fire1
; < D1: bit to test for fire2

PatchJoy:
	clr.b	(A0)

	btst	D2,$BFE001
	bne	.nofire

	or.b	#$60,(A0)	; fire, static
	
.nofire
	move.b	rawkey(pc),D0

	cmp.b	(A1),D0		; L/Rshift
	bne.b	.3

	or.b	#$10,(A0)	; change weapon
.3
	cmp.b	(3,A1),D0		; up
	bne.b	.4

	or.b	#$08,(A0)	; jump/rematerialize
.4
	cmp.b	(2,A1),D0		; arrow right, fire & right
	bne.b	.nofire1

	or.b	#$20,(A0)	; fire 1

.nofire1
	cmp.b	(1,a1),D0		; arrow left, fire & left
	bne.b	.nofire2

	or.b	#$40,(A0)	; fire 2

.nofire2
	move.w	$DFF016,D0
	btst	D1,D0
	bne.b	.no2b

	or.b	#$10,(A0)	; change weapon
.no2b

.exit
	move.w	#$CC01,$DFF034	; reset
	rts

PatchJoy1:
	movem.l	d0-a6,-(a7)
	lea	$200CE,A0	; variable

	; *** test ESC only for player 1

	move.b	rawkey(pc),D0

	cmp.b	#$45,D0		; ESCAPE
	bne.b	.1

	or.b	#$80,(A0)	; quit game
	bra.b	.exit
	
.1
	lea	.keytable(pc),A1
	move.l	#14,D1		; bit of $DFF016 to test
	move.l	#7,D2		; bit of $BFE001 to test
	bsr	PatchJoy
.exit
	movem.l	(a7)+,d0-a6
	rts

.keytable:
	dc.b	97,79,78,76

PatchJoy0:
	movem.l	d0-a6,-(a7)
	lea	$20162,A0	; variable
	lea	.keytable(pc),A1
	move.l	#10,D1		; bit of $DFF016 to test
	move.l	#6,D2		; bit of $BFE001 to test
	bsr	PatchJoy
	movem.l	(a7)+,d0-a6
	rts

.keytable:
	dc.b	96,49,50,33

kbread:
	move.b	$BFE001,$1330.W	; original game
	move.b	$DFF016,$1331.W	; original game

	movem.l	d0-a6,-(a7)

	bsr	ReadKB

	cmp.b	#$19,D0
	beq	.pauseloop
	
.out
	move.w	#8,$DFF09C	; acknowledge keyboard
	movem.l	(a7)+,d0-a6

	rts

.pauseloop
	moveq	#10,D0
	bsr	_beamdelay
	bsr.b	ReadKB
	move.w	#8,$DFF09C	; acknowledge keyboard

	cmp.b	#$19,D0
	bne.b	.pauseloop
	bra.b	.out

ReadKB:
	movem.l	a0/A5,-(sp)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ.S	.exit
	MOVE.B	$1C01(A5),D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here

	lea	rawkey(pc),a0
	move.b	D0,(a0)

	BSET	#$06,$1E01(A5)
	moveq.l	#2,d0
	bsr	_beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge keypress
.exit
	movem.l	(sp)+,a0/A5
	
	rts

joypad:
	dc.l	0

rawkey:
	dc.b	0

loadername:
	dc.b	"SkeLoader",0
progname:
	dc.b	"Skeleton.bin",0
filename:
	ds.b	108,0
	
_tags
		dc.l	WHDLTAG_CUSTOM3_GET
_start_level_index
		dc.l	0
		dc.l	0
;--------------------------------

_resload	dc.l	0		;address of resident loader

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.l  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.l	(a7)+,d0
	dbf	d0,.bd_loop1
	rts
