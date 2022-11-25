;---------------------------------------------------------------------------;
;  :Program.	North&South.asm;
;  :Contents.	Slave for "North & South" from Infogrames;
;  :Author.	Mr.Larmer of Wanted Team, Wepl;
;  :Original	;
;  :Version.	$Id: North&South.asm 1.2 2001/02/17 19:59:05 jah Exp $;
;  :History.	17.02.01 Wepl adjusted;
;		02.06.03 Wepl minor changes;
;  :Requires.	-;
;  :Copyright.	Public Domain;
;  :Language.	68000 Assembler;
;  :Translator.	Asm-One 1.44;
;  :To Do.;
;---------------------------------------------------------------------------*;
;
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	;INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"NorthAndSouth.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC
Execbase	=	4
;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= 0000
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
CACHE
;DEBUG
DISKSONBOOT
BOOTBLOCK
;DOSASSIGN
;FONTHEIGHT	= 8
;HDINIT
;HRTMON
;IOCACHE	= 1024
;MEMFREE	= $100
;NEEDFPU
;POINTERTICKS	= 1
SETPATCH
;STACKSIZE	= 6000
TRDCHANGEDISK

;============================================================================


slv_Version=17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include 	kick13.s
	include readjoypad.s


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

slv_name		dc.b	"North & South",0
slv_copy		dc.b	"1989 Infogrames",0
slv_info		dc.b	"adapted by Wepl, CFou!, Mr.Larmer & JOTD",10,10
			dc.b	"Use 2nd joystick button / CD32 pad blue to switch units",10
			dc.b	"Use CD32 pad FWD+BWD to retreat",10,10
			dc.b	"Version "
			DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config		
;		DC.B	"C1:X:Second Button Support (PL1&PL2) & CD32 PAD (PL1):0;"
		DC.B	"C1:B:Forces Joystick or CD32Pad for PL2 (mouse port);"
                dc.b    0
	even
; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
patchs2	MACRO
	IFNE	NARG-2
		FAIL	arguments "patchs2"
	ENDC
		move.w	#$4eb9,\1
		pea	(\2,pc)
		move.l	(a7)+,2+\1
		move.w	#$4E71,6+\1
	ENDM

patch2	MACRO
	IFNE	NARG-2
		FAIL	arguments "patchs2"
	ENDC
		move.w	#$4ef9,\1
		pea	(\2,pc)
		move.l	(a7)+,2+\1
		move.w	#$4E71,6+\1
	ENDM
;============================================================================;
;
	;a1 = ioreq ($2c+a5);
	;a4 = buffer (1024 bytes)
	;a6 = execbase
_bootblock;
	; just to be able to use 2-button joysticks
	bsr	_detect_controller_types
	
.versionTest
	;get tags
		lea	(_tag,pc),a0
		move.l	_resload(pc),a2
		jsr	(resload_Control,a2)

	;check version
		move.l	#$2A4,d0
		lea	12(a4),a0
		move.l	(_resload,pc),a2
		jsr	(resload_CRC16,a2)

		cmp.w	#$8E19,D0	V1&V3	; multilanguage version
		beq	.verok
		cmp.w	#$4A39,D0	V2 NTSC	; english version (hidden bootblock)
		beq	.USversion
.not_support
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)
.verok		pea	.patch(pc)


		Lea	_DIR1Name(pc),a0
		BSR	_GetFileSize
		tst.l	d0
		bne	.filesversion
	;call bootblock

		lea	($2c,a5),a1
		jmp	(12,a4)
.patch

		addq.l	#8,A0
;***************************;***************************;***************************
;***************************;***************************;***************************
;***************************** Version 1
;***************************;***************************;***************************
;***************************;***************************;***************************
		cmp.l	#$61A64A40,$7FFE(A0)		;V1 multilanguage
		bne	.another
		
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	a0,a1
		move.l	_resload(pc),a2
		lea	pl_version_1(pc),a0
		jsr	resload_Patch(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		

;------------------------ Second Button Patch
			add.l	#$8348,a0
			cmp.l	#$1B6CBE2D,(A0)
			bne	.noFoundJoy
			patchs	$00(a0),_TakePL1JOY1	; Patch PL1 Take JoyOption
			patchs	$08(a0),_TakePL2JOY0	; Patch PL2 Take JoyOption
			patchs	$14(a0),_TakePL2JOY0	; Patch PL2 Take JoyOption

.noFoundJoy		sub.l	#$8348,a0
			add.l	#$B5B2,a0
			cmp.l	#$162CBE24,(A0)
			bne	.noFoundLShift
			patchs	$00(a0),_TakeSpecialKeyPL1	; Patch Take Special Keys 
.noFoundLShift
			sub.l	#$B5B2,a0
			add.l	#$B762,a0
			cmp.l	#$162CBE24,(A0)
			bne	.noFoundRShift
			patchs	$00(a0),_TakeSpecialKeyPL2	; Patch Take Special Keys 
.noFoundRShift		sub.l	#$B762,a0
			add.l	#$16D96-$B8C0,a0
			cmp.l	#$7600162C,(A0)
			bne	.noFoundSwapPORT
			move.l	#$76011943,(a0)		; remove swap control PORT
.noFoundSwapPORT	sub.l	#$16D96-$B8C0,a0
.noSB
;------------------------
;------------------------	Files version PAtch
			move.l	_FileVersion(pc),d0
			tst.l	d0
			beq	.nofiles
			add.l	#$13B62-8,a0
			patch2	$0(a0),_LoadFilePart200Game	; Patch TRackDisk access to load files
			sub.l	#$13B62-8,a0
.nofiles
;------------------------
.go		subq.l	#8,A0
		jmp	(a0)


	
;***************************;***************************;***************************
;***************************;***************************;***************************
;***************************** Version 3
;***************************;***************************;***************************
;***************************;***************************;***************************
.another	cmp.l	#$61A64A40,$7F42(A0)		;V3 Multlanguage
		bne	.another2
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	a0,a1		
		move.l	_resload(pc),a2
		lea	pl_version_3(pc),a0
		jsr	resload_Patch(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		

;------------------------ Second Button Patch
	;		move.l	_custom1(pc),d0
	;		tst.l	d0
	;		beq	.noSBV3
			add.l	#$13B48-$B8C0,a0
			cmp.l	#$1B6CBE2B,(A0)
			bne	.noFoundJoyV3
			patchs	$00(a0),_TakePL1JOY1_V3	; Patch PL1 Take JoyOption
			patchs	$08(a0),_TakePL2JOY0_V3	; Patch PL2 Take JoyOption
			patchs	$14(a0),_TakePL2JOY0_V3	; Patch PL2 Take JoyOption
.noFoundJoyV3		sub.l	#$13B48-$B8C0,a0
			add.l	#$16D88-$B8C0,a0
			cmp.l	#$162CBE22,(A0)
			bne	.noFoundLShiftV3
			patchs	$00(a0),_TakeSpecialKeyPL1_V3	; Patch Take Special Keys 
.noFoundLShiftV3	sub.l	#$16D88-$B8C0,a0
			add.l	#$16F3C-$B8C0,a0
			cmp.l	#$162CBE22,(A0)
			bne	.noFoundRShiftV3
			patchs	$00(a0),_TakeSpecialKeyPL2_V3	; Patch Take Special Keys 
.noFoundRShiftV3	sub.l	#$16F3C-$B8C0,a0
			add.l	#$16CA8-$B8C0,a0
			cmp.l	#$7600162C,(A0)
			bne	.noFoundSwapPORTV3
			move.l	#$76011943,(a0)		; remove swap control PORT
.noFoundSwapPORTV3	sub.l	#$16CA8-$B8C0,a0

.noSBV3
;------------------------
;------------------------
			move.l	_FileVersion(pc),d0
			tst.l	d0
			beq	.nofiles3
			add.l	#$13B24-8,a0
			patch2	$0(a0),_LoadFilePart200Game	; Patch TRackDisk access to load files
			sub.l	#$13B24-8,a0
.nofiles3
;------------------------
		bra	.go

;***************************;***************************;***************************
;***************************;***************************;***************************
;***************************** Version 2
;***************************;***************************;***************************
;***************************;***************************;***************************
.another2	cmp.l	#$61A64A40,$7EF6(A0)		;V2 English NTSC
		bne	.not_support
		
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	a0,a1
		move.l	_resload(pc),a2
		lea	pl_version_2(pc),a0
		jsr	resload_Patch(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		
		add.l	#$119A2-8,a0
		cmp.l	#$08B90007,(A0)		;
		bne	.not_support
		cmp.l	#$00BFD100,4(A0)		;
		bne	.not_support
		patch	$0(a0),_Crack		; crack disk protection
		sub.l	#$119A2-8,a0
;------------------------ Second Button Patch
; JOTD why not enabling it anyway? no need for custom1
;			move.l	_custom1(pc),d0
;			tst.l	d0
;			beq	.noSBV2
			add.l	#$13B00-$B8C0,a0
			cmp.l	#$1B6CBE21,(A0)
			bne	.noFoundJoyV2
			patchs	$00(a0),_TakePL1JOY1_V2	; Patch PL1 Take JoyOption
			patchs	$08(a0),_TakePL2JOY0_V2	; Patch PL2 Take JoyOption
			patchs	$14(a0),_TakePL2JOY0_V2	; Patch PL2 Take JoyOption
.noFoundJoyV2		sub.l	#$13B00-$B8C0,a0
			add.l	#$16D6A-$B8C0,a0
			cmp.l	#$162CBE18,(A0)
			bne	.noFoundLShiftV2
			patchs	$00(a0),_TakeSpecialKeyPL1_V2	; Patch Take Special Keys 
.noFoundLShiftV2	sub.l	#$16D6A-$B8C0,a0
			add.l	#$16F1A-$B8C0,a0
			cmp.l	#$162CBE18,(A0)
			bne	.noFoundRShiftV2
			patchs	$00(a0),_TakeSpecialKeyPL2_V2	; Patch Take Special Keys 
.noFoundRShiftV2	sub.l	#$16F1A-$B8C0,a0
			add.l	#$16C8E-$B8C0,a0
			cmp.l	#$7600162C,(A0)
			bne	.noFoundSwapPORTV2
			move.l	#$76011943,(a0)		; remove swap control PORT
.noFoundSwapPORTV2	sub.l	#$16C8E-$B8C0,a0
.noSBV2
;------------------------
;------------------------
			move.l	_FileVersion(pc),d0
			tst.l	d0
			beq	.nofiles2
			add.l	#$139D8-8,a0
			patch2	$0(a0),_LoadFilePart200Game	; Patch TRackDisk access to load files
			sub.l	#$139D8-8,a0
.nofiles2
;------------------------
		bra	.go
.USversion
		Lea	_DIR1Name(pc),a0
		BSR	_GetFileSize
		tst.l	d0
		bne	.filesversionUS

		move.l	a4,a0
		move.l	#$DBC00,D0
		move.l	#$400,d1	; SKIP TRACK PROTECT
		move.l	#1,d2		; RUN GOOD HIDDEN BOOTBLOCK
		BSR	_LoadDisk	
		BRA	.versionTest
.filesversionUS

		lea	_FileVersion(pc),a1
		move.l	#1,(A1)
		lea	_Boot2Name(pc),a0
		move.l	a4,a1
		bsr	_ReadFile
		BRA	.versionTest

;***************************;***************************;***************************
;***************************;***************************;***************************
;***************************	File version V1,V2,V3 patch boot block
;***************************;***************************;***************************
;***************************;***************************;***************************
.filesversion

	IFD	_FlashFiles
.t	move.w	#$f0,$dff180
	btst	#6,$bfe001
	bne	.t	
	ENDC
		patch2	$298(A4),_LoadFilePart200	; PATCH DOIT FUNCTION FOR TRACKDISKDEVICE
		lea	_FileVersion(pc),a1
		move.l	#1,(A1)
	;call bootblock
		lea	($2c,a5),a1
		jmp	(12,a4)
_FileVersion	dc.l	0
	


pl_version_1
	PL_START
	PL_W	$7FFE,$7001		; skip protection;
	; menu keyboard read: joypad FWD+BWD = ESC
	PL_PSS	$1362C-$B8C0,keyboard_read,4
	
	PL_IFC1
	; remove mouse read
	PL_W	$136D4-$B8C0,$7000
	PL_NOP	$136D6-$B8C0,4
	; double joystick read
	PL_PS	$13674-$B8C0,joysticks_menu_read
	PL_ELSE
	PL_PS	$13674-$B8C0,joysticks_menu_read_mouse
	PL_ENDIF
	
	PL_END


pl_version_2
	PL_START
	PL_W	$7F42,$7001		; skip protection;
	PL_B	$9AE,$60        ; Skip NTSC test (freezed on title screen;
	; menu keyboard read: joypad FWD+BWD = ESC
	PL_PSS	$13524-$B8C0,keyboard_read,4
	
	PL_IFC1
	; remove mouse read
	PL_W	$135CC-$B8C0,$7000
	PL_NOP	$135CE-$B8C0,4
	; double joystick read
	PL_PS	$1356C-$B8C0,joysticks_menu_read
	PL_ELSE
	PL_PS	$1356C-$B8C0,joysticks_menu_read_mouse
	PL_ENDIF
	
	PL_END
	
pl_version_3
	PL_START
	PL_W	$7F42,$7001		; skip protection;
	; menu keyboard read: joypad FWD+BWD = ESC
	PL_PSS	$13570-$B8C0,keyboard_read,4
	
	PL_IFC1
	; remove mouse read
	PL_W	$13618-$B8C0,$7000
	PL_NOP	$1361A-$B8C0,4
	; double joystick read
	PL_PS	$135B8-$B8C0,joysticks_menu_read
	PL_ELSE
	PL_PS	$135B8-$B8C0,joysticks_menu_read_mouse
	PL_ENDIF
	
	PL_END

	
keyboard_read
	move.l	joy0(pc),d0
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.j1
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.j1
	bra.b	.esc
.j1
	move.l	joy1(pc),d0
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.kb
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.kb
.esc
	move.b	#$45,d0
	bra.b	.out
.kb
	MOVE.B $00bfec01,D0
    ROR.B #$01,D0
    NOT.B D0
.out
	rts
	
joysticks_menu_read_mouse
	bsr	_joystick
	lea	$DFF00C,A0
	RTS

joysticks_menu_read
	movem.l	d0-d2,-(a7)
	move.l	$DFF00A,d2	; save value
	bsr	_joystick
	move.l	joy1(pc),d0
	bne.b	.joy1_move
	; check if all directions neutral. If all neutral, check 2nd joystick
	swap	d2
.joy1_move
	lea	.joybuff(pc),a0
	move.w	d2,(a0)
	movem.l	(a7)+,d0-d2
	rts
	
.joybuff
	dc.w	0
	
;---------------------------
;===============V1
;---------------------------
;---------------------------
_TestJoy0Gen
	move.l	joy1(pc),d0
		btst	#JPB_BTN_BLU,d0	; fix second button winuae
		bne	.noSB
	btst	#JPB_BTN_RED,d0
	beq	.noSB
	bset	#7,d3			; fire
.noSB	rTs
;---------------------------
;---------------------------
_TestJoy1Gen
	move.l	joy0(pc),d0
	tst.b	d1			; 2PL mode=>0? 1PL mode=>2
	beq	.2PLmode
	move.l	joy1(pc),d0
.2PLmode	

	move.l	_mouse_as_joy(pc),d1
;;	btst	#1,d1			; CD32 PAD FOR PLAYER 2 MOUSE PORT
	BEQ	.noCD32PAD	
	; JOTD: up & down were reversed
	btst	#JPB_BTN_DOWN,d0
	beq	.noU
	bset	#1,d3			; UP
.noU	btst	#JPB_BTN_UP,d0
	beq	.noD
	bset	#0,d3			; DOWN
.noD	btst	#JPB_BTN_LEFT,d0
	beq	.noL
	bset	#2,d3			; LEFT
.noL	btst	#JPB_BTN_RIGHT,d0
	beq	.noR
	bset	#3,d3			; RIGHT
.noR
.noCD32PAD
		btst	#JPB_BTN_BLU,d0	; fix second button winuae
		bne	.noSB
	btst	#JPB_BTN_RED,d0
	beq	.noSB
	bset	#7,d3			; fire
.noSB
	rts
;---------------------------
;---------------------------
_TakePL1JOY1
	bsr	_CD32_Read
	move.l	d0,-(a7)

	move.b	-$41D3(a4),d3
	bsr	_TestJoy0Gen
	move.b	D3,-$41D3(a4)

	move.B	-$41D3(A4),-2(A5)	; $8x=Fire | $01=Sown | $02=Up | $04=Left | $08= Right
	move.l	(a7)+,d0
	rts

;---------------------------
_TakePL2JOY0
	bsr	_CD32_Read
	movem.l	d0-d1,-(a7)

	move.B	-$7460(A4),d1		; 1PL MODe =>$02
	move.b	-$41D4(a4),d3
	bsr	_TestJoy1Gen
	move.b	D3,-$41D4(a4)

	movem.l	(a7)+,d0-D1
	move.B	-$41D4(A4),-2(A5)	; $8x=Fire | $01=Down | $02=Up | $04=Left | $08= Right
	rts
	

ROK_MACRO:MACRO
rest_of_keys_\1_\2
	btst	#JPB_BTN_REVERSE,d3
	beq	.no_retreat
	btst	#JPB_BTN_FORWARD,d3
	beq	.no_retreat
	move.b	#$\2,-$\1(a4)		; RShift
.no_retreat
	rts
	ENDM
	
	; player 1
	ROK_MACRO	41DC,45
	ROK_MACRO	41E8,45
	ROK_MACRO	41DE,45
	; player 2
	ROK_MACRO	41DC,41
	ROK_MACRO	41E8,41
	ROK_MACRO	41DE,41
	
;---------------------------
_TakeSpecialKeyPL1
;	bsr	_CD32_Read
	move.l	joy1(pc),d3
	btst	#JPB_BTN_BLU,d3
	beq	.noSB
	move.b	D4,-$41DC(a4)		; RShift
.noSB
	bsr	rest_of_keys_41DC_45
	move.b	-$41DC(a4),d3		; $61=RShift | $45=Esc $60= Left
	ext.W	d3
	rts
;---------------------------
_TakeSpecialKeyPL2
;	bsr	_CD32_Read
	move.l	joy0(pc),d3
	btst	#JPB_BTN_BLU,d3
	beq	.noSB
	move.b	#$61,-$41DC(a4)		; RShift
.noSB
	bsr	rest_of_keys_41DC_41

	move.b	-$41DC(a4),d3		; $61=RShift | $45=Esc $60= Left
	ext.W	d3
	rts
;---------------------------

	
;==============V2
_TakePL1JOY1_V2
	bsr	_CD32_Read
	move.l	d0,-(a7)

	move.b	-$41DF(a4),d3
	bsr	_TestJoy0Gen
	move.b	D3,-$41DF(a4)
.noSB	
	move.B	-$41DF(A4),-2(A5)	; $8x=Fire | $01=Sown | $02=Up | $04=Left | $08= Right

	move.l	(a7)+,d0
	rts
;---------------------------
_TakePL2JOY0_V2
	bsr	_CD32_Read
	movem.l	d0-d1,-(a7)
	move.B	-$746C(A4),d1		; 1PL MODe =>$02
	move.b	-$41E0(a4),d3
	bsr	_TestJoy1Gen
	move.b	D3,-$41E0(a4)
	move.B	-$41E0(A4),-2(A5)	; $8x=Fire | $01=Down | $02=Up | $04=Left | $08= Right
	movem.l	(a7)+,d0-D1
	rts
;---------------------------
_TakeSpecialKeyPL1_V2
	bsr	_CD32_Read
	move.l	joy1(pc),d3
	btst	#JPB_BTN_BLU,d3
	beq	.noSB
	move.b	D4,-$41E8(a4)		; LShift
.noSB
	bsr	rest_of_keys_41E8_45
	move.b	-$41E8(a4),d3
	ext.W	d3			; $60=LShift | $45=Esc
	rts
;---------------------------
_TakeSpecialKeyPL2_V2
	bsr	_CD32_Read
	move.l	joy0(pc),d3
	btst	#JPB_BTN_BLU,d3
	beq	.noSB
	move.b	#$61,-$41E8(a4)		; RShift
.noSB
	bsr	rest_of_keys_41E8_41
	move.b	-$41E8(a4),d3		; $61=RShift | $45=Esc
	ext.W	d3
	rts
;---------------------------


;==============V3
_TakePL1JOY1_V3
	bsr	_CD32_Read
	move.l	d0,-(a7)

	move.b	-$41D5(a4),d3
	bsr	_TestJoy0Gen
	move.b	D3,-$41D5(a4)
.noSB
	move.B	-$41D5(A4),-2(A5)	; $8x=Fire | $01=Sown | $02=Up | $04=Left | $08= Right

	move.l	(a7)+,d0
	rts
;---------------------------
_TakePL2JOY0_V3
	bsr	_CD32_Read

	movem.l	d0-d1,-(a7)
	move.B	-$7460(A4),d1		; 1PL MODe =>$02
	move.b	-$41D6(a4),d3
	bsr	_TestJoy1Gen
	move.b	D3,-$41D6(a4)
	movem.l	(a7)+,d0-D1

	move.B	-$41D6(A4),-2(A5)	; $8x=Fire | $01=Down | $02=Up | $04=Left | $08= Right
	rts
;---------------------------
_TakeSpecialKeyPL1_V3
	bsr	_CD32_Read
	move.l	joy1(pc),d3
	btst	#JPB_BTN_BLU,d3
	beq	.noSB
	move.b	D4,-$41DE(a4)		; LShift
.noSB
	bsr	rest_of_keys_41DE_45
	move.b	-$41DE(a4),d3
	ext.W	d3			; $60=LShift | $45=Esc
	rts
;---------------------------
_TakeSpecialKeyPL2_V3
	bsr	_CD32_Read
	move.l	joy0(pc),d3
	btst	#JPB_BTN_BLU,d3
	beq	.noSB
	move.b	#$61,-$41DE(a4)		; RShift
.noSB
	bsr	rest_of_keys_41DE_41
	move.b	-$41DE(a4),d3		; $61=RShift | $45=Esc
	ext.W	d3
	rts
;---------------------------


_CD32_Read	move.l	d0,-(A7)
		bsr	_joystick
		move.l	(a7)+,d0
		rts
;----------------------------
_Crack
	move.w	#$32E0,d6
	rts
;---------------------------
_LoadFilePart200Game
	movem.l	D3-D4/a3-a4,-(a7)
	lea	_GameName(pc),a4
	move.l	(A3),(a4)	; take name of file
	move.l	4(A3),4(a4)	; take name of file
	move.l	8(A3),8(a4)	; take name
	move.l	a1,a3		; TRackDiskDEvice struct

	move.l	_GameName(pc),D4
	move.l	_GameNamePrec(pc),D3
	cmp.l	d3,D4
	beq	.ok
	bsr	_ResetFileinfo
.ok
	bsr	_LoadFilePart200
	movem.l	(a7)+,d3-D4/a3-A4
	rts

_LoadFilePart200
	move.l	4,a6
	movem.l	d0-a6,-(a7)
	cmp.w	#$c,$1C(a1)
	beq	.skip
	cmp.w	#$9,$1C(a1)
	beq	.skip
	cmp.L	#$0,$24(a1)
	beq	.skip
	cmp.L	#$1600,$2C(a1)	; no data on track 1
	beq	.skip
	
	move.l	$24(a1),d0	; LG
	move.l	$2C(a1),d1	; OFFSET
	move.l	$28(a1),a1	; dest


	lea	_GameName(pc),a0
	cmp.l	#$400,d1	; DiR
	bne	.pasdir

	lea	_DirectoryAdr(pc),a0
	move.l	a1,(a0)			; save directory adress
	lea	_DIR1Name(pc),a0	
	clr.l	D1
	bsr	_LoadFileOffset
	bsr	_TakeFirstFileInfo
.skip	movem.l	(a7)+,d0-a6
	rts
;//////////////////////
.pasdir

	bsr	_TakeFileInfo	

	move.l	_FileLengthAdr(pc),d2
	sub.l	_FileOffsetAdr(pc),d1	; start offset
	move.l	d1,d3
	add.l	#$200,d3
	cmp.l	D3,D2
	bHS	.cont
	; end of file
	DIVU	#$200,D2
	SWAP.W D2
	AND.L	#$fff,D2
	MOVE.L	D2,D0
	bsr	_LoadFileOffset
	bsr	_ResetFileinfo
	LEA	_GameNamePrec(PC),a0
	move.l	_GameName(pc),(a0)
	movem.l	(a7)+,d0-a6
	rts	
;//////////////////////
.cont	bsr	_LoadFileOffset
	LEA	_GameNamePrec(PC),a0
	move.l	_GameName(pc),(a0)
	movem.l	(a7)+,d0-a6
	rts	
;//////////////////////
_ResetFileinfo
	movem.l d0-D2/a0-A2,-(a7)
	move.l	_DirectoryAdr(pc),a0
	lea	_GameName(pc),a4
	lea	_FileOffsetAdr(pc),a1
	lea	_FileLengthAdr(pc),a2
	clr.l	(a4)
	clr.l	4(a4)
	clr.l	8(a4)
	clr.l	(a1)
	clr.l	(a2)
	movem.l (a7)+,d0-D2/a0-A2
	rts
_TakeFirstFileInfo
	move.l	_DirectoryAdr(pc),a0
	lea	_GameName(pc),a4
	lea	_FileOffsetAdr(pc),a1
	lea	_FileLengthAdr(pc),a2
	move.l	(a4),d0	
	tst.l	d0
	bne	.nom
	; take FIRST NAME & file info: 'ns.am2'
	move.l	(A0),(a4)	; take name of file
	move.l	4(A0),4(a4)	; take name of file
	move.l	8(A0),8(a4)	; take name
	MOVE.L	$C(A0),(A1)	; start offset of file
	MOVE.L	$10(A0),(A2)	; length file
.nom	rts

_TakeFileInfo
	movem.l d0-D2/a0-A2,-(a7)
	move.l	_DirectoryAdr(pc),a0
	lea	_GameName(pc),a4
	lea	_FileOffsetAdr(pc),a1
	lea	_FileLengthAdr(pc),a2
	move.l	(a2),d0	
	tst.l	d0
	bne	.nom
	; take NAME & info of file
	move.l	#$200/$14-1,d2
.nextfile
	move.l	$C(a0),D0
	tst.l	d0
	beq	.endofdir
	cmp.l	d1,d0			; start offset?
	beq	.found
	lea	$14(A0),a0		; next file info
	dbf	d2,.nextfile
.endofdir
.error move.w	#$F00,$DFF180
	bra	.error
.found
	move.l	(A0),(a4)	; take name of file
	move.l	4(A0),4(a4)	; take name of file
	move.l	8(A0),8(a4)	; take name
	MOVE.L	$C(A0),(A1)	; start offset of file
	MOVE.L	$10(A0),(A2)	; length file
.nom	movem.l (a7)+,d0-D2/a0-A2
	rts



_FileOffsetAdr	dc.l	0
_FileLengthAdr	dc.l	0
_DirectoryAdr	dc.l	0
;--------------------------------
_GetFileSize
	movem.l	d1-a6,-(a7)
;	lea	_FileName(pc),a0
	move.l	(_resload,pc),a2
	jsr	(resload_GetFileSize,a2)
	movem.l	(a7)+,d1-a6
	rts
;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts
;--------------------------------
_Decrunch
		movem.l	d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_Decrunch(a2)
		movem.l	(a7)+,d1/a0-a2
		rts
;--------------------------------
_Relocate
		movem.l	d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_Relocate(a2)
		movem.l	(a7)+,d1/a0-a2
		rts
;--------------------------------
_ReadFile	movem.l	d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)
		movem.l	(a7)+,d1/a0-a2
		rts
;--------------------------------
_LoadFileOffset	movem.l	d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_LoadFileOffset(a2)
		movem.l	(a7)+,d1/a0-a2
		rts
;--------------------------------
_AllocMem:
	move.l Execbase,a6
	move.l	LG_ALLOC_MEM(PC),d0
	MOVE.L #$10002,D1		; clear+chip
;	MOVE.L #$10004,D1		; clear+fast
	JSR	_LVOAllocMem(A6)

	LEA	ADR_ALLOC_MEM(PC),A1
	MOVE.L	D0,(A1)
r	rts
;--------------------------------------
_FreeMem:
	move.l	Execbase,a6
	move.l	ADR_ALLOC_MEM(pc),a1
	move.l	LG_ALLOC_MEM(pc),d0
	tst.l	d0
	beq	.no
	jsr	_LVOFreeMem(a6)
.no	RTS
;--------------------------------------
LG_ALLOC_MEM		dc.l	$B800+19000
ADR_ALLOC_MEM		dc.L	0
;--------------------------------------
_Boot2Name	dc.b 'boot2.bin',0
_DIR1Name	dc.b 'DIR1',0
dosname		dc.b	'dos.library',0
		even
_GameName	dc.l	0,0,0,0		; leave it!!!! name buffer =>if not crash
_GameNamePrec	dc.l	0
;============================================================================;
_tag		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
_mouse_as_joy	dc.l	0
;		dc.l	WHDLTAG_CUSTOM2_GET
;_custom2	dc.l	0
;		dc.l	WHDLTAG_CUSTOM3_GET
;_custom3	dc.l	0
;		dc.l	WHDLTAG_CUSTOM4_GET
;_custom4	dc.l	0
;		dc.l	WHDLTAG_BUTTONWAIT_GET
;_ButtonWait	dc.l	0
		dc.l	TAG_END;0	; End
;====================================================================== 

;
;============================================================================;
;
	END;
	IFD	_Flash
.t	move.w	#$f0,$dff180
	btst	#6,$bfe001
	bne	.t	
	ENDC
