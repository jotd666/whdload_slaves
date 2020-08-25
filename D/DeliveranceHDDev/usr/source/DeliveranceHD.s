;*---------------------------------------------------------------------------
;  :Program.	deliveranceslave.asm
;  :Contents.	Slave for "Deliverance"
;  :Author.	Harry
;  :History.	21.05.97
;  :Requires.	whdload-package :)
;  :Copyright.	Freeware
;  :Language.	68000 Assembler
;  :Translator.	ASM-One 1.25
;  :To Do.
;---------------------------------------------------------------------------*

;crc_v1	= $baec
;crc_v2	= $a12d

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"Deliverance.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

; game doesn't work properly when 32-bit memory is set
;USE_FASTMEM

;======================================================================

_base		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem	;ws_flags
		IFD	USE_FASTMEM
		dc.l	$80000
		ELSE
		dc.l	$100000		;ws_BaseMemSize			;$bc000
		ENDC
		dc.l	$0		;ws_ExecInstall
		dc.w	_start-_base	;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem
		IFD	USE_FASTMEM
		dc.l	$80000
		ELSE
		dc.l	0			;ws_ExpMem
		ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

_config
        dc.b    "C1:X:Trainer Infinite Lives:0;"
        dc.b    "C1:X:Trainer Infinite Energy:1;"
        dc.b    "C2:B:Second/blue button jumps;"
		dc.b	0
	

;======================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"2.0"
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

_data		dc.b	"data",0
_name		dc.b	"Deliverance"
;	IFND	USE_FASTMEM
;	dc.b	" (DEBUG MODE)"
;	ENDC
	dc.b	0
_copy		dc.b	"1990 21st Century Entertainment",0
_info		dc.b	"Install & fix by Harry & JOTD",10,10
			dc.b	"CD32 play pauses",10
            dc.b    "CD32 fwd+yellow / help skips levels",10
            dc.b    "1-6 keys selects current level",10
			dc.b	"CD32 rev+fwd when paused aborts",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

	include	ReadJoyButtons.s

;======================================================================
_start	;	A0 = resident loader
;======================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using
	IFD	USE_FASTMEM
		lea	EXTRAMEM(pc),a0
		move.l	_expmem(pc),(a0)
	ENDC
;		move.l	#CACRF_EnableI,d0	;enable instruction cache
;		move.l	d0,d1			;mask
;		jsr	(resload_SetCACR,a0)

	bsr	_detect_controller_type
	
	IFD	CHECKDISK
	;check disk version
		move.l	#$5aa00,d0	;offset
		move.l	#$2c00,d1	;size
		moveq	#1,d2		;disk
		lea	$1000,a0	;data
		movem.l	d1/a0,-(a7)
		move.l	(_resload,pc),a3
		jsr	(resload_DiskLoad,a3)

		movem.l	(a7)+,d0/a0
		jsr	(resload_CRC16,a3)

		moveq	#1,d1
		cmp.w	#crc_v1,d0
		beq	.set
		moveq	#2,d1
		cmp.w	#crc_v2,d0
		beq	.set
		bra	_badver
.set		lea	_version,a0
		move.w	d1,(a0)
	ENDC


	LEA.L	$DFF000,A6
	LEA.L	$80000,A7
	MOVE.W	#$8650,$DFF096
	MOVE.L	EXTRAMEM(PC),A4
	LEA.L	$6800(A4),A4
	MOVE.L	A4,A0
	MOVEQ.L	#3,D0
	BSR.W	LOADROUT
	LEA.L	-$4000(A7),A1
	MOVEQ.L	#4,D0
	LEA.L	-$4000(A1),A0
	BSR.W	LOADROUT
	BSR	RELOC

;MODIFY
	MOVE.L	EXTRAMEM(PC),A0
	MOVE.L	a0,a1
	LEA.L	LENTAB(PC),A2
	MOVE.W	#$A4-1,D0
.1	MOVE.B	(A2)+,(A1)+
	DBF	D0,.1
	
;	MOVE.L	#$33fc000f,$86afc
;	MOVE.L	#$dff180,$86afc+4
;	MOVE.W	#$60f6,$86afc+8

	move.l	EXTRAMEM(pc),A0
	move.l	A0,A1
	add.l	#$40000,A1
	lea	.blit_string(pc),a2
	move.l	#12,D0
.loop
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.out

	move.l	#$4E714EB9,(A0)+
	pea	_waitblit(pc)
	move.l	(A7)+,(A0)+
	move.l	#$4E714E71,(A0)+
	bra.b	.loop
.out

	move.l	_resload(pc),a2
	lea	_pl_prog(pc),a0
	MOVE.L	EXTRAMEM(PC),A1
	jsr	resload_Patch(a2)

	; install our own dummy keyboard interrupt routine
	; so keyboard works
	pea	keyboard_interrupt(pc)
	move.l	(A7)+,$68.W

	JMP	8(A4)

.blit_string:
	dc.l	$4A6E0002,$082E000E,$000266F8

_pl_prog:
	PL_START
	; remove interrupt vector trashing
	PL_W	$683E,$6006
	; enable keyboard interrupts
	PL_W	$688E+2,$C038

	PL_PS	$DBDC,CHANGESND
	PL_PS	$D350,LOADING1
	PL_PS	$D392,LOADING2

	; completely skip broken keyboard handling
	PL_PS	$69FA,KEYHP
	PL_W	$6A00,$6022

	PL_R	$D844

	PL_PS	$994C,_waitandloada6
	PL_PS	$B396,_waitandloada6
	PL_PS	$AEDA,_waitandsetmask
	
    PL_PSS   $6BFE,before_game_startup,2
    
	PL_IFC2
	PL_PS	$68ca,joypad_hook
	PL_ELSE
	PL_PS	$68ca,joystick_hook
	PL_ENDIF
	
	; infinite lives
	PL_IFC1X    0
	PL_W	$6DF0,$6006
	PL_ENDIF
    ; infinite energy
    PL_IFC1X    1
    PL_NOP  $7170,2
    PL_ENDIF
	PL_END


KEYCODE_COPY = $20B

before_game_startup
    bsr _detect_controller_type
    
    ; original game. We use a0, we can trash it here
    move.l  EXTRAMEM(pc),a0
    add.l   #$9216,a0
	jsr	(a0)
	CLR.B	$209.W		;86c02: 42380209
    rts
    
joystick_hook:
	bsr	meta_controls
	MOVE.W	$DFF00C,D1		; original
joy_end
    add.l   #$10,(a7)       ; skip code that we execute below instead
	MOVE.W	D1,D0			;868d0: 3001
	LSR.W	#1,D0			;868d2: e248
	EOR.W	D1,D0			;868d4: b340
	MOVEQ	#0,D3			;868d6: 7600
    movem.l d0,-(a7)
	move.l	_current_buttons_state(pc),d0
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0
    EORI    #4,CCR  ; flip z
	rts
	
joypad_hook:
	movem.l	d0,-(a7)
	bsr	meta_controls
	move.l	_current_buttons_state(pc),d0
	MOVE.W	$DFF00C,D1		; original
    cmp.b   #$6,$568+1  ; level 6 is a flying level
    beq.b   .no_blue    ; blue should be disabled for UP
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
;	bclr	#8,d1
;	btst	#9,d1
;	beq.b	.noneed
;	bset	#8,d1	; xor 8 and 9 yields 0 cos bit9=1
;.noneed
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d1
	btst	#9,d1
	bne.b	.no_blue
	bset	#8,d1	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
	movem.l	(a7)+,d0
    bra.b   joy_end


CURRENT_LEVEL = $568
END_LEVEL_FLAG = $525
	
meta_controls:
	movem.l	d0/d1,-(a7)
	bsr		_update_buttons_status
	move.l	_current_buttons_state(pc),d0
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noesc
    btst    #JPB_BTN_YEL,d0
    beq.b   .noyel
    tst.b   END_LEVEL_FLAG
    bne.b   .noyel  ; already skipped
    bsr _next_level
.noyel
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noesc
	move.b	#$1B,KEYCODE_COPY
.noesc
	move.l	_previous_buttons_state(pc),d1
	not.l	d1
	and.l	d1,d0
	btst	#JPB_BTN_PLAY,d0
	beq.b	.nopause
	move.b	#$20,KEYCODE_COPY
.nopause
	btst	#JPB_BTN_GRN,d0
	beq.b	.noopal
	move.b	#$10,KEYCODE_COPY
.noopal
	movem.l	(a7)+,d0/d1
	RTS

.previous_joy
	dc.l	0
	
	
_waitandsetmask
	moveq	#$-1,D0
	bsr	_waitblit
	move.w	D0,$44(A6)
	rts


_waitandloada6
	bsr	_waitblit
	lea	$DFF000,A6
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

RELOC
	MOVEM.L	D0/A0,-(A7)
	MOVE.L	A4,D4
	BRA.S	.1

.2	ADD.L	D4,(A4,D0.L)
.1	MOVE.L	(A0)+,D0
	BPL.S	.2
	BRA.S	.3

.4	MOVE.L	(A0)+,D1
	ADD.L	D4,D1
.5	MOVE.L	(A0)+,D2
	ADD.L	D1,(A4,D2.L)
	DBF	D0,.5
.3	MOVE.W	(A0)+,D0
	BPL.S	.4
	MOVEM.L	(A7)+,D0/A0
	RTS	

;D0-FILENR
;A0-DEST

LOADROUT

	MOVEM.L	D0-A6,-(A7)
	MOVE.L	d0,d4
	LEA.L	FILNAME(PC),A6
	MOVE.L	D0,D3			;EVALUATE FILENAME
	DIVU.W	#10,D3
	OR.B	#$30,D3
	MOVE.B	D3,2(A6)
	SWAP	D3
	OR.B	#$30,D3
	MOVE.B	D3,3(A6)

	MOVE.L	A0,A6
	LSL.L	#2,D0
	LEA.L	LENTAB(PC),A2
	MOVE.L	4(A2,D0.W),D6
	SUB.L	(A2,D0.W),D6

	move.l	D6,D0			;len
	LEA.L	-8(A6),a1		;address
	lea	FILNAME(PC),a0		;filename
	move.l	(_resload,pc),a2
	jsr	(resload_LoadFile,a2)

	LEA.L	-8(A6,D6.L),A2
	LEA.L	(A6),A0

	BSR.W	DECR
.9	MOVEM.L	(A7)+,D0-A6
	RTS

LOADING1
	SUBQ.L	#8,A0
	MOVEM.L	D0-A6,-(A7)
	MOVE.L	A2,D3
	SUB.L	EXTRAMEM(PC),D3
	SUBQ.L	#8,D3
	LSR.L	#2,D3
	MOVE.L	D3,D4
	LEA.L	FILNAME(PC),A6
	DIVU.W	#10,D3
	OR.B	#$30,D3
	MOVE.B	D3,2(A6)
	SWAP	D3
	OR.B	#$30,D3
	MOVE.B	D3,3(A6)

;	MOVE.L	D0,D0
	MOVE.L	A0,A1
	LEA.L	FILNAME(PC),A0
	move.l	(_resload,pc),a2
	jsr	(resload_LoadFile,a2)

	MOVEM.L	(A7)+,D0-A6
	RTS
LOADING2
	SUBA.L	D2,A0
	MOVEM.L	D0-A6,-(A7)
	MOVE.L	A2,D3
	SUB.L	EXTRAMEM(PC),D3
	SUBQ.L	#8,D3
	LSR.L	#2,D3
	MOVE.L	D3,D4
	LEA.L	FILNAME(PC),A6
	DIVU.W	#10,D3
	OR.B	#$30,D3
	MOVE.B	D3,2(A6)
	SWAP	D3
	OR.B	#$30,D3
	MOVE.B	D3,3(A6)

;	MOVE.L	D0,D0
	MOVE.L	A0,A1
	LEA.L	FILNAME(PC),A0
	move.l	(_resload,pc),a2
	jsr	(resload_LoadFile,a2)

	MOVEM.L	(A7)+,D0-A6
	RTS


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


DECR
	DC.B	$70,$00,$10,$22,$E1,$48,$10,$22
	DC.B	$E1,$88,$10,$22,$43,$F0,$08,$00
	DC.B	$70,$00,$10,$22,$E2,$08,$65,$50
	DC.B	$E2,$08,$65,$40,$E2,$08,$65,$62
	DC.B	$E2,$08,$65,$34,$E2,$08,$65,$14
	DC.B	$E1,$48,$10,$22,$12,$22,$5A,$40
	DC.B	$13,$01,$51,$C8,$FF,$FC,$B1,$C9
	DC.B	$6D,$D6,$4E,$75,$12,$22,$E2,$09
	DC.B	$D1,$40,$56,$40,$E1,$49,$12,$22
	DC.B	$47,$F1,$10,$00,$13,$23,$51,$C8
	DC.B	$FF,$FC,$B1,$C9,$6D,$BA,$4E,$75
	DC.B	$E1,$48,$10,$22,$13,$22,$51,$C8
	DC.B	$FF,$FC,$B1,$C9,$6D,$AA,$4E,$75
	DC.B	$32,$00,$02,$40,$00,$03,$E4,$09
	DC.B	$47,$F1,$10,$00,$56,$40,$13,$23
	DC.B	$51,$C8,$FF,$FC,$B1,$C9,$6D,$90
	DC.B	$4E,$75,$72,$00,$12,$22,$74,$0F
	DC.B	$C4,$41,$EB,$4A,$E8,$49,$84,$40
	DC.B	$47,$F1,$20,$00,$56,$41,$13,$23
	DC.B	$51,$C9,$FF,$FC,$B1,$C9,$6D,$00
	DC.B	$FF,$70,$4E,$75

LENTAB
	DC.B	$00,$00,$18,$A0,$00,$00,$A4,$4C
	DC.B	$00,$00,$C5,$CF,$00,$01,$32,$95
	DC.B	$00,$01,$7C,$8E,$00,$01,$7F,$A1
	DC.B	$00,$04,$09,$97,$00,$04,$A8,$6C
	DC.B	$00,$04,$BB,$44,$00,$04,$BC,$74
	DC.B	$00,$05,$34,$D6,$00,$07,$37,$83
	DC.B	$00,$07,$63,$E6,$00,$07,$6E,$F5
	DC.B	$00,$09,$0C,$D8,$00,$0B,$71,$C9
	DC.B	$00,$0B,$78,$7D,$00,$0B,$79,$76
	DC.B	$00,$0C,$9C,$9F,$00,$0D,$F8,$D9
	DC.B	$00,$0E,$14,$22,$00,$0E,$19,$45
	DC.B	$00,$0F,$09,$C5,$00,$11,$59,$A8
	DC.B	$00,$11,$5F,$1E,$00,$11,$5F,$FB
	DC.B	$00,$11,$C8,$8F,$00,$14,$84,$92
	DC.B	$00,$14,$9C,$2A,$00,$14,$9F,$E6
	DC.B	$00,$16,$20,$AC,$00,$18,$25,$EF
	DC.B	$00,$18,$2D,$A0,$00,$18,$2E,$7E
	DC.B	$00,$1A,$38,$09,$00,$1C,$93,$F7
	DC.B	$00,$1C,$A4,$F2,$00,$1C,$A7,$C6
	DC.B	$00,$1D,$37,$E2,$00,$1E,$B7,$A4
;	DC.B	$00,$1E,$B7,$A4


_version	dc.w	0	;version of disks
_resload	dc.l	0	;address of resident loader
EXTRAMEM	DC.L	$80000	;ADRESS OF EXTRAMEM
FILNAME	DC.B	'D_XX',0
	EVEN

	IFEQ 1

;--------------------------------


;--------------------------------

_badver		pea	TDREASON_BADVERSION
		bra	_end
_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================

	ENDC

; fresh keyboard interrupt instead of lame keyboard polling
; which locked keyboard/quit/freeze keys

keyboard_interrupt
	movem.l	D0/a0/A5,-(a7)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ	.nokey

	MOVE.B	$1C01(A5),D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here
	lea	keycode(pc),a0
	move.b	d0,(A0)

	BSET	#$06,$1E01(A5)
	move.l	#2,d0
	bsr	beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge key

.nokey
	movem.l	(a7)+,d0/a0/a5
	move.w	#8,$dff09c
	rte

_next_level:
    cmp.w   #$6,CURRENT_LEVEL
    beq.b   .no
    addq.w  #1,CURRENT_LEVEL
    st.b    END_LEVEL_FLAG
.no
    rts
    
; RAW-Key-Codes:
;	ESC	$45
;	DEL	$46
;	F1..F10	$50..$59
;	HELP	$5f

KEYHP	
	MOVE.L	A0,-(A7)
	
	lea	keycode(pc),a0
	move.b	(a0),d0
	clr.b	(a0)		; only once!!

	; handle quit key
	CMP.B	_keyexit(pc),D0
	BEQ.S	.QUIT

    cmp.b   #1,d0   ; '1'
    bcs.b   .drop
    cmp.b   #7,d0
    bcc.b   .drop
    move.b  d0,CURRENT_LEVEL+1
    st.b    END_LEVEL_FLAG
.drop
    cmp.b   #$5F,d0
    bne.b   .nonext
    bsr _next_level

	; trainer: infinite lives
;	CMP.B	#$58,D0
;	BNE.S	.1
;	MOVE.L	EXTRAMEM(PC),A0
;	MOVE.W	#$6006,$6DF0(A0)
;	bsr	_flushcache
;.1
.nonext
	MOVE.L	(A7)+,A0
	RTS


.QUIT
.exit	pea	TDREASON_OK
	bra	.end
.debug	pea	TDREASON_DEBUG
.end	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

CHANGESND
	CMP.B	#8,D0
	BNE.S	.1
	MOVE.L	A1,-(A7)
	MOVE.L	EXTRAMEM(PC),A0
	ADD.L	#$E000,A0
	MOVE.L	#$4E714EB9,$B30(A0)
	MOVE.L	#$4E714EB9,$B46(A0)
	MOVE.L	#$4E714EB9,$1288(A0)
	MOVE.L	#$4E714EB9,$129E(A0)


	LEA.L	DELAY(PC),A1
	MOVE.L	A1,$B34(A0)
	MOVE.L	A1,$B4A(A0)
	MOVE.L	A1,$128C(A0)
	MOVE.L	A1,$12A2(A0)
	MOVE.L	(A7)+,A1

	bsr	_flushcache

.1	LEA.L	$31000,A0
	RTS

DELAY	MOVE.W	#($12C/$28),D0
.2	MOVE.W	D0,-(A7)
	MOVE.B	$DFF006,D0
.1	CMP.B	$DFF006,D0
	BEQ.S	.1
	MOVE.W	(A7)+,D0
	DBF	D0,.2
	RTS

keycode
	dc.w	0

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

	