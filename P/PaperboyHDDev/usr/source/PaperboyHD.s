
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	Paperboy.slave
	OPT	O+ OG+			;enable optimizing
	ENDC
	
;======================================================================

TRACK_SIZE	EQU	$1700
DISC_SIZE	EQU	TRACK_SIZE*160
BOOT_SIZE	EQU	11*512

OFFS_LOADER1	EQU	$112
OFFS_GOTRACK0	EQU	$BA
OFFS_JMP_MAIN	EQU	$B4

OFFS_LOAD2	EQU	$4F39E
OFFS_GOTRACK02	EQU	$4F346
OFFS_JMP_MAIN2	EQU	$4F196

OFFS_LOAD3	EQU	$1C24
OFFS_GOTRACK03	EQU	$1B82

OFFS_KBDIRQ	EQU	$2440

OFFS_DESTTRK1	EQU	$A74
OFFS_DESTTRK2	EQU	$4F58C
OFFS_DESTTRK3	EQU	$1FA6

OFFS_IRQ	EQU	$2440
OFFS_SETIRQ	EQU	$8C0

OFFS_ACCESSMEM1	EQU	$25DA
OFFS_ACCESSMEM2	EQU	$1AE2
OFFS_ACCESSMEM3	EQU	$1B1A
OFFS_ACCESSMEM4	EQU	$2DF0

OFFS_IRQ2	EQU	$2232
OFFS_IRQ3	EQU	$22C4


_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError	;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
		dc.b	0		;ws_keydebug = F9
_keyexit	dc.b	$59		;ws_keyexit = F10
_expmem		
	dc.l	$80000			;ws_ExpMem

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	
_data   dc.b    0
_name	dc.b	'Paperboy',0
_copy	dc.b	'1989 Elite',0
_info
    dc.b   'adapted by Ralf & JOTD',10,10
	dc.b	"Version "
	DECL_VERSION
	dc.b	0
	
_config
	dc.b	"BW;"
    ;dc.b    "C1:X:Infinite lives:0;"
	dc.b	0

	dc.b	'$VER: Paperboy by Ralf & JOTD - '
	DECL_VERSION
	dc.b	0
	CNOP 0,2


;======================================================================
Start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
	
	move.l	_resload(pc),a2
	MOVE.L	_expmem(pc),A0
	MOVEQ	#0,D0       ; offset
	MOVE.L	#BOOT_SIZE,D1   ; size
	moveq.l	#1,D2       ; disk number: 0
	jsr	(resload_DiskLoad,a2)

	MOVE.L	_expmem(PC),A1
	lea	pl_boot(pc),a0
	jsr	resload_Patch(a2)

    MOVE	#0,SR
	MOVE.L	_expmem(PC),A0
	JMP	12(A0)

pl_boot
	PL_START
	PL_R	OFFS_GOTRACK0
	PL_P	OFFS_LOADER1,MY_LOADER
	PL_P	OFFS_JMP_MAIN,MY_MAIN
	PL_END


MY_MAIN
	MOVEM.L	A0-A2/D0-D1,-(A7)
	move.l	_resload(pc),a2
	sub.l	a1,a1
	lea	pl_main(pc),a0
	jsr	resload_Patch(a2)


	LEA	DEST_TRACK(PC),A0
	MOVE.L	#OFFS_DESTTRK2,(A0)

	MOVEM.L	(A7)+,D0-D1/A0-A2

	JMP	$4F01C

pl_main
	PL_START
	PL_P	OFFS_LOAD2,MY_LOADER
	PL_R	OFFS_GOTRACK02
	PL_P	OFFS_JMP_MAIN2,MY_MAIN2
	PL_END

copper_write:
;;;	cmp.l	#$00020507,$564

	move.w	d6,($82,a5)
	tst.w	(a0)
	rts

MY_MAIN2
	MOVEM.L	D0-D1/A0-A2,-(A7)
    move.l  _resload(pc),a2
    sub.l   a1,a1
    lea pl_main2(pc),a0
    jsr resload_Patch(a2)
    


	; fix illegal blitwait programming (by access to $DFF000 longword)

;	lea	$100.W,A0
;	lea	$3000.W,A1
;	lea	.blitwait(pc),A2
;	move.l	#6,D0
;.rloop
;	JSRGEN	HexSearch
;	cmp.l	#0,A0
;	beq.b	.end
;	PATCHUSRJSR	(A0),WaitBlit
;	bra.b	.rloop
;	
;.end


	move.l	buttonwait(pc),D0
	beq.b	.out
.loop
	btst	#7,$bfe001
	bne.b	.loop
.release
	btst	#7,$bfe001
	beq.b	.release
.out
	MOVEM.L	(A7)+,D0-D1/A0-A2
	
	JMP	$800.W
    
pl_main2
    PL_START
    PL_PS	$214C,copper_write
	; fix snoop bug (probably ports direction change)
    PL_NOP  $250E,6
    
	PL_P	OFFS_LOAD3,MY_LOADER
	PL_R	OFFS_GOTRACK03

	PL_A    OFFS_ACCESSMEM1,_expmem
	PL_A    OFFS_ACCESSMEM2,_expmem
	PL_A    OFFS_ACCESSMEM3,_expmem
	PL_A    OFFS_ACCESSMEM4,_expmem

	PL_P	OFFS_SETIRQ,MY_SETIRQ

    PL_A	OFFS_DESTTRK3,DEST_TRACK
    
    PL_END
    
;.blitwait:
	;dc.w	$2015,$D040,$6BFA

wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts
    
MY_SETIRQ
	PEA	$21F0
	MOVE.L	A0,A7
	
	MOVE.B	#$7F,$BFED01
	MOVE.B	#$7F,$BFDD00

	LEA	OLD_IRQ(PC),A0
	MOVE.L	$68.W,(A0)
	LEA	MY_KBD(PC),A0
	MOVE.L	A0,$68.W
	RTS

;	MOVE.L	D0,-(A7)
;	MOVE.L	#$400,D0
;	JSRGEN	StoreCopperPointer
;	MOVE.L	(A7)+,D0
;	RTS

MY_LOADER
	movem.l	D0-D2/A0-A2,-(a7)

	MOVEQ	#0,D1
	MOVE.L	DEST_TRACK(PC),A1
	MOVE	(A1),D0
	
	MULU	#TRACK_SIZE,D0	; offset
	move.l	A6,A0		; destination
	move.l	D5,D1		; length
	moveq.l	#1,D2		; disk 1
	move.l  _resload(pc),a2
    jsr resload_DiskLoad(a2)
	
	movem.l	(a7)+,D0-D2/A0-A2
	RTS

MY_KBD
	MOVE.L	D0,-(A7)
	
	MOVE.B	$BFEC01,D0
	ror.b	#1,D0
	not.b	D0

	cmp.b	_keyexit(pc),D0
	BNE.S	.noquit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit
	MOVE.L	(A7)+,D0
	MOVE.L	OLD_IRQ(PC),-(A7)
	RTS

BOOT_MEM
	dc.l	0

OLD_KBDIRQ
	dc.l	0

OLD_IRQ
	dc.l	0

DEST_TRACK
	ds.L	1,OFFS_DESTTRK1


Tags		dc.l	WHDLTAG_BUTTONWAIT_GET
buttonwait:		dc.l	0

		dc.l	0

_resload
	dc.l	0
