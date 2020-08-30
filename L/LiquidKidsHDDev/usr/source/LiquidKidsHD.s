;*---------------------------------------------------------------------------
; Program:	LiquidKids.s
; Contents:	Slave for "Liquid Kids" (c) 1991 Ocean
; Author:	Codetapper of Action & Galahad & CFou!
; History:	27.08.2003 - v0.1 Codetapper 
;	26.04.2006 - v1.1
;	- Fixed for cache on 68060
;	- Another Blt delays in game
;
;	12.11.2005 - v1.0 CFou!
;	- Islave support for files extraction or DICfor disk image
;	- Slave support for disk image of extracted files
;	- Decrunch routine relocated in fast mem
;	- Many blitter delay inserted intro/outro/game interlevel
;	- Load/Save redirected on hd file 'highs'
;	- Trainer + level skip key
;	- keyboard routine fixed & interupt $68 added
;	- English faults corrected
;	- French, german & polish translation added
;	(With lowlevel.library support or CUSTOM2)
;	CUSTOM2=1:EN |CUSTOM2=2:FR |CUSTOM2=2:DE |CUSTOM2=3:PO
;
; Requires:	WHDLoad 10+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
;---------------------------------------------------------------------------*
;_Flash
	INCDIR	Include:
	INCLUDE whdload.i
	INCLUDE whdmacros.i

	IFD BARFLY
	OUTPUT	"LiquidKids.slave"
	BOPT	O+	;enable optimizing
	BOPT	OG+	;enable optimizing
	BOPT	ODd-	;disable mul optimizing
	BOPT	ODe-	;disable mul optimizing
	BOPT	w4-	;disable 64k warnings
	BOPT	wo-	;disable warnings
	SUPER	 ;disable supervisor warnings
	ENDC

;======================================================================

_base	SLAVE_HEADER	;ws_Security + ws_ID
	dc.w	17		;ws_Version
	dc.w	WHDLF_NoError|WHDLF_EmulTrap ; |WHDLF_NoKbd	;ws_flags
	dc.l	$80000	;ws_BaseMemSize
	dc.l	0	;ws_ExecInstall
	dc.w	_Start-_base	;ws_GameLoader
	dc.w	0	;ws_CurrentDir
	dc.w	0	;ws_DontCache
_keydebug	dc.b	0	;ws_keydebug
_keyexit	dc.b	$59	;ws_keyexit = F10
_expmem	dc.l	$1000	;ws_ExpMem
	dc.w	_name-_base	;ws_name
	dc.w	_copy-_base	;ws_copy
	dc.w	_info-_base	;ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
    dc.w    _config-_base
;============================================================================
_config
	dc.b	"C1:X:unlimited lives:0;"
	dc.b	"C1:X:activate level skip key F8 during the game:1;"
	dc.b	"C1:X:see outro by pressing F8 during the game:2;"
	dc.b	"C2:B:second button jumps;"
    dc.b	"C4:L:language:auto,english,french,german,polish;"
	dc.b	0
   IFD BARFLY
   DOSCMD   "WDate  >T:date"
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
_name	dc.b	"Liquid Kids",0
_copy	dc.b	"1991 Ocean",0
_info	dc.b	"Installed by CFou!",10
	dc.b	"Version "
	DECL_VERSION
	dc.b	-1,"Thanks to Wolf for supplying this unreleased game!"
	dc.b	-1,"And Codetapper for his slave's beta source"
	dc.b	0
	EVEN
	include	'ReadJoyPad.s'
	
;======================================================================
_Start		;A0 = resident loader
;======================================================================

	lea	_resload(pc),a2
	move.l	a0,(a2)	;save for later use

	lea	_Tags(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Control(a2)

	bsr _GetFileSize
	tst.l	d0
	beq _restart
	lea	_FileOpt(pc),a0
	move.l	#1,(a0)	; File found
DestAdr=$5000
_restart	

;-------------------
	MOVEQ	#0,D0
	MOVE.L	#$400,D1
	LEA	DestAdr,A0
	BSR	_LoadRNC
;-------------------

	MOVE.L	#$4C7,D0
	MOVE.L	#$2723,D1
	LEA	$70000,A0
	BSR	_LoadRNC

;------------------ Copy Decrunch routine in Fast memory
	MOVEM.l	D0/A0/A1,-(SP)
	MOVEQ	#$69,D0
	LEA	_DecrunchRoutineBuffer(PC),A1
.enc
	MOVE.L	(A0)+,(A1)+
	DBRA	D0,.enc
	MOVEM.l	(SP)+,D0/A0/A1
;---------------------
;------------------- Patch
	movem.l	d0-d1/a0-a2,-(sp)
;	MOVE.W	#$4EF9,(A0)
;	LEA	_DecrunchRoutineBuffer(PC),A1
;	MOVE.L	A1,(2,A0)

	LEA	$1A8(A0),A0
	; BSR	_DecrunchRoutineBuffer
	jsr		$70000 ; decrunch
	lea	_PL_Intro(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	bsr _Patch_Txt_Intro
	movem.l	(sp)+,d0-d1/a0-a2
;------------------ Patch end

	lea	$500,SP
	LEA	DestAdr,A0
	JMP	$80(A0)
	
_PL_Intro	PL_START
	PL_P	$68-2,_ToucheNew	; Install Keyboard
	PL_W	$68-2,$cccc	; Replace previous free exception
	PL_B	$100,0	; no original key ingame
	;--
	PL_W	$70286+2,$7fff-8	; Leave keyboard interuption installed
	PL_PS	$70212,_SkipIntro	; Skip intro pressing LMB/RMB/FIRE0
	PL_W	$70212+6,$4e71	;
	PL_P	$7022c,_TitleModif	;_Title
	PL_W	$702fe,$4200	;Colour bit fix
	PL_W	$7066c,$4200	;Colour bit fix
	PL_W	$7068a,$2200	;Colour bit fix
	PL_L	$70b8c,$44532720	;KID' -> KIDS'
	PL_L	$70c28,$202d2044	;DEVELOPPERS -> DEVELOPERS
	PL_L	$70c34,$53202d20
	PL_L	$70ec8,$204d7573	;Musics -> Music
	PL_B	$70ed6,$20	;Sounds -> Sound
	PL_P	$74eba,_LoadRNC	; loader
	PL_END

;---------------------
_TitleModif
	MOVEM.l	d0-d1/A0-A1,-(SP)
	lea	_PL_Title(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	MOVEM.l	(SP)+,d0-d1/A0-A1
	JMP	$6B000
_PL_Title	PL_START
	PL_W	$6b1f6+2,$7fff-8	; Leave keyboard interuption installed
	PL_B	$100,0	; no original key ingame
	;---
	PL_P	$6d664,_DecrunchRoutineBuffer; Decrunch routine in fast
	;---	some Blitter fixes
	PL_P	$c0,_Blt_d4_58_a5
	PL_P	$c6,_Blt_d7_58_a5
	PL_P	$d8,_Blt_d1_58_a5
	PL_P	$d2,_Blt_d6_58_a5	; prep for outro
	PL_L	$203aa,$4eb800c0	; blitter delay
	PL_L	$204e6,$4eb800c6	; blitter delay
	PL_PS	$6b8b2,_Blt_1f8a_58_a5
	PL_PS	$6bd4a,_Blt_140f_58_a5
	PL_PS	$6bdb0,_Blt_7cf_58_a5
	PL_L	$6bfc8,$4eb800d8	; blitter delay
	PL_PSS	$6B1DA,menu_quit,2
	;---
	PL_L	$6c482,$1fe0000	;Copperlist $1060000
	;---
	PL_W	$6b144+2,$0020	; before $4000 ->shut down only music and left keyboard
	PL_P	$6b1e4,_GameModif	; ok
	PL_P	$6d32c,_LoadRNC	; ok
	PL_END

;---------------------
_GameModif
	MOVEM.l	D0-D1/A0-A2,-(SP)

	bsr	_detect_controller_types
	
	BSR	_PatchBLT1
	BSR	_PatchBLT2
	BSR	_PatchBLT3
	BSR	_PatchBLT4

	bsr	_WaitBLT2Blitter

	lea	_PL_Game(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	MOVEM.l	(SP)+,D0-D1/A0-A2
	JMP	$20500
_PL_Game	PL_START
	PL_IFC1X	0
	PL_B	$223AC,$4A   ; unlimited lives counter $21ea7.b
	PL_ENDIF
	
	PL_IFC2
	PL_PS	$22768,joypad_controls
	PL_ELSE
	PL_PS	$22768,joystick_controls
	PL_ENDIF
	
	PL_PSS	$2A7C2,unpause,4
	
	PL_P	$646ac,_DecrunchRoutineBuffer; Decrunch routine in fast
	;---
	PL_PS	$22ee0,_loadHS
	PL_PSS	$23006,_saveHS,2

	;---
	PL_B	$100,1	; CFou! :original key ingame activated
	PL_B	$2a8d0,$60	; Remove old bugged interruption
	;---
	PL_W	$21f4e,$300	;Colour bit fix (was $100)
	PL_PS	$22500,_Clr_dff100
	PL_W	$47dfa,$300	;Colour bit fix (was $100)
	PL_W	$47e62,$8300	;Colour bit fix (was $8100)
	PL_W	$47fbc,$300	;Colour bit fix (was $100)
	PL_W	$480fe,$8300	;Colour bit fix (was $8100)
	PL_W	$4813e,$300	;Colour bit fix (was $100)
	PL_P	$64336,_TitleModif	; ok
	PL_PS	$47f4a,_InterLevelModif ; ok
	PL_P	$22b9c,_OutroModif	; ok
	;	PL_W	$22b88,$4e71	; outro remove old delay routine
	PL_P	$64356,_LoadRNC	; ok
	;-- BLT new
	PL_L	$254c0,$4eb800c6	; blitter delay
	PL_L	$2a5d0,$4eb800c6	; blitter delay
	PL_END

menu_quit:
	movem.l	d0,-(a7)
	bsr	read_joystick_tq		; returns state in D0
	movem.l	(a7)+,d0
	; original
	BTST.B #$0007,$00bfe001	
	rts
	
unpause:
	; first wait for pause unpressed
	bsr.b	.waitrel
.unploop
	; check for pause pressed
	movem.l	d0,-(a7)
	bsr	read_joystick_tq		; returns state in D0
	btst	#JPB_BTN_PLAY,d0
	beq.b	.loop
	; play pressed: wait for release
	bsr.b	.waitrel
	bra.b	.out
.loop
	CMPI.B	#$c8,$dff006
	BNE.S	.loop		;2a7ca: 66f6
	bra.b	.exit
.out
	clr.b	$21EA0		; unpause flag?
.exit
	movem.l	(a7)+,d0
	; can be set by another external event (key)
	TST.B	$21EA0		;2a7cc: 4a3900021ea0
	BNE.S	.unploop		;2a7d2: 66ee
	rts

.waitrel
	moveq.l	#1,d0
	bsr	read_joystick_tq		; returns state in D0
	btst	#JPB_BTN_PLAY,d0
	bne.b	.waitrel
	rts
; joypad
read_joy:
	movem.l	d0-d1/a0,-(a7)
	lea	_joystate(pc),a0
	move.l	4(a0),(a0)+	; save previous
	bsr	read_joystick_tq		; returns state in D0
	move.l	d0,(a0)		; store current
	btst	#JPB_BTN_PLAY,d0
	beq.b	.nopause
	move.l	-4(a0),d1
	btst	#JPB_BTN_PLAY,d1
	bne.b	.nopause
	eor.b	#1,$21ea0		; toggle pause
.nopause
	movem.l	(a7)+,d0-d1/a0
	rts

read_joystick_tq:
	moveq.l	#1,d0
	bsr	_read_joystick
	btst	#JPB_BTN_PLAY,d0
	beq.b	.noquit
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noquit
	btst	#JPB_BTN_FORWARD,d0
	bne		_exit
.noquit
	rts
	
joystick_controls:
	bsr	read_joy
	move.w	_custom+joy1dat,d0
	rts
	
joypad_controls:
	movem.l	d1,-(a7)
	bsr	read_joy
	move.l	_joystate+4(pc),d1
	move.w	_custom+joy1dat,d0
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d0
	btst	#9,d0
	beq.b	.noneed
	bset	#8,d0	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d1
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d0
	btst	#9,d0
	bne.b	.no_blue
	bset	#8,d0	; xor 8 and 9 yields 1 cos bit9=0
.no_blue
	movem.l	(a7)+,d1
	rts
;---------------------
_InterLevelModif
	MOVEM.l	D0-D1/A0-A2,-(SP)
	lea	_PL_InterLevel(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	MOVEM.l	(SP)+,D0-D1/A0-A2
	jmp	$65000
_PL_InterLevel	PL_START
	PL_L	$6568a,$4eb800d8	; blitter delay
	PL_L	$65744,$4eb800c6	; blitter delay
	PL_END

;---------------------
_OutroModif
	MOVEM.l	D0-D1/A0-A2,-(SP)
	lea	_PL_Outro(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

;	move.l	#$8000,d0	; wait before run outro
;.enc
;;	move.w	#$f0,$dff180
;	BSR _EmptyDBF
;	dbf d0,.enc

	MOVEM.l	(SP)+,D0-D1/A0-A2
	bsr	_PatchBLT4Outro
	jmp	$d000
_PL_Outro
	PL_START
	PL_L	$d776,$4eb800d2	; blitter delay
	PL_L	$d6fa,$4eb800d8	; blitter delay
	PL_PS	$d686,_Blt_885_58_a5	; blitter delay
	PL_END
;---------------------
;******************************************************************

_PatchBLT1
	MOVEM.l	D0-A6,-(SP)
	MOVE.L	#$36834E71,D0
	MOVE.W	#$D444,D1
	MOVE.W	#$4EB9,D2

	LEA	_WaitBLT(PC),A2
	LEA	$2AFAE,A0
	LEA	$2B1AE,A1
.loop
	CMP.L	(A0),D0
	BNE.B	.skip
	CMP.W	(4,A0),D1
	BNE.B	.skip
	MOVE.W	D2,(A0)
	MOVE.L	A2,(2,A0)
.skip	ADDQ.L	#2,A0
	CMPA.L	A0,A1
	BNE	.loop
	MOVEM.l	(SP)+,D0-A6
	RTS

_PatchBLT2
	MOVEM.l	D0-A6,-(SP)
	MOVE.L	#$4896000C,D0
	MOVE.W	#$4EB9,D2
	LEA	_WaitBLT4(PC),A2
	LEA	_WaitBLT5(PC),A3
	LEA	$2AFB4,A0
	LEA	$2B1C4,A1
.loop
	CMP.L	(A0),D0
	BNE	.skip3
	CMPI.W	#$9440,(4,A0)
	BEQ	.skip
	CMPI.W	#$4E71,(4,A0)
	BEQ	.skip1
	BRA	.skip3
.skip
	MOVE.L	A3,(2,A0)
	BRA	.skip2

.skip1
	MOVE.L	A2,(2,A0)
.skip2
	MOVE.W	D2,(A0)
.skip3
	ADDQ.L	#2,A0
	CMPA.L	A0,A1
	BNE	.loop
	MOVEM.l	(SP)+,D0-A6
	RTS

_PatchBLT3
	MOVEM.l	D0-A6,-(SP)
	MOVE.L	#$36874E71,D0
	MOVE.W	#$DC44,D1
	MOVE.W	#$4EB9,D2

	LEA	_WaitBLT2(PC),A2
	LEA	$2B2AC,A0
	lea	$2b96a,a1
.loop
	CMP.L	(A0),D0
	BNE	.skip
	CMP.W	(4,A0),D1
	BNE	.skip
	MOVE.W	D2,(A0)
	MOVE.L	A2,(2,A0)
.skip
	ADDQ.L	#2,A0
	CMPA.L	A0,A1
	BNE	.loop
	MOVEM.l	(SP)+,D0-A6
	RTS

_PatchBLT4Outro
	MOVEM.l	D0-A6,-(SP)
	lea	$dc00,a0
	lea	$dd00,a1
	bra	_cont
_PatchBLT4
	MOVEM.l	D0-A6,-(SP)
	lea	$2a600,a0
	lea	$2ae00,a1
_cont
	Lea	_Blt_A1_A4_a5(pc),a2
	move.l	#$4e714eb9,d2
	move.l	#$48d51e00,d0
	move.l	#$3B470010,d1	
.next
	cmp.l	(a0),d0
	bne	.no
	cmp.l	4(a0),d1
	bne	.no
	move.l	d2,(a0)
	move.l	a2,4(a0)
.no
	add.l	#2,a0
	cmp.l	a0,a1
	bne	.next
	MOVEM.l	(SP)+,D0-A6
	RTS

_WaitBLT
	;	dl	$377C87D0
	;	dw	$3E
;	MOVE.L	#$01800F00,$6C666
;	MOVE.L	#$01000200,$6C666+4
;	MOVE.L	#$FFFFFFFE,$6C666+8
	move.w	#$87d0,$3e(a3)

.enc	BTST	#6,(-$56,A3)
	BNE.B	.enc
	MOVE.W	D3,(A3)
	ADD.W	D4,D2
	RTS

_WaitBLT2
.enc	BTST	#6,(-$56,A3)
	BNE	.enc
	MOVE.W	D7,(A3)
	ADD.W	D4,D6
	RTS

_WaitBLT4
.enc	BTST	#6,($DFF002).L
	BNE	.enc
	MOVEM.w	D2/D3,(A6)
	RTS

_WaitBLT5
.enc	BTST	#6,($DFF002).L
	BNE	.enc
	MOVEM.w	D2/D3,(A6)
	SUB.W	D0,D2
	RTS

_SkipIntro
.loop	BTST	#7,$BFE001
	BEQ	.skip
	BTST	#6,$BFE001
	BEQ	.skip
	BTST	#2,$DFF016
	BEQ	.skip
	TST.W	$706B4
	BEQ	.loop
.skip	RTS

_Touche	move.b	$c00(a1),d0
	ori.b	#$40,$e00(a1)
	move.l	d0,-(a7)
	ror.b	#1,d0
	not.b	d0

	cmp.b	_keyexit(pc),d0
	beq	_exit

	move.l	(a7)+,d0
	rts

;======================================================================

_ToucheB
	bsr	_EmptyDBF
	cmp.b	_keyexit(pc),d0	;Check if the user hit the
	beq	_exit	;quit key and exit if so
	cmp.b	#$58,d0
	bne	.pasf8
	move.w	#$f,$dff180
.pasf8
	rts

;======================================================================

_EmptyDBF	movem.l	d0-d1,-(sp)
	moveq	#3-1,d1	;wait because handshake min 75 탎
.int2w1	move.b	(_custom+vhposr),d0
.int2w2	cmp.b	(_custom+vhposr),d0	;one line is 63.5 탎
	beq	.int2w2
	dbf	d1,.int2w1	;(min=127탎 max=190.5탎)
	movem.l	(sp)+,d0-d1
	rts


;======================================================================

_LoadRNC
_Loader	movem.l	d0-d3/d5/a0-a2/a5,-(sp)
	move.l	a0,a5
	move.l	d0,d5
	mulu	#$200,d0
	move.l	_FileOpt(pc),d3
	bne _LoadFile
	moveq	#1,d2
	bsr _LoadDisk
	movem.l	(sp)+,d0-d3/d5/a0-a2/a5
	rts
_LoadDisk
	MOVEM.l	D0/D1/A0-A2,-(SP)
	MOVEA.l	(_resload,PC),A2
	jsr	resload_DiskLoad(a2)
	bsr	_LoadCommun
	MOVEM.l	(SP)+,D0/D1/A0-A2
	RTS

_LoadFile
	move.l	d1,d7
	move.l	d0,d2
	move.l	a0,a2
	bsr _GetFileNameA0

	lea	_FileName(pc),a0
	move.l	a2,a1
	clr.l	d1	; offset

	bsr _GetFileSize
	cmp.l	d7,d0
	bcc .ok
	move.l	d0,d7
.ok
	move.l	d7,d0	; lg
	MOVEA.l	(_resload,PC),A2
	jsr	resload_LoadFileOffset(a2)
;	jsr	resload_LoadFile(a2)
	bsr	_LoadCommun
	movem.l	(sp)+,d0-d3/d5/a0-a2/a5
	rts
_LoadCommun
	move.l	a5,a0
	cmp.l	#'ICE!',(a0)
	bne	.pas
	bsr	_DecrunchRoutineBuffer
.pas
	lea	_FileToPatch(pc),a1
.next
	move.l	(a1)+,d0	; looking for file to patch
	beq	.end
	move.l	(a1)+,d1	; looking for file to patch
	beq	.end

	cmp.w	d0,d5
	bne	.next

	IFD	_Flash
.t	move.w	#$f,$dff180
	btst	#6,$bfe001
	bne	.t
	ENDC
	lea	_base(pc),a0
	jsr	(a0,d1.l)
.end
	bsr	instal_touche
	rts

_FileToPatch
	dc.l	$4b0,_Patch_Txt_File_4B0-_base
	dc.l	$4db,_Patch_Txt_File_4DB-_base
	dc.l	$4e8,_Patch_Txt_File_4E8-_base
	dc.l	$5ae,_Patch_Txt_File_5AE-_base
	dc.l	0,0

_GetFileNameA0	lea	_FileNumber(pc),a0	;d0 = File number
	move.l	d2,-(sp)
	divu	#$200,d2	; take sector number

	bsr	_NumToHex
	move.b	d3,3(a0)
	lsr.l	#4,d2
	bsr	_NumToHex
	move.b	d3,2(a0)
	lsr.l	#4,d2
	bsr	_NumToHex
	move.b	d3,1(a0)
	lsr.l	#4,d2
	bsr	_NumToHex
	move.b	d3,0(a0)

	move.l	(sp)+,d2
	rts

_NumToHex	move.b	d2,d3
	and.b	#$f,d3
	cmp.b	#9,d3
	bgt	.HexChar
	add.b	#'0',d3
	rts
.HexChar	add.b	#'a'-10,d3
	rts

_FileName	dc.b	"LiquidKids"
_FileNumber	dc.b	"0000.bin",0
_DiskNumber	dc.b	"1"
	EVEN	
_FileOpt	dc.l	0

_GetFileSize
	movem.l	d1-a6,-(a7)
	lea	_FileName(pc),a0
	move.l	(_resload,pc),a2
	jsr	(resload_GetFileSize,a2)
	movem.l	(a7)+,d1-a6
	rts

;======================================================================
_resload	dc.l	0	;resident loader
_Tags	dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
	dc.l	WHDLTAG_CUSTOM4_GET
_forced_language	dc.l	0
	dc.l	WHDLTAG_LANG_GET
_language	dc.l	0
	dc.l	WHDLTAG_BUTTONWAIT_GET
_buttonwait	dc.l	0
	dc.l	TAG_DONE
;======================================================================

_exit	pea	TDREASON_OK
	bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

;======================================================================
_EnableBlitter	lea	$dff058,a3
	move.w	#$8040,$dff096
	rts

;======================================================================

_Clr_dff100	move.w	#$200,$dff100
	rts

;======================================================================

_WaitBLT2Blitter	movem.l	d0-d7/a0-a6,-(sp)

	lea	$2a000,a0
	lea	$2c000,a1
	move.l	#$36834e71,d0	;move.w	d3,(a3) + nop
	move.l	#$4eb800cc,d1
	move.l	#$36874e71,d2	;move.w	d7,(a3) + nop
	move.l	#$4eb800d2,d3
	move.l	#$4896000c,d4	;move.w	d2/d3,(a6)
	lea	_Blt_d2d3_a6(pc),a4
	move.l	#$489600c0,d5	;move.w	d6/d7,(a6)
	lea	_Blt_d6d7_a6(pc),a5

.Check	move.l	(a0),d6
	cmp.l	d0,d6
	bne	.1
	move.l	d1,(a0)
	bra	.Next

.1	cmp.l	d2,d6
	bne	.2
	move.l	d3,(a0)
	bra	.Next

.2	cmp.w	#$4e71,4(a0)
	bne	.4

	cmp.l	d4,d6
	bne	.3
	move.w	#$4eb9,(a0)
	move.l	a4,2(a0)
	bra	.Next

.3	cmp.l	d5,d6
	bne	.Next
	move.w	#$4eb9,(a0)
	move.l	a5,2(a0)
	bra	.Next

.4
.Next	add.l	#2,a0
	cmp.l	a0,a1
	bne	.Check

	movem.l	(sp)+,d0-d7/a0-a6
	rts

;======================================================================

_Blt_d3_a3	move.w	d3,(a3)
	bra	_BlitWaitGame

_Blt_d7_a3	move.w	d7,(a3)
	bra	_BlitWaitGame

_Blt_d2d3_a6	movem.w	d2/d3,(a6)
	bra	_BlitWaitGame

_Blt_d6d7_a6	movem.w	d6/d7,(a6)
	bra	_BlitWaitGame

_Blt_d1_58_a5	move.w	d1,$58(a5)
	bra	_BlitWait

_Blt_d6_58_a5	move.w	d6,$58(a5)
	bra	_BlitWait

_Blt_d4_58_a5	move.w	d4,$58(a5)
	bra	_BlitWait

_Blt_d7_58_a5	move.w	d7,$58(a5)
	bra	_BlitWait

_Blt_7cf_58_a5	move.w	#$7cf,$58(a5)
	bra	_BlitWait

_Blt_140f_58_a5 move.w	#$140f,$58(a5)
	bra	_BlitWait

_Blt_1f8a_58_a5 move.w	#$1f8a,$58(a5)
	bra	_BlitWait

_Blt_885_58_a5	move.w	#$885,$58(a5)	; outro
	bra	_BlitWait

_Blt_A1_A4_a5
	moveM.l	a1-a4,(a5)
	move.w	d7,$10(a5)	; game
	bra	_BlitWait


;_BlitWaitGame
;
;_smeg	nop
;	btst	#6,$dff002
;.CUNT	nop
;	btst	#6,$dff002
;	bne	.CUNT
;	rts

_BlitWaitGame
_BlitWait	BLITWAIT
	rts
;-------------------

instal_touche:
	cmp.l	#0,$68
	beq .ok
	cmp.l	#$cccccccc,$68
	bne .pas
.ok
	move.w	#$2700,sr
;	LEA	.interupt6c(PC),A0
;	move.l	a0,$6c
	LEA	_ToucheNew(PC),A0
	MOVE.L	A0,$68
	LEA	$BFE001,A1
	MOVE.B	#$88,$D00(A1)
	TST.B	$D00(A1)
	AND.B	#$BF,$E00(A1)
	MOVE.W	#8,$DFF09C
	MOVE.W	#$c008,$DFF09A
	move.w	#$2000,sr
.pas
	RTS

.interupt6c
	movem.l	d0,-(a7)
	move.w	$dff01e,d0
	and.w	#$20,d0
	beq .fin
	move.w	$dff01e,d0
	and.w	#$70,d0
	ori.w	#$8000,d0
	move.w	d0,$dff09c
	and.w	#$7fff,d0
	move.w	d0,$dff09c
.fin
	movem.l	(a7)+,d0
	rte

	
_ToucheNew:
	MOVEM.l	D0/D1/A1,-(SP)
	LEA	$BFE001,A1
	BTST	#3,$D00(A1)
	BEQ	.end
	MOVE.B	$C00(A1),D0
	CLR.B	$C00(A1)
	OR.B	#$40,$E00(A1)
	NOT.B	D0
	ROR.B	#1,D0

	cmp.b	#0,$100	; only in game
	beq .pas
	bsr .Kbd_Original
.pas
;	lea	.touchebin(pc),a1
;	move.l	d0,(a1)

	cmp.b	_keyexit(pc),d0
	beq _exit

	cmp.b	#$58,d0
	bne .pas_f9
	move.w	#$f0,$dff180
	move.w	#$f0,$dff180
	move.w	#$f0,$dff180
;	move.w	#$0,$dff180
.pas_f9:

	MOVEQ	#2,D1
.w2:
	MOVE.B	$DFF006,D0
.w1:
	CMP.B	$DFF006,D0
	BEQ.b	.w1
	DBRA	D1,.w2
	LEA	$BFE001,A1
	AND.B	#$BF,$E00(A1)
.end:
	MOVE.W	#8,$DFF09C
	MOVEM.l	(SP)+,D0/D1/A1
	RTE
	
.touchebin:
	dc.l	0

.Kbd_Original
	cmp.b	#$56,d0
	bne .pas_f7
	move.w	#$f00,$dff180
	move.b	#1,$21eb3	; restart
.pas_f7:
	cmp.b	#$57,d0
	bne .pas_f8
	move.l	_custom1(pc),d0
	btst #2,d0
	beq .pasoutro	
	move.b	#1,$21ed1	; see outro
	move.b	#1,$2fb9e
.pasoutro
	btst	#1,d0
	beq	.skip
	lea	_Skip1(pc),a1
.encType1
	move.b	(a1)+,d0
	beq	.noType1
	cmp.b	$21e24+1,d0
	bne	.encType1
	move.w	#$f0,$dff180
	move.b	#2,$21ea9	; skip level	$21e24.w	=	2	; normal level
.noType1
	lea	_Skip2(pc),a1
.encType2
	move.b	(a1)+,d0
	beq	.noType2
	cmp.b	$21e24+1,d0
	bne	.encType2
	move.w	#$f0,$dff180
	cmp.b	#$13,$21e25 ; last level boss
	beq	.Bigboss
	tst.b	$21eab
	bne	.Bigboss
	move.b	#1,$21eab	; skip level	$21e24.w	=	2	; normal level
	move.b	#1,$21eb3	; restart but dec 1 to live
	move.l	_custom1(pc),d0
	btst	#0,d0
	bne	.noType2
	add.b	#1,$21ea7	; inc 1 to live
.noType2
	bra .skip
.Bigboss
	lea	_BigBossNRJ(pc),a1
	move.w	$21e24,d0
	and.l	#$ff,d0
	divu	#3,d0
	and.l	#$ff,d0
	sub.l	#$1,d0
	lsl.l	#2,d0
	move.l	(a1,d0.l),a1
	clr.b	(a1)	; kill boss
	bra	.skip
.pas_f8:

;	BTST	#0,$21E4B
;	BEQ.b	.skip
;	CLR.L	$21D34
	MOVE.B	$21D38,D1
;	CMP.B	D0,D1
;	BEQ.B	.nochange
	MOVE.B	D0,$21D34
	MOVE.B	D0,$21D38
;.nochange

	; MOVE.B	$21D34,D0
	CMPI.B	#$19,D0
	BNE.B	.no
	EORI.B	#1,$21EA0

.no	CMPI.B	#1,D0
	BNE.B	.no2
	EORI.W	#1,$21E10
	MOVE.W	#1,$5DF6E
	TST.W	$21E10
	BNE.B	.no2
	CLR.W	$5DF6E

.no2	CMPI.B	#2,D0
	BNE.B	.skip
	EORI.W	#1,$21E12
	MOVE.W	#1,$5DF6C
	TST.W	$21E12
	BNE.B	.skip
	CLR.W	$5DF6C
.skip	rts

_Skip1:	; normal level
	dc.b	1,2,4,5,7,8,$a,$b,$d,$e,$10,$11
	dc.b	0
	even
_Skip2:	; big boss
	dc.b	3,6,9,$c,$f,$12,$13
	dc.b	0
	even
_BigBossNRJ
	dc.l	$1a120	; boss 1
	dc.l	$1a24c	; boss 2
	dc.l	$1a33c	; boss 3
	dc.l	$1a15c	; boss 4
	dc.l	$1a15c	; boss 5
	dc.l	$1a120	; boss 6
	dc.l	$1a120	; boss 7
	dc.l	0
_DecrunchRoutineBuffer
	ds.l	110
_joystate
	dc.l	0	; previous
	dc.l	0	; current
	
_GetFileSizeSave
	movem.l	d1-a6,-(a7)
	lea	save_game_name(pc),a0
	move.l	(_resload,pc),a2
	jsr	(resload_GetFileSize,a2)
	movem.l	(a7)+,d1-a6
	rts
_loadHS
	movem.l	d0-a6,-(a7)
	bsr	_GetFileSizeSave
	beq	.pas
	lea	$800,a0
	lea	save_game_name(pc),a1
	exg.l	a0,a1
	clr.l	d0
	move.l	#$50,d1 ; lg
	exg.l	d0,d1
	move.l	(_resload,pc),a2
	jsr	(resload_LoadFileOffset,a2)
.pas
	movem.l	(a7)+,d0-a6
	st	$23462
	rts

_saveHS
	movem.l	d0-a6,-(a7)
	move.l	_custom1(pc),d0
	bne	.pas
	lea	$800,a0
	lea	save_game_name(pc),a1
	exg.l	a0,a1
	clr.l	d0
	move.l	#$50,d1 ; lg
	exg.l	d0,d1
	move.l	(_resload,pc),a2
	jsr	(resload_SaveFileOffset,a2)
.pas
	movem.l	(a7)+,d0-a6
	move.b	#$64,$21ea2
	rts

save_game_name
	dc.b	'highs',0
	even
	include	'LiquidKids_Translation.s'


 END
;-------------------
