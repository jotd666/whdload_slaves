;*---------------------------------------------------------------------------
;  :Program.	FernandezMustDieHD.asm
;  :Contents.	Slave for "FernandezMustDie" from
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
	OUTPUT	FernandezMustDie.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;USE_FASTMEM
CHIPMEMSIZE = $80000
EXPMEMSIZE = $0

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem	;ws_flags
		IFD	USE_FASTMEM
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE+EXPMEMSIZE
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	data-_base		;ws_CurrentDir
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
	ENDM

_name		dc.b	"Fernandez Must Die"
		dc.b	0
_copy		dc.b	"1988 Mirrorsoft/Imageworks",0
_info		dc.b	"adapted by JOTD",10,10
		dc.b	"BUTTONWAIT allows to see intro pic",10
		dc.b	"CUSTOM1=1 enables cheatkey:",10
		dc.b	"TAB (cheat) toggles infinite lives",10,10
		dc.b	"F6: raises screen",10
		dc.b	"F7: lowers screen",10
                dc.b    "ESC: lose all lives",10,10
		dc.b	"P/R: pause/resume",10,10

		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

BASE_ADDRESS = $800
SCORELEN = 140
SCORESTART = $6BFA
COPPERLIST = $70000
PICTURE_ADDRESS = $65000

EXT_0002	EQU	$800
COP1LCH		EQU	$DFF080
COPJMP1		EQU	$DFF088
DIWSTRT		EQU	$DFF08E
DIWSTOP		EQU	$DFF090
DDFSTRT		EQU	$DFF092
DFFSTOP		EQU	$DFF094
DMACON		EQU	$DFF096
INTENA		EQU	$DFF09A
BPLCON0		EQU	$DFF100
BPLCON1		EQU	$DFF102
BPL1MOD		EQU	$DFF108
BPL2MOD		EQU	$DFF10A
SPR0DATA	EQU	$DFF144
SPR1DATA	EQU	$DFF14C
SPR2DATA	EQU	$DFF154
SPR3DATA	EQU	$DFF15C
SPR4DATA	EQU	$DFF164
SPR5DATA	EQU	$DFF16C
SPR6DATA	EQU	$DFF174
SPR7DATA	EQU	$DFF17C
COLOR00		EQU	$DFF180
COLOR02		EQU	$DFF184
COLOR04		EQU	$DFF188
COLOR06		EQU	$DFF18C
COLOR08		EQU	$DFF190
COLOR10		EQU	$DFF194
COLOR12		EQU	$DFF198
COLOR14		EQU	$DFF19C

RELOC_MOVE:MACRO
	lea	\2(pc),a0
	move.w	\1,(a0)
	ENDM

;======================================================================
start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	move.l	a0,a2
	lea	(tag,pc),a0
	jsr	(resload_Control,a2)

	lea	CHIPMEMSIZE-$100,a7

	move.l	#PICTURE_ADDRESS,D0

	ADDI.L	#$00000022,D0		;038: 068000000022
	RELOC_MOVE	D0,LAB_0009		;03E: 33C0000002CE
	SWAP	D0			;044: 4840
	RELOC_MOVE	D0,LAB_0008		;046: 33C0000002CA
	SWAP	D0			;04C: 4840
	ADDI.L	#$00000028,D0		;04E: 068000000028
	RELOC_MOVE	D0,LAB_000B		;054: 33C0000002D6
	SWAP	D0			;05A: 4840
	RELOC_MOVE	D0,LAB_000A		;05C: 33C0000002D2
	SWAP	D0			;062: 4840
	ADDI.L	#$00000028,D0		;064: 068000000028
	RELOC_MOVE	D0,LAB_000D		;06A: 33C0000002DE
	SWAP	D0			;070: 4840
	RELOC_MOVE	D0,LAB_000C		;072: 33C0000002DA
	SWAP	D0			;078: 4840
	ADDI.L	#$00000028,D0		;07A: 068000000028
	RELOC_MOVE	D0,LAB_000F		;080: 33C0000002E6
	SWAP	D0			;086: 4840
	RELOC_MOVE	D0,LAB_000E		;088: 33C0000002E2

	lea	COPPERLIST,a1
	lea	copper_start(pc),a0
	move.l	#copper_end-copper_start,d0
	subq.l	#1,d0
.copy
	move.b	(a0)+,(a1)+
	dbf	d0,.copy

	move.l	_resload(pc),a2
	lea	picture_file(pc),a0
	lea	PICTURE_ADDRESS,a1	;0B2: 243A0262
	jsr	(resload_LoadFileDecrunch,a2)		


	MOVE	#$0020,INTENA		;0C6: 33FC002000DFF09A
	move.l	#COPPERLIST,COP1LCH	;0CE: 23FC000002C800DFF080
	MOVE	D0,COPJMP1		;0D8: 33C000DFF088
	lea	PICTURE_ADDRESS,A0	;0DE: 207A0236
	ADDQ.L	#2,A0			;0E2: 5488
	MOVEM.L	(A0)+,D0-D7		;0E4: 4CD800FF
	ANDI.L	#$07770777,D0		;0E8: 028007770777
	ANDI.L	#$07770777,D1		;0EE: 028107770777
	ANDI.L	#$07770777,D2		;0F4: 028207770777
	ANDI.L	#$07770777,D3		;0FA: 028307770777
	ANDI.L	#$07770777,D4		;100: 028407770777
	ANDI.L	#$07770777,D5		;106: 028507770777
	ANDI.L	#$07770777,D6		;10C: 028607770777
	ANDI.L	#$07770777,D7		;112: 028707770777
	ADD.L	D0,D0			;118: D080
	ADD.L	D1,D1			;11A: D281
	ADD.L	D2,D2			;11C: D482
	ADD.L	D3,D3			;11E: D683
	ADD.L	D4,D4			;120: D884
	ADD.L	D5,D5			;122: DA85
	ADD.L	D6,D6			;124: DC86
	ADD.L	D7,D7			;126: DE87
	MOVEM.L	D0-D7,COLOR00		;128: 48F900FF00DFF180
	MOVE	#$00C7,D0		;130: 303C00C7
LAB_0000:
	MOVEQ	#39,D1			;134: 7227
	LEA	LAB_0015(pc),A1		;136: 43F90000032A
LAB_0001:
	MOVE.L	(A0)+,(A1)+		;13C: 22D8
	DBF	D1,LAB_0001		;13E: 51C9FFFC
	LEA	(-160,A0),A0		;142: 41E8FF60
	LEA	(-160,A1),A1		;146: 43E9FF60
	MOVEQ	#19,D1			;14A: 7213
LAB_0002:
	MOVE	(A1)+,(A0)		;14C: 3099
	MOVE	(A1)+,(40,A0)		;14E: 31590028
	MOVE	(A1)+,(80,A0)		;152: 31590050
	MOVE	(A1)+,(120,A0)		;156: 31590078
	ADDQ.L	#2,A0			;15A: 5488
	DBF	D1,LAB_0002		;15C: 51C9FFEE
	LEA	(120,A0),A0		;160: 41E80078
	DBF	D0,LAB_0000		;164: 51C8FFCE
	MOVE	#$4000,BPLCON0		;168: 33FC400000DFF100
	MOVE	#$0000,BPLCON1		;170: 33FC000000DFF102
	MOVE	#$0038,DDFSTRT		;178: 33FC003800DFF092
	MOVE	#$00D0,DFFSTOP		;180: 33FC00D000DFF094
	MOVE	#$3A81,DIWSTRT		;188: 33FC3A8100DFF08E
	MOVE	#$02C1,DIWSTOP		;190: 33FC02C100DFF090
	MOVE	#$0078,BPL1MOD		;198: 33FC007800DFF108
	MOVE	#$0078,BPL2MOD		;1A0: 33FC007800DFF10A

	MOVE.L	#$00000000,SPR0DATA	;1B0: 23FC0000000000DFF144
	MOVE.L	#$00000000,SPR1DATA	;1BA: 23FC0000000000DFF14C
	MOVE.L	#$00000000,SPR2DATA	;1C4: 23FC0000000000DFF154
	MOVE.L	#$00000000,SPR3DATA	;1CE: 23FC0000000000DFF15C
	MOVE.L	#$00000000,SPR4DATA	;1D8: 23FC0000000000DFF164
	MOVE.L	#$00000000,SPR5DATA	;1E2: 23FC0000000000DFF16C
	MOVE.L	#$00000000,SPR6DATA	;1EC: 23FC0000000000DFF174
	MOVE.L	#$00000000,SPR7DATA	;1F6: 23FC0000000000DFF17C

	move.w	#$8380,DMACON
	move.l	buttonwait(pc),D2
	beq.b	.skip	
.loop
	btst	#6,$bfe001
	beq.b	.skip
	btst	#7,$BFE001
	bne.b	.loop
.skip
	lea	game_file(pc),a0
	lea	BASE_ADDRESS-$1C,a1
	move.l	_resload(pc),a2
	jsr	resload_LoadFileDecrunch(a2)

	MOVE.L	#$00000000,COLOR00	;250: 23FC0000000000DFF180
	MOVE.L	#$00000000,COLOR02	;25A: 23FC0000000000DFF184
	MOVE.L	#$00000000,COLOR04	;264: 23FC0000000000DFF188
	MOVE.L	#$00000000,COLOR06	;26E: 23FC0000000000DFF18C
	MOVE.L	#$00000000,COLOR08	;278: 23FC0000000000DFF190
	MOVE.L	#$00000000,COLOR10	;282: 23FC0000000000DFF194
	MOVE.L	#$00000000,COLOR12	;28C: 23FC0000000000DFF198
	MOVE.L	#$00000000,COLOR14	;296: 23FC0000000000DFF19C
	ORI	#$0700,SR		;2EC: 007C0700

	movem.l	D0-D1/A0-A2,-(A7)

	move.l	(_resload,pc),a2	
	sub.l	A1,A1
	lea	pl_main(pc),A0
	jsr	(resload_Patch,a2)

	; load score

	move.l	(_resload,pc),a2	
	lea	scorename(pc),a0
	lea	SCORESTART,A1
	jsr	(resload_LoadFile,a2)
	movem.l	(A7)+,D0-D1/A0-A2

	JMP	BASE_ADDRESS

save_score:
.loop
	move.b	(A0)+,(A4)+
	dbf	D0,.loop	; stolen code

	; save score

	movem.l	D0-D1/A0-A2,-(A7)
	move.l	custom1(pc),d0
	bne.b	.skip		; don't save if trainer on

	move.l	(_resload,pc),a2	
	lea	scorename(pc),a0
	lea	SCORESTART,A1
	move.l	#SCORELEN,D0
	moveq.l	#0,D1
	jsr	(resload_SaveFileOffset,a2)

.skip
	movem.l	(A7)+,D0-D1/A0-A2
	rts

kbint:
	move.b	($BFEC01),D0
	movem.l	D0,-(A7)
	ror.b	#1,d0
	not.b	d0
	cmp.b	_keyexit(pc),d0		; quit game
	beq.b	quit

	cmp.b	#69,D0			; ESC: no more lives
	bne.b	.noesc
	move.w	#1,$84A.W
.noesc

	cmp.b	#$42,D0			; TAB: train
	bne.b	.skip
	move.l	custom1(pc),D0
	beq.b	.skip
	eor.b	#$19,$4B4C.W	; toggles trainer
	movem.l	a2,-(a7)
	move.l	(_resload,pc),a2
	jsr	(resload_FlushCache,a2)
	movem.l	(A7)+,a2
.skip
	movem.l	(A7)+,d0
	rts

kbdelay:
	moveq.l	#2,D0
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

pl_main:
	PL_START
	PL_S	$BF2,$C0C-$BF2	; skip trap redirect
	PL_S	$C36,$C4E-$C36	; skip cia access
	PL_PS	$6F24,save_score
	PL_PS	$8EA,kbint
	PL_PS	$934,kbdelay
	PL_PS	$64F4,dbf_emu
	PL_END

copper_start
LAB_0007:
	DC.W	$00E0
LAB_0008:
	dc.l	$000000E2
LAB_0009:
	dc.l	$000000E4
LAB_000A:
	dc.l	$000000E6
LAB_000B:
	dc.l	$000000E8
LAB_000C:
	dc.l	$000000EA
LAB_000D:
	dc.l	$000000EC
LAB_000E:
	dc.l	$000000EE
LAB_000F:
	DC.W	$0000			;2E6
	DC.W	$FFFF			;2E8
	DC.W	$FFFE			;2EA
copper_end

file_size:
	ORI.B	#$00,D0			;31A: 00000000
LAB_0015:
	blk.b	$A0,0

picture_file:
	dc.b	"pic.pi1",0
game_file:
	dc.b	"fmd",0
scorename:
	dc.b	"Highs",0
data
	dc.b	"data",0
	even


tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
		dc.l	WHDLTAG_BUTTONWAIT_GET
buttonwait	dc.l	0
		dc.l	0

;--------------------------------

_resload	dc.l	0		;address of resident loader

dbf_emu
	move.l	#13,d0
	bsr	_beamdelay
	add.l	#2,(a7)
	rts

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


