;*---------------------------------------------------------------------------
;  :Program.	CyberpunksHD.asm
;  :Contents.	Slave for "Cyberpunks" from 
;  :Author.	Keith Krellwitz
;  :Version.	$Id: cyberpunks.asm 1.2 2000/12/28 00:00:10 jah Exp jah $
;  :History.	09.05.98
;		27.12.00 Wepl reworked, cacr access fixed
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Phxass
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"Cyberpunks.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

pushall:MACRO
	movem.l	d0-a6,-(a7)
	ENDM

pullall:MACRO
	movem.l	(a7)+,d0-a6
	ENDM

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_NoKbd	;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	$80000			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
;============================================================================
_config
        dc.b    "C1:X:Trainer Infinite Lives:0;"
        dc.b    "C1:X:Trainer Infinite Time:1;"
        
		dc.b	0
        
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.3"
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
	dc.b	0

_name		dc.b	"Cyberpunks",0
_copy		dc.b	"1993 Mutation Software & Core Design Ltd.",0
_info		dc.b	"Installed & fixed by",10,"Keith Krellwitz/Abaddon & Wepl & JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
	EVEN

    include ReadJoyPad.s
    
;============================================================================
_start	;	A0 = resident loader
;============================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)					;save for later use

	move.l  #$0,d0
	lea     $5c40,a0
	move.l  #$0,d1			;offset
	move.l  #$4,d2			;length
	bsr	loadtracks
	patch 	$5cd6,jumper
	bsr	_flushcache
	jmp     $5c4c

jumper:
	waitvb
	move.w	#$7FFF,$dff096
	move.w	#$7FFF,$dff09A

	move.l  #$0,d0
	lea     $400,a0
	move.l  #$16,d1			;offset
	move.l  #$266,d2		;length
	bsr	loadtracks

	move	#$2100,SR	; stolen

	lea	$400,a7
	
	bra	decrunch_400


_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts



jumper3:
    bsr _detect_controller_types
	lea	$229D6,a0
	lea	decrunch(pc),a1
	move.w	#$351,d0
.copy
	move.b	(a0)+,(a1)+
	dbf	d0,.copy


    sub.l   a1,a1
    lea pl_main(pc),a0
    move.l  _resload(pc),a2
    jsr resload_Patch(a2)
    


	jmp     $400.W

pl_main
    PL_START
	PL_P	$22d32,loadtracks
	PL_P	$7e1a,prot1
	PL_P	$7194,memory
	PL_L	$74f8,$600008f6,
	PL_L	$17d18,$4ef90001,
	PL_W	$17d1c,$870e,
	PL_R	$6f12			;cacr
	PL_S	$6e46,8			;dsksel
	PL_S	$6eee,8			;beamcon0
	PL_ORW	$21792,$200		;bplcon0
	PL_ORW	$21a16,$200		;bplcon0
	PL_ORW	$21ee6,$200		;bplcon0
	PL_P	$229D6,decrunch
    PL_PS	$705C,quitkey_test
    
    ; joypad controls
    PL_ORW  $06e60+2,$20        ; enable vertical blank
    PL_PA   $6E58+2,level3_interrupt
    PL_PS   $21732,read_joy1dat

    PL_PSS  $074c2,read_fire,2
    PL_PSS  $07eec,read_fire,2
    PL_PSS  $07fde,read_fire,2
    PL_PSS  $080cc,read_fire,2
    PL_PSS  $081ba,read_fire,2
    PL_PSS  $08298,read_fire,2
    PL_PSS  $08328,read_fire,2
    PL_PSS  $085a0,read_fire,2
    PL_PSS  $08b40,read_fire,2
    PL_PSS  $08bbe,read_fire,2
    PL_PSS  $09c42,read_fire,2
    PL_PSS  $09d66,read_fire,2
    PL_PSS  $09e60,read_fire,2
    PL_PSS  $09f78,read_fire,2
    PL_PSS  $0a072,read_fire,2
    PL_PSS  $0a18a,read_fire,2
    PL_PSS  $0a284,read_fire,2
    PL_PSS  $0a39c,read_fire,2
    PL_PSS  $0a496,read_fire,2
    PL_PSS  $0a5a2,read_fire,2
    PL_PSS  $0a69c,read_fire,2
    PL_PSS  $0a7b6,read_fire,2
    PL_PSS  $0a8b0,read_fire,2
    PL_PSS  $1263e,read_fire,2
    PL_PSS  $15cf2,read_fire,2
    PL_PSS  $15e02,read_fire,2
    PL_PSS  $17a28,read_fire,2
    PL_PSS  $17a68,read_fire,2
    PL_PSS  $17ce2,read_fire,2
    PL_PSS  $186d4,read_fire,2
    PL_PSS  $187f2,read_fire,2
    PL_PSS  $1881e,read_fire,2
    PL_PSS  $1884e,read_fire,2
    PL_PSS  $20e2a,read_fire,2
    PL_PSS  $21680,read_fire,2
    PL_PSS  $2176a,read_fire,2
        
    ; blitter
	PL_PS	$1ecc6,blitshit1
	PL_PS	$1ecb2,blitshit1
	PL_PS	$1ec9e,blitshit1
	PL_PS	$1ec8a,blitshit1
	PL_PS	$1ec6e,blitshit1
	PL_PS	$1ec5e,blitshit1
	PL_PS	$1ec4e,blitshit1
	PL_PS	$1ec3e,blitshit1
	PL_PS	$178ee,wt
	PL_PS	$156c6,wt
	PL_PS	$14c22,wt
	PL_PS	$14bd0,wt
	PL_PS	$11df0,wt
	PL_PS	$1167a,wt
	PL_PS	$1168a,wt
	PL_PS	$1169a,wt
	PL_PS	$116aa,wt
	PL_PS	$116ba,wt
	PL_PS	$116ca,wt
	PL_PS	$116da,wt
	PL_PS	$116ea,wt
	PL_PS	$116fa,wt
	PL_PS	$1170a,wt
	PL_PS	$1171a,wt
	PL_PS	$1172a,blitshit2
    
    ; trainer
    
    ; infinite time
    PL_IFC1X    1
    PL_R    $1716e
    PL_ENDIF
    ; infinite lives for all 3 characters
    
    PL_IFC1X    0
    PL_S    $1652c,8
    PL_S    $16548,8
    PL_S    $16560,8
    PL_S    $165ca,8
    PL_S    $165e6,8
    PL_S    $165fe,8
    PL_S    $16668,8
    PL_S    $16684,8
    PL_S    $1669c,8
    PL_ENDIF
    PL_END

BTNTEST:MACRO
    btst    #JPB_BTN_\1,d1
    bne.b   .\1_was_pressed
    btst    #JPB_BTN_\1,d0
    beq.b   .out\1
    st.b   (\2,a1)  ; space pressed
    bra.b   .out\1
.\1_was_pressed    
    btst    #JPB_BTN_\1,d0
    bne.b   .out\1
    clr.b   (\2,a1)  ; space released
.out\1
    ENDM
   
read_fire
    movem.l d0,-(a7)
    move.l  joy1(pc),d0
    not.l   d0
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0
    rts
    
level3_interrupt
    MOVEM.L	D0-D7/A0-A6,-(A7)
    move.w  _custom+intreqr,d0
    btst    #5,d0
    bne.b   .vbl
    jmp $06f22  ; copper
.vbl
    bsr _joystick
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .noquit
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noquit
    btst    #JPB_BTN_YEL,d0
    bne quit
.noquit    
    
    LEA	$7093,A1		;144ca: 43f90000
    lea _prev_joy1_buttons(pc),a0
    move.l  (a0),d1
    move.l  joy1(pc),d0
    BTNTEST BLU,$40
    BTNTEST PLAY,$19
    BTNTEST YEL,$44

    btst    #JPB_BTN_GRN,d0
    beq.b   .nogreen
    BTNTEST UP,$4C
    BTNTEST DOWN,$4D
    BTNTEST LEFT,$4F
    BTNTEST RIGHT,$4E
    
.nogreen
    BTNTEST REVERSE,$43
    tst.b   ($43,a1)
    beq.b   .noesc
    BTNTEST FORWARD,$45

.out
    move.l  d0,(a0)
    move.w  #$20,_custom+intreq
	MOVEM.L	(A7)+,D0-D7/A0-A6	;06f30: 4cdf7fff
	RTE				;06f34: 4e73
.noesc
    clr.b   ($45,a1)
    bra.b   .out
    
read_joy1dat
    move.l  joy1(pc),d0
    btst    #JPB_BTN_GRN,d0
    beq.b   .no_green
    ; when green is pressed, we use joystick to simulate
    ; keypresses, so the characters can't move in the meantime
    moveq.l #0,d0
    rts
.no_green
    MOVE.W	_custom+joy1dat,D0		;21732: 303900dff00c
    rts
    
quitkey_test
	bset	#0,$bfee01	; original
	move.l	D0,-(a7)
	not.b	d0
	ror.b	#1,d0
	cmp.b	_keyexit(pc),d0
	bne.b	noq
quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

noq
	move.l	(a7)+,d0
	rts

prot1:
	move.l	#$c71b94ea,d7	; copylock
    move.l  d7,$100.W   ; just in case... (issue #002441)
	jmp	$22824

memory:
	clr.l	$0
;	move.l	#$80000,d0
	move.l	_expmem(pc),d0
	move.l	d0,$731a.w
	rts


blitshit1:
	move.w	d5,$dff058	
	bra		wt
blitshit2:
	adda.l	#$2,a0
wt:
	btst	#$6,$dff002
.w
	btst	#$6,$dff002
	bne		.w
	rts

loadtracks:
	movem.l	d1-d2/a0-a2,-(a7)
	moveq	#$0,d0
	move.w	d1,d0
	mulu.w	#512,d0			;offset
	moveq	#$0,d1
	move.w	d2,d1
	mulu.w	#512,d1			;size
	move.l	#$1,d2
	move.l	(_resload,pc),a2
	jsr	(resload_DiskLoad,a2)
	movem.l	(a7)+,d1-d2/a0-a2
	moveq	#0,d0			;zero means success
	rts

; first RN decrunch routine copied here

decrunch_400:
	MOVEM.L	D0-D7/A0-A7,-(A7)	;000: 48E7FFFF

	lea	$580.W,a0

	LEA	decrunch_400(PC),A1	;008: 43FAFFF6
	BSR.S	.lab_0006		;00C: 6158
	CMP.L	#$524E4301,D0		;00E: B0BC524E4301
	BNE.S	.lab_0004		;014: 664A
	BSR.S	.lab_0006		;016: 614E
	LEA	4(A0),A4		;018: 49E80004
	LEA	0(A4,D0.L),A2		;01C: 45F40800
	ADDA	#$0100,A2		;020: D4FC0100
	MOVEA.L	A2,A3			;024: 264A
	BSR.S	.lab_0006		;026: 613E
	LEA	0(A4,D0.L),A6		;028: 4DF40800
	MOVE.B	-(A6),D3		;02C: 1626
.lab_0001:
	BSR.S	.lab_0008		;02E: 6142
	ADDQ	#1,D5			;030: 5245
	CMPA.L	A4,A6			;032: BDCC
	BLE.S	.lab_0003		;034: 6F22
	BSR	.lab_0013		;036: 61000090
	BSR	.lab_001A		;03A: 610000C0
	SUBQ	#1,D6			;03E: 5346
	LEA	0(A3,D7),A0		;040: 41F37000
	EXT.L	D6			;044: 48C6
	ADDA.L	D6,A0			;046: D1C6
	TST	D7			;048: 4A47
	BNE.S	.lab_0002		;04A: 6604
	LEA	1(A3),A0		;04C: 41EB0001
.lab_0002:
	MOVE.B	-(A0),-(A3)		;050: 1720
	DBF	D6,.lab_0002		;052: 51CEFFFC
	BRA.S	.lab_0001		;056: 60D6
.lab_0003:
	MOVE.L	A2,D0			;058: 200A
	SUB.L	A3,D0			;05A: 908B
	MOVEA.L	A3,A0			;05C: 204B
	BRA.S	.lab_0005		;05E: 6002
.lab_0004:
	MOVEQ	#0,D0			;060: 7000
.lab_0005:
	BRA	.lab_0022		;062: 600000E6
.lab_0006:
	MOVEQ	#3,D1			;066: 7203
.lab_0007:
	LSL.L	#8,D0			;068: E188
	MOVE.B	(A0)+,D0		;06A: 1018
	DBF	D1,.lab_0007		;06C: 51C9FFFA
	RTS				;070: 4E75
.lab_0008:
	MOVEQ	#-1,D5			;072: 7AFF
	BSR.S	.lab_0011		;074: 6148
	BCC.S	.lab_000E		;076: 643C
	MOVEQ	#0,D5			;078: 7A00
	BSR.S	.lab_0011		;07A: 6142
	BCC.S	.lab_000C		;07C: 642C
	MOVEQ	#3,D1			;07E: 7203
.lab_0009:
	CLR	D5			;080: 4245
	MOVE.B	.lab_000F(PC,D1),D0	;082: 103B1032
	EXT	D0			;086: 4880
	MOVEQ	#-1,D2			;088: 74FF
	LSL	D0,D2			;08A: E16A
	NOT	D2			;08C: 4642
	SUBQ	#1,D0			;08E: 5340
.lab_000A:
	BSR.S	.lab_0011		;090: 612C
	ROXL	#1,D5			;092: E355
	DBF	D0,.lab_000A		;094: 51C8FFFA
	TST	D1			;098: 4A41
	BEQ.S	.lab_000B		;09A: 6706
	CMP	D5,D2			;09C: B445
	DBNE	D1,.lab_0009		;09E: 56C9FFE0
.lab_000B:
	MOVE.B	.lab_0010(PC,D1),D0	;0A2: 103B1016
	EXT	D0			;0A6: 4880
	ADD	D0,D5			;0A8: DA40
.lab_000C:
	MOVE	D5,-(A7)		;0AA: 3F05
.lab_000D:
	MOVE.B	-(A6),-(A3)		;0AC: 1726
	DBF	D5,.lab_000D		;0AE: 51CDFFFC
	MOVE	(A7)+,D5		;0B2: 3A1F
.lab_000E:
	RTS				;0B4: 4E75
.lab_000F:
	DC.W	$0A03			;0B6
	DC.W	$0202			;0B8
.lab_0010:
	DC.W	$0E07			;0BA
	DC.W	$0401			;0BC
.lab_0011:
	LSL.B	#1,D3			;0BE: E30B
	BNE.S	.lab_0012		;0C0: 6604
	MOVE.B	-(A6),D3		;0C2: 1626
	ROXL.B	#1,D3			;0C4: E313
.lab_0012:
	RTS				;0C6: 4E75
.lab_0013:
	MOVEQ	#3,D0			;0C8: 7003
.lab_0014:
	BSR.S	.lab_0011		;0CA: 61F2
	BCC.S	.lab_0015		;0CC: 6404
	DBF	D0,.lab_0014		;0CE: 51C8FFFA
.lab_0015:
	CLR	D6			;0D2: 4246
	ADDQ	#1,D0			;0D4: 5240
	MOVE.B	.lab_0018(PC,D0),D1	;0D6: 123B001A
	BEQ.S	.lab_0017		;0DA: 670C
	EXT	D1			;0DC: 4881
	SUBQ	#1,D1			;0DE: 5341
.lab_0016:
	BSR.S	.lab_0011		;0E0: 61DC
	ROXL	#1,D6			;0E2: E356
	DBF	D1,.lab_0016		;0E4: 51C9FFFA
.lab_0017:
	MOVE.B	.lab_0019+1(PC,D0),D1	;0E8: 123B000D
	EXT	D1			;0EC: 4881
	ADD	D1,D6			;0EE: DC41
	RTS				;0F0: 4E75
.lab_0018:
	DC.W	$0A02			;0F2
	dc.w	$0100
.lab_0019:
	DC.W	$000A			;0F6
	DC.W	$0604			;0F8
	dc.w	$0302
.lab_001A:
	MOVEQ	#0,D7			;0FC: 7E00
	CMP	#$0002,D6		;0FE: BC7C0002
	BEQ.S	.lab_001E		;102: 6722
	MOVEQ	#1,D0			;104: 7001
.lab_001B:
	BSR.S	.lab_0011		;106: 61B6
	BCC.S	.lab_001C		;108: 6404
	DBF	D0,.lab_001B		;10A: 51C8FFFA
.lab_001C:
	ADDQ	#1,D0			;10E: 5240
	MOVE.B	.lab_0020(PC,D0),D1	;110: 123B002C
	EXT	D1			;114: 4881
.lab_001D:
	BSR.S	.lab_0011		;116: 61A6
	ROXL	#1,D7			;118: E357
	DBF	D1,.lab_001D		;11A: 51C9FFFA
	LSL	#1,D0			;11E: E348
	ADD	.lab_0021(PC,D0),D7	;120: DE7B0020
	RTS				;124: 4E75
.lab_001E:
	MOVEQ	#5,D0			;126: 7005
	CLR	D1			;128: 4241
	BSR.S	.lab_0011		;12A: 6192
	BCC.S	.lab_001F		;12C: 6404
	MOVEQ	#8,D0			;12E: 7008
	MOVEQ	#64,D1			;130: 7240
.lab_001F:
	BSR.S	.lab_0011		;132: 618A
	ROXL	#1,D7			;134: E357
	DBF	D0,.lab_001F		;136: 51C8FFFA
	ADD	D1,D7			;13A: DE41
	RTS				;13C: 4E75
.lab_0020:
	dc.w	$0B04
	dc.w	$0700
.lab_0021:
	dc.w	$0120
	dc.l	$20
	DC.W	$0000			;148
.lab_0022:
	lea	$400.w,a1
	MOVE.L	A0,D1			;14A: 2208
	SUB.L	A1,D1			;14C: 9289
	MOVE.L	#$005C4E75,-(A7)	;14E: 2F3C005C4E75
	MOVE.L	#$00204FEF,-(A7)	;154: 2F3C00204FEF
	MOVE.L	#$4CEF7FFF,-(A7)	;15A: 2F3C4CEF7FFF
	MOVE.L	#$538166FA,-(A7)	;160: 2F3C538166FA
	MOVE.L	#$66FA4219,-(A7)	;166: 2F3C66FA4219
	MOVE.L	#$12D85380,-(A7)	;16C: 2F3C12D85380
	MOVE.L	#$2549005C,-(A7)	;172: 2F3C2549005C
	MOVE.L	#$45FAFFFE,-(A7)	;178: 2F3C45FAFFFE

	patch	$3ba,jumper3


	bsr	_flushcache
    
	jmp	$3a0.w

decrunch
	ds.b	$360,0

;--------------------------------

_resload	dc.l	0		;address of resident loader
_prev_joy1_buttons  dc.l    0
;======================================================================

	END
