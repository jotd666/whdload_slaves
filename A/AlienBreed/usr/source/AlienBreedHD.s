***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       ALIEN BREED WHDLOAD SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               July 2018                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 25-Jul-2018	- music wasn't replayed properly in main menu, reason was a
;		  wrong interrupt fix, main interrupt code must be called at
;		  the end of the VBI in main menu
;		- CUSTOM3 can be used to run the "1MB Required" part, thanks
;		  to Bored Seal for the idea :)

; 24-Jul-2018	- help screen removed for now!
;		- patch is finished for now

; 22-Jul-2018	- added "help screen" to display in-game keys when help
;		  has been pressed, not sure it'll stay though as I didn't
;		  find a 100% reliable solution for the screen memory yet

; 21-Jul-2018	- fixed the problem with opening/closing map screen with
;		  joypad, rawkey is now cleared each VBI before reading
;		  the joypad buttons, seems to work reliable

; 20-Jul-2018	- proper pause handling now when using joypad
;		- access fault fix fixed :) no more refresh bugs

; 19-Jul-2018	- Joypad routine now uses actual bits instead of bit numbers
;		  so checking if 2 or more button have been pressed
;		  simultaneously is possible, logic adapted (and -> eor)

; 18-Jul-2018	- rewritten joypad reading code fixed :)
;		- joypad code works properly now
;		- joypad base code optimised a bit

; 17-Jul-2018	- a few problems regarding joypad emulation fixed
;		- Joypad reading code rewritten, also not tested yet

; 16-Jul-2018	- some more in-game keys added
;		- quit key works in main menu now too
;		- default quitkey changed back to F10
;		- end picture patched, game can be quit using either mouse/
;		  joystick buttons or using quitkey
;		- main menu patched, VBI fixed, SMC fixed, high-score
;		  load/save added
;		- added JOTD's Joypad reading code, it needs to be enabled
;		  with CUSTOM2 and is untested so far

; 15-Jul-2018	- Intex computer patched, annoying "efford" typo fixed,
;		  start with max. money and unlimited money trainers now
;		  implemented, cache flush after relocating embedded exe
;		  in Intex Computer exe added
;		- start with all weapons and map trainer added

; 14-Jul-2018	- interrupts fixed
;		- ButtonWait support for mission texts
;		- 68000 quitkey support for main game
;		- lots of trainer options added
;		- Reset (GURU TIME cheat) patched to quit back to DOS

; 13-Jul-2018	- decryption for title part fixed, no more crash in snoop
; a Friday :)	  mode
;		- started to patch main game, starts now but needs more
;		  fixes
;		- Bplcon0 color bit fixes, long writes to $dff100 fixed,
;		  access faults fixed

; 12-Jul-2018	- generic decrypter for all encrypted files coded

; 11-Jul-2018	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem|WHDLF_NoKbd
QUITKEY		= $59		; F10
;DEBUG

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM

DECL_VERSION:MACRO
	dc.b	"2.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	19		; ws_version
	dc.w	FLAGS		; flags
	dc.l	524288		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	IFD	DEBUG
	dc.w	.dir-HEADER	; ws_CurrentDir
	ELSE
	dc.w	0		; ws_CurrentDir
	ENDC
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
	dc.b	QUITKEY		; ws_KeyExit
	dc.l	$80000		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"BW;"
	dc.b	"C2:B:Enable Joypad Support;"
	dc.b	"C3:B:Enable ""No Extra Memory Found"" Part;"
	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Energy:1;"
	dc.b	"C1:X:Unlimited Ammo:2;"
	dc.b	"C1:X:Unlimited Keys:3;"
	dc.b	"C1:X:Unlimited Money:4;"
	dc.b	"C1:X:Start with max. Money:5;"
	dc.b	"C1:X:Start with max. Keys:6;"
	dc.b	"C1:X:Start with all Weapons and Map:7;"
	dc.b	"C1:X:In-Game Keys:8;"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/AlienBreed",0
	ENDC

.name	dc.b	"Alien Breed",0
.copy	dc.b	"1991 Team 17",0
.info	dc.b	"installed by Mr.Larmer/JOTD (until V2.2)",-1
	dc.b	"StingRay/[S]carab^Scoopex (V2.3 recode)",-1
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	DECL_VERSION
	dc.b	0
HighName	dc.b	"AlienBreed.high",0

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

	CNOP	0,2


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
TRAINEROPTIONS	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
JOYPADSUPPORT	dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
NOEXTRAMEMPART	dc.l	0
		dc.l	TAG_END

TR_INGAMEKEYS	= 8		; bit for in-game keys options

_resload:
resload:
	dc.l	0

	include	ReadJoyPad.s

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

; install keyboard irq
	bsr	SetLev2IRQ

	move.l	NOEXTRAMEMPART(pc),d0
	beq.b	.normal
	moveq	#22,d0
	moveq	#78,d1
	lea	$40000,a0
	move.l	a0,a5
	bsr	Loader
	lea	PLNOMEM_PRE(pc),a0
	lea	$40000,a1
	jsr	resload_Patch(a2)
	jmp	$40000
.normal	

; load and decrypt title
	moveq	#100,d0
	moveq	#80,d1
	lea	$30000,a0
	move.l	a0,a5
	bsr	Loader

	move.l	#80*512,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$f265,d0		; SPS 998
	beq.b	.ok

.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

; patch
	lea	PLTITLE(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	lea	$7fffc,a7
	lea	$7f800,a0
	move.l	a0,USP


; store ext. mem ptr
	move.l	HEADER+ws_ExpMem(pc),d0
; memory is aligned like this in the original but this is
; not necessary
	;add.l	#$60000,d0
	;and.l	#$fff80000,d0
	move.l	d0,$7fffc


; create code at $3f4.w
	lea	$3f4.w,a0
	move.l	#$53e2577e,d5
	move.l	#$4b83c5be,d6
	move.l	#$000041fa,d7

	move.l	#$1E1B57A1,d2
	move.l	#$BB83F582,d3
	move.l	#$7FFF0F8F,d4

	eor.l	d2,d5
	eor.l	d3,d6
	eor.l	d4,d7
	move.l	d5,(a0)+
	move.l	d6,(a0)+
	move.l	d7,(a0)
	move.l	d5,$200.w
	


; set default VBI
	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w

; and start game
	jmp	(a5)



QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


KillSys	move.w	#$7fff,$dff09a
	bsr	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts

AckVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rte

PLNOMEM_PRE
	PL_START
	PL_P	$6f4,.patchNoMem1	; patch after decrunching
	PL_END

.patchNoMem1
	lea	PLNOMEM1(pc),a0
	lea	$60000+$20,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$60020

PLNOMEM1
	PL_START
	PL_P	$ae,.patchNoMem		; now patch the real decrunched part

	PL_SA	$6c,$70			; skip pea $40(a4)
	PL_W	$7a,$4e71		; disable rts
	PL_L	$38+2,$60000		; don't trash decruncher code
	PL_END

.patchNoMem
	lea	PLNOMEM(pc),a0
	move.l	a4,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	move.w	#$7fff,(a5)
	move.w	#$7fff,4(a5)		; disable DMA, original code
	move.w	d5,sr			; SR: 0, original code
	jmp	(a4)

PLNOMEM	PL_START
	PL_PS	$1e,.enableKbd
	PL_END

.enableKbd
	bsr	SetLev2IRQ
	move.w	#$8380,$96(a6)		; original code, enable DMA
	rts


PLTITLE	PL_START
	PL_P	$1606,Loader
	PL_P	$ab66,AckVBI
	PL_ORW	$e7c+2,1<<3		; enable level 2 interrupts
	PL_P	$2046,.patch_premain	; file 1c_15
	PL_END

.patch_premain
	lea	PLPREMAIN(pc),a0
	pea	$8000
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)

FlushCache
	move.l	resload(pc),a0
	jsr	resload_FlushCache(a0)
	movem.l	(a7)+,d0-a6		; original code
	rts

PLPREMAIN
	PL_START
	PL_P	$241a,.patchmain
	PL_P	$253e,FlushCache	; flush cache after relocating
	PL_END
	


; main file has been decrypted and relocated, patch it
.patchmain
	movem.l	d0-a6,-(a7)

	lea	PLMAIN(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

; patch copperlists in data section
; data section relocation start is $600
; data section offset in executable is $7ee84
	lea	PLMAIN_CHIP(pc),a0
	lea	$600.w,a1
	jsr	resload_Patch(a2)

; load high scores
	lea	HighName(pc),a0
	move.l	a5,a1
	add.l	#$200bc,a1
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.noHigh
	lea	HighName(pc),a0
	move.l	a5,a1
	add.l	#$200bc,a1
	jsr	resload_LoadFile(a2)
.noHigh


; install trainers
	move.l	TRAINEROPTIONS(pc),d0

; unlimited lives
	lsr.l	#1,d0
	bcc.b	.noUnlimitedLives
	eor.b	#$19,$749c(a5)		; subq.w <-> tst.w

.noUnlimitedLives

; unlimited energy
	lsr.l	#1,d0
	bcc.b	.noUnlimitedEnergy
	move.l	#$bcd4,d1		; player 1
	move.w	#1,(a5,d1.l)
	move.w	#1,2(a5,d1.l)		; player 2
.noUnlimitedEnergy

; unlimited ammo
	lsr.l	#1,d0
	bcc.b	.noUnlimitedAmmo
	move.l	#$d950,d1
	eor.b	#$19,(a5,d1.l)		; subq.w <-> tst.w
.noUnlimitedAmmo

; unlimited keys
	lsr.l	#1,d0
	bcc.b	.noUnlimitedKeys
	move.w	#1,$7b3a(a5)
.noUnlimitedKeys

; unlimited money (done in the PLINTEXCOMPUTER patch list)
	lsr.l	#1,d0
.noUnlimitedMoney

; start with max. money (done in the PLINTEXCOMPUTER patch list)
	lsr.l	#1,d0
.noMaxMoney

; start with max. keys
	lsr.l	#1,d0
	bcc.b	.noMaxKeys
	pea	30000
	move.l	(a7),$5a5a(a5)		; player 1
	move.l	(a7)+,$61fa(a5)		; player 2
.noMaxKeys

; start  with all weapons and map
	lsr.l	#1,d0
	bcc.b	.noAllWeapons
	move.w	#%11111111,$28a0+2(a5)
	;addq.w	#1,$794(a5)		; "has map" flag is cleared in init part
	move.w	#$4e71,$d9c(a5)
.noAllWeapons


	move.l	JOYPADSUPPORT(pc),d0
	beq.b	.noJoypad
	bsr	_detect_controller_types
.noJoypad

	movem.l	(a7)+,d0-a6

.nomain	lea	$7fc00,a7		; original code
	jmp	(a5)
	
PLMAINMENU
	PL_START
	PL_PS	$2d2,.sethiflag		; set "high score achieved" flag
	PL_PS	$9e,.savehighscores
	PL_PSA	$181e,.SaveVBI,$1828	; don't modify VBI code
	PL_P	$1834,.RestoreVBI	; restore old VBI
	PL_P	$18d8,.AckVBI
	PL_END

.AckVBI	move.l	HEADER+ws_ExpMem(pc),-(a7)
	add.l	#$1644,(a7)		; call main interrupt code
	rts

.SaveVBI
	move.l	a0,-(a7)
	lea	.oldVBI(pc),a0
	move.l	$6c.w,(a0)
	move.l	(a7)+,a0
	rts

.RestoreVBI
	move.l	.oldVBI(pc),$6c.w
	rts

.oldVBI	dc.l	0

.savehighscores
	movem.l	d0-a6,-(a7)

	lea	.hiflag(pc),a0
	tst.b	(a0)
	beq.b	.nohigh
	sf	(a0)

	move.l	TRAINEROPTIONS(pc),d0	; no saving if any trainers are used
	bne.b	.nohigh
	lea	HighName(pc),a0
	move.l	HEADER+ws_ExpMem(pc),a1
	add.l	#$200bc,a1
	move.l	resload(pc),a2
	move.l	#$6f4-$654,d0		; size
	jsr	resload_SaveFile(a2)
.nohigh

	movem.l	(a7)+,d0-a6

	moveq	#8,d0			; optimised original code
	rts


.sethiflag
	move.l	a0,-(a7)
	lea	.hiflag(pc),a0
	st	(a0)
	move.l	(a7)+,a0

	clr.b	(a0)+			; original code
	clr.b	(a0)+
	clr.b	(a0)+
	
	rts

.hiflag	dc.b	0
	dc.b	0

PLINTEXCOMPUTER
	PL_START
	PL_P	$a8a,FlushCache		; there is an exe embedded, flush
					; cache after relocating
	PL_B	$2471+14,"A"		; fix "efford" typo :)

; unlimited money
	PL_IFC1X	4
	PL_W	$be6,$4e71		; sub.l d1,(a5) -> nop (tools)
	PL_W	$14d2,$4e71		; sub.l d0,d1 -> nop (weapons)

	PL_ENDIF
	PL_END

PLMAIN_CHIP
	PL_START
	PL_ORW	($83fc2-$7ee84)+2,1<<9	; set Bplcon0 color bit
	PL_ORW	($8457e-$7ee84)+2,1<<9	; set Bplcon0 color bit
	PL_END



PLMAIN	PL_START
	PL_SA	$f4c6,$f4d0		; skip long write to $dff100
	PL_P	$239ae,FlushCache	; flush cache after relocating
	PL_P	$ada6,Loader	
	PL_PS	$f61a,ChangeDisk
	;PL_AL	$10978+2,4		; fix access fault
	;PL_AL	$10982+2,4		; fix access fault
	PL_PS	$10904,.fix

	PL_PSS	$21274,AckLev4,2
	PL_PSS	$17bc,AckVBI_R,2
	PL_PSS	$17da,AckCOP_R,2
	PL_PS	$2004e,.checkkeys
	PL_P	$be2a,QUIT		; reset ("GURU TIME" cheat) -> quit

	PL_PS	$e754,.PatchMainMenu
	PL_PS	$d2a8,.PatchIntexComputer


	PL_IFBW
	PL_PS	$e976,.WaitButtonMissionText
	PL_ENDIF

	PL_P	$cf2,.PatchEnd

; Mr.Larmer patches
	PL_PS	$a6d6,Protection

; JOTD patches

	PL_END

.fix	move.l	(a0)+,d0
	bne.b	.dest_ok
	addq.l	#4,d0
.dest_ok
	move.l	d0,a1
	move.w	-4(a1),d0
	rts


.PatchMainMenu
	movem.l	d0-a6,-(a7)
	lea	PLMAINMENU(pc),a0
	lea	($a8edc-$7ee84)+$600,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	move.w	#1<<15+1<<3,$dff09a	; enable level 2 interrupts in main menu
	rts

.PatchEnd
	move.l	HEADER+ws_ExpMem(pc),a0
	add.l	#$20f20,a0
	jsr	(a0)			; call original routine

	move.l	#100000*10,d0		; more than 27 hours should be enough :)
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)
	bra.w	QUIT


.PatchIntexComputer
	movem.l	d0-a6,-(a7)
	move.l	a0,a5

	lea	PLINTEXCOMPUTER(pc),a0

; $600: start of relocated data section
; $a8edc: offset to intex computer executable in binary
; $7ee84: start offset of data section in binary
	lea	($a8edc-$7ee84)+$600,a1

	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	lea	TRAINEROPTIONS(pc),a0
	tst.w	.moneyset-TRAINEROPTIONS(a0)
	bne.b	.noMaxMoney
	addq.w	#1,.moneyset-TRAINEROPTIONS(a0)
	move.l	(a0),d0
	btst	#5,d0
	beq.b	.noMaxMoney

; set 500000 credits
	move.l	a5,a0
	move.l	#500000*2*50,(a0)
.noMaxMoney

	movem.l	(a7)+,d0-a6
	jmp	($a8edc-$7ee84)+$600

.moneyset	dc.w	0


.WaitButtonMissionText
	move.l	a0,-(a7)
	moveq	#10*10,d0	; 10 seconds
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)
	move.l	(a7)+,a0
	moveq	#32,d0		; optimised original code
	rts


.pause_status	dc.w	0


.checkkeys
	bsr.w	.getkey
	ror.b	d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT


; check joypad buttons
	move.l	JOYPADSUPPORT(pc),d1
	beq.b	.nojoypad


; clear raw key to avoid problems (f.e. with map screen)
	move.l	HEADER+ws_ExpMem(pc),a0
	add.l	#$200ba,a0
	clr.b	(a0)

	move.w	d0,-(a7)
	bsr	ReadJoypad
	move.w	(a7)+,d0
	tst.b	d2			; was a button pressed?
	;beq.b	.nojoypad
	bmi.w	QUIT


	lea	.pause_status(pc),a0
	cmp.w	#$19,d2
	bne.b	.noP

	tst.b	(a0)
	beq.b	.first_time

	moveq	#0,d2			; clear key code -> wait until
	bra.b	.ok			; button has pressed again


.first_time
	st	(a0)			; set pause_status flag
	bra.b	.ok


.noP	clr.b	(a0)


.ok	move.b	d2,d0			; yes, return mapped key
	beq.b	.nojoypad
	lsl.b	d0
	not.b	d0
	rts
.nojoypad

	move.l	TRAINEROPTIONS(pc),d1
	btst	#TR_INGAMEKEYS,d1
	beq.b	.nokeys

	move.l	HEADER+ws_ExpMem(pc),a5	; start of executable
	lea	.TAB(pc),a0
.search	movem.w	(a0)+,d1/d2
	cmp.b	d0,d1
	bne.b	.next

	jsr	.TAB(pc,d2.w)
	bra.b	.nokeys

.next	tst.w	(a0)
	bne.b	.search

.nokeys

.getkey	move.b	$bfec01,d0
	rts

.TAB	dc.w	$36,.SkipLevel-.TAB	; n - skip level
	dc.w	$12,.RefreshEnergy-.TAB	; e - refresh energy
	dc.w	$27,.MaxKeys-.TAB	; k - get max. keys
	dc.w	$20,.RefreshAmmo-.TAB	; a - refresh ammo
	dc.w	$28,.RefreshLives-.TAB	; l - refresh lives
	dc.w	$25,.GetMap-.TAB 	; h - get hand map
	dc.w	$11,.GetWeapons-.TAB	; w - get all weapons
	dc.w	0			; end of tab

.SkipLevel
	move.w	#1,$822(a5)
	rts

.RefreshEnergy
	move.w	#$40,$58fa+$150(a5)	; player 1
	move.w	#$40,$609a+$150(a5)	; player 2
	rts

.MaxKeys
	move.w	#30000,$58fa+$160(a5)	; player 1
	move.w	#30000,$609a+$160(a5)	; player 2
	rts

.RefreshAmmo
	move.w	#32,$58fa+$15c(a5)	; player 1
	move.w	#32,$609a+$15c(a5)	; player 2
	rts

.RefreshLives
	move.w	#4,$58fa+$154(a5)	; player 1
	move.w	#4,$609a+$154(a5)	; player 2

.GetMap	move.w	#1,$794(a5)
	rts

.GetWeapons
	move.w	#%11111111,d2
	move.w	d2,$58fa+$192(a5)	; player 1
	move.w	d2,$609a+$192(a5)	; player 2
	rts


; returns result in d2, either mapped rawkey or 0 if no button was pressed
; -1 if quit
ReadJoypad
	lea	.joy(pc),a0		; read joystick in port 2 only
	move.b	controller_joypad_1(pc),d0
	beq.b	.joy_only
	lea	.pad(pc),a0		; read full CD32 pad
.joy_only
	jsr	(a0)

	moveq	#0,d2
	lea	.TAB(pc),a0
.loop	move.l	joy0(pc),d0
	move.l	(a0)+,d1		; port
	beq.b	.port0
	move.l	joy1(pc),d0
	subq.b	#1,d1
	beq.b	.port1
	or.l	joy0(pc),d0	; both ports
.port1

.port0

	move.l	(a0)+,d1
	move.l	(a0)+,d3

	and.l	d1,d0
	eor.l	d1,d0
	bne.b	.no_button
	move.w	d3,d2

.no_button
	tst.l	(a0)			; check all entries in table
	bpl.b	.loop
	rts

.pad	bra.w	_joystick

.joy	moveq	#1,d0			; port 1
	bsr	_read_joystick
	lea	joy1(pc),a0
	move.l	d0,(a0)
	rts


; joypad port (0,1,both), joypad button, mapped rawkey
.TAB	dc.l	1,JPF_BTN_GRN,$64	; left alt, change weapons player 1
	dc.l	0,JPF_BTN_GRN,$65	; right alt, change weapons player 2
	dc.l	2,JPF_BTN_YEL,$37	; M, open map
	dc.l	2,JPF_BTN_BLU,$40	; Space, enter intex computer
	dc.l	2,JPF_BTN_PLAY,$19	; P, pause

	dc.l	2,JPF_BTN_FORWARD+JPF_BTN_REVERSE,$45	; ESC
	dc.l	2,JPF_BTN_FORWARD+JPF_BTN_REVERSE+JPF_BTN_PLAY,-1	; quit
	dc.l	-1			; end of tab

	CNOP	0,2



AckVBI_R
	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rts

AckCOP_R
	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rts

AckLev4	move.w	#$400,$dff09c
	move.w	#$400,$dff09c
	rts

ChangeDisk
	move.l	a0,-(a7)
	lea	DiskNum(pc),a0
	move.b	#2,(a0)
	move.l	(a7)+,a0
	rts



Protection	eor.b	#$4E,$458.w	; this code is forgot in cracked version :)

		lea	Track(pc),a0
		moveq	#8-1,d0
.copy		move.l	(a0)+,(a2)+
		dbf	d0,.copy

;		move.l	#$77000000,d0
		moveq	#$77,d0
		ror.l	#8,d0
		move.l	#$4449534B,d1
;		move.l	#$32000000,d2
		moveq	#$32,d2
		ror.l	#8,d2
;		move.l	#$10000000,d3
		moveq	#$10,d3
		ror.l	#8,d3
		moveq	#2,d4
		moveq	#-1,d6
;		move.l	#$FFFF,d5
		moveq	#0,d5
		move.w	d6,d5
		move.l	#$55555555,d7

; read track 0_0 from disk 2 with SYNC $8924 to $200 ptr
; and calculated values are left in d0-d7 !

		rts
Track
		dc.l	$8924912A,$AAAA552A,$AAAAAAA4,$A9254449
		dc.l	$5149112A,$AAAA92AA,$AAAAAAAA,$AAAAAAAA


Loader	bsr.b	.load
	movem.l	d0-a6,-(a7)
	bsr	Decrypt_AB		; decrypt file if necessary
	movem.l	(a7)+,d0-a6
	moveq	#0,d0			; no errors
	rts


.load	movem.l	d0-a6,-(a7)
	mulu.w	#512,d0
	mulu.w	#512,d1
	move.b	DiskNum(pc),d2
	move.l	resload(pc),a1
	jsr	resload_DiskLoad(a1)
	movem.l	(a7)+,d0-a6
	rts

DiskNum	dc.b	1
	dc.b	0


WaitRaster
.wait	btst	#0,$dff005
	beq.b	.wait
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts



***********************************
*** Level 2 IRQ			***
***********************************

SetLev2IRQ
	pea	.int(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode

	move.w	#1<<3,$dff09c			; clear ports interrupt
	move.w	#1<<15|1<<14|1<<3,$dff09a	; and enable it
	rts

.int	movem.l	d0-d1/a0-a2,-(a7)
	lea	$dff000,a0
	lea	$bfe001,a1


	btst	#3,$1e+1(a0)			; PORTS irq?
	beq.b	.end

	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

	moveq	#0,d0
	move.b	$c00(a1),d0
	not.b	d0
	ror.b	d0
	
	or.b	#1<<6,$e00(a1)			; set output mode


	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	

.nokeys	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	beq.b	.wait
	dbf	d1,.loop


	and.b	#~(1<<6),$e00(a1)	; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte




; generic decrypter for all encrypted Alien Breed files
; stingray, 12.07.2018 (13.07.: CLEANCODE added, file 2 decryption fixed)
; code works with full caches
; done for my version of the Alien Breed WHDLoad patch

; if CLEANCODE is set to 1, all encrypted code will be
; cleared with NOP, this way only the real code is left for easy
; disassembling

CLEANCODE	= 1			; 1: clear encryption code with NOPs


; d0.w: start (sector)
; d1.w: length (sectors)
; a0.l: start of encrypted data

Decrypt_AB
	move.l	a0,a5
	mulu.w	#512,d1
	lea	(a0,d1.l),a6		; a6: end of encrypted file
	
	lea	.FTAB(pc),a0
	
.search	movem.w	(a0)+,d2/d3		; start sector, offset to routine
	cmp.w	d0,d2
	beq.b	.found
	tst.w	(a0)
	bne.b	.search
	rts

.found	jmp	.FTAB(pc,d3.w)		; decrypt file


.FTAB	dc.w	2,.file1-.FTAB
	dc.w	$64,.file2-.FTAB
	dc.w	$1da,.file3-.FTAB
	dc.w	$1c5,.file4-.FTAB
	dc.w	$16,.file5-.FTAB	; no extra memory detected
	dc.w	0			; end of tab


.file1	move.l	a6,a0
	move.w	#$2800/2-1,d0
	moveq	#-2,d1
.loop0	eor.w	d1,-(a0)
	rol.w	#1,d1
	dbf	d0,.loop0

	lea	$826(a5),a4
	lea	$f9c(a5),a6
	bsr.b	.decrypt

	lea	$13e0(a5),a4
	lea	$2800(a5),a6
	bra.b	.decrypt


; at offset $6a98 is unused/forgotten code to encrypt the important
; routines
.file2	lea	$14(a5),a4
	lea	$197a(a5),a6
	bsr.b	.decrypt
	lea	$19c6(a5),a4
	lea	$2bd6(a5),a6
	bra.b	.decrypt
	
	

.file3	move.l	a5,a4
	lea	$17f8(a5),a6
	bsr.b	.decrypt

	lea	$5d7c(a5),a4
	lea	$30*512(a5),a6
	bra.b	.decrypt

.file4	lea	$788(a5),a4
	bra.b	.decrypt

.file5	move.l	a5,a4



; a4.l: start of decryption
; a5.l: start of file
; a6.l: end of decryption

.decrypt
.find	cmp.w	#$41fa,(a4)		; lea xxx(pc),a0
	beq.b	.start_found

	addq.w	#2,a4

	cmp.l	a6,a4
	bcs.b	.find
	rts

.start_found
	move.w	4+2(a4),d0		; loop counter
	lea	.TAB(pc),a3

.find_opcode
	move.w	(a3)+,d3		; offset to check
	movem.w	(a3)+,d1/d2		; opcode/routine offset
	cmp.w	(a4,d3.w),d1
	beq.b	.instruction_found
	tst.w	(a3)
	bne.b	.find_opcode
	rts

.instruction_found
	move.w	2(a4),a0		; offset to destination
	lea	2(a4,a0.w),a0

	lea	.TAB(pc,d2.w),a1

	jsr	(a1)			; call init code
	addq.w	#2,a1

.decrypt_loop
	jsr	(a1)			; call decryption code
	dbf	d0,.decrypt_loop

; search for dbf opcode to find end of decryption loop
.find_end
	cmp.w	#$51c8,(a4)
	beq.b	.end_found
	IFNE	CLEANCODE
	move.w	#$4e71,(a4)+		; encryption code -> nop
	ELSE				; so real code is left only
	addq.w	#2,a4			
	ENDC
	cmp.l	a6,a4
	bcs.b	.find_end
	rts	



.end_found
	IFNE	CLEANCODE
	move.l	#$4e714e71,(a4)+	; disable dbf d0,xxx
	ELSE
	addq.w	#4,a4			; skip dbf d0,xxx
	ENDC
	;move.l	a4,a2			; a2: current decryption loop (debug)

	bra.b	.decrypt


; offset to check, opcode, routine offset
.TAB	dc.w	8,$4460,.NegAx-.TAB	; neg.w -(ax) 
	dc.w	8,$0a60,.EorI-.TAB	; eor.w #xxx,-(ax)
	dc.w	8,$0460,.SubI-.TAB	; sub.w #xxx,-(ax)
	dc.w	12,$d360,.AddDx-.TAB	; add.w d1,-(ax)
	dc.w	8,$4660,.NotAx-.TAB	; not.w -(ax)
	dc.w	12,$b360,.EorDx-.TAB	; eor.w d1,-(ax)
	dc.w	12,$9360,.SubDx-.TAB	; sub.w d1,-(ax)
	dc.w	8,$e6e0,.RorAx-.TAB	; ror.w -(ax) 
	dc.w	8,$e7e0,.RolAx-.TAB	; rol.w -(ax) 
	dc.w	8,$0660,.AddI-.TAB	; add.w #xxx,-(ax)
	dc.w	8,$4258,.Clr-.TAB	; clr.w (ax)+
	dc.w	4,$4298,.Clr-.TAB	; clr.l (ax)+
	dc.w	34,$3e20,.Large-.TAB	; move.w -(a0),d7 -> large decryption loop
	dc.w	0			; end of tab


.NegAx	bra.b	.NegAx_Init
	neg.w	-(a0)
	rts

.NegAx_Init
	rts

.NotAx	bra.b	.NotAx_Init
	not.w	-(a0)
	rts

.NotAx_Init
	rts

.RorAx	bra.b	.RorAx_Init
	ror.w	-(a0)
	rts

.RorAx_Init
	rts

.RolAx	bra.b	.RolAx_Init
	rol.w	-(a0)
	rts

.RolAx_Init
	rts

.EorI	bra.b	.EorI_Init
	move.w	8+2(a4),d1
	eor.w	d1,-(a0)
	rts

.EorI_Init
	rts


.SubI	bra.b	.SubI_Init
	move.w	8+2(a4),d1
	sub.w	d1,-(a0)
	rts

.SubI_Init
	rts

.AddI	bra.b	.AddI_Init
	add.w	d1,-(a0)
	rts

.AddI_Init
	move.w	8+2(a4),d1
	rts


.AddDx	bra.b	.AddDx_Init

	add.w	d1,-(a0)
	rol.w	d2,d1
	rts

.AddDx_Init
	move.w	8+2(a4),d1
	moveq	#1,d2
	cmp.w	#$e359,14(a4)		; rol.w #1,d1
	beq.b	.rol
	neg.w	d2			; -> ror.w #1,d1
.rol	rts	

.EorDx	bra.b	.EorDx_Init

	eor.w	d1,-(a0)
	rol.w	d2,d1
	rts

.EorDx_Init
	bra.b	.AddDx_Init
	

.SubDx	bra.b	.SubDx_Init

	sub.w	d1,-(a0)
	rol.w	d2,d1
	rts

.SubDx_Init
	bra.b	.AddDx_Init

.Clr	bra.b	.ClrInit

	rts

.ClrInit
	moveq	#0,d0			; clear loop counter -> do nothing

; special case: two clr.l (a0)+ instructions without loop
; clr.l (a0)+
; clr.l (a0)+
	cmp.w	#$4298,6(a4)		; clr.l (a0)+
	bne.b	.nospecial
	move.w	#$51c8,4(a4)		; add fake dbf so our "search for end"
					; routine will work
.nospecial
	rts


.Large	bra.b	.LargeInit


	move.w	-(a0),d7
	eor.w	d1,d7
	ror.w	d2,d7
	rol.w	d6,d7
	sub.w	d5,d7
	add.w	d6,d7
	swap	d1
	ror.w	#4,d7
	swap	d2
	sub.w	d2,d7
	rol.w	#8,d7
	eor.w	#$C0DE,d7
	add.w	d2,d7
	eor.l	d1,d2
	sub.w	d2,d7
	move.w	d7,(a0)
	sub.l	d7,d6
	eor.l	d7,d5
	add.l	d7,d5
	rts
	

.LargeInit
	move.l	8+2(a4),d1		; key 1
	move.l	14+2(a4),d2		; key 2
	moveq	#0,d7
	move.l	#'L.K.',d6
	move.l	#'S.B.',d5
	rts

