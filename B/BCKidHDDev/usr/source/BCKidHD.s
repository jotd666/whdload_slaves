;*---------------------------------------------------------------------------
;  :Program.	Bckid.asm
;  :Contents.	Slave for "B.C.Kid" from Factor 5
;  :Author.	Mr.Larmer of Wanted Team, Wepl, JOTD
;  :History.	09.05.98 v1.0 by Mr.Larmer
;		22.02.08 reworked by Wepl
;			 some snoop bugs removed
;			 adapted for new image format
;			 whdload v10 infos added
;			 decruncher relocated and smc fixed (same decruncher as turrican 2)
;		25.02.08 stack moved to fast memory
;			 int acknowledge fixed
;		02.01.10 terminating factor5 logo
;		03.01.12 SKIPLOGOS added
;		09.03.14 logoskip via custom1
;			 smc and intack in the tfmx player fixed
;			 debug mode to save files added
;			 requires v17 now
;		11.03.14 decruncher optimized
;			 fileripper added
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

; 410 pause loop, rawkey 2AE4
; 684 number max of hearts
; 698 number of coins
; 69A lives
; 636 game state PLAY/SEQU=>end level/DEAD/HALT
; 644.W current level
; skip level: add 1 + write DONE in 636
; access fault $6D34 read from xxxx
; 178D8: code for initial number of lives

; TODO: test quit to wb
; access fault on 29222 when esc+"continue"

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"BCKid.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

;DEBUG
;FILERIP
;BW

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
	IFND DEBUG
		dc.w	17			;ws_Version
	ELSE
		dc.w	18			;ws_Version
	ENDC
		dc.w	WHDLF_NoError|WHDLF_ClearMem;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	Start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug = F9
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	$1000			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
DECL_VERSION:MACRO
	dc.b	"1.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_name		dc.b	"B.C.Kid",0
_copy		dc.b	"1992 Hudson-Soft/Factor 5",0
_info		dc.b	"Adapted by Mr.Larmer & Wepl & CFou! & JOTD",10,10
		dc.b	"Press F1 to skip levels",10,10
		dc.b	"Press F2 to skip sub-levels",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
_highs		dc.b	"BCKid.highs",0
_boot		dc.b	"boot",0
_data		dc.b	"data",0
_config
		dc.b	"C1:B:Trainer - Infinite lives;"
		dc.b	"C2:B:Force 2 button joystick;"
		dc.b    "C3:L:Start with lives:2,3,4,5,6,7;"			
		dc.b    "C4:L:Start level:Practice,Inside Dino,Caveland,Desert,Cloud Nine,"
		dc.b	"Caveland 2,Ice Tea,Boss 3,Gobi,Boss 4,Siege,Statues,Gallery,Boss Rush,Boss 5,Moonwalk;"			
		dc.b	"C5:B:Skip Hudson/Factor5 Logos;"
			dc.b	0
	EVEN
IGNORE_JOY_DIRECTIONS
	include	ReadJoyPad.s
;======================================================================
Start	;	A0 = resident loader
;======================================================================

	IFD FILERIP
		move.l	a0,a5
		lea	$400,a4
		move.l	a4,a0
		moveq	#0,d0
		move.l	#$320,d1
		moveq	#1,d2
		jsr	(resload_DiskLoad,a5)
		move.w	#$30,d7
.lp		move.w	(4,a4),d0
		subq.l	#2,D0
		mulu	#$1964,D0
		moveq	#0,d1
		move.w	(6,a4),d1
		add.l	d1,d0
		move.l	(8,a4),d1
		move.l	#$1000,a3
		move.l	a3,a0
		jsr	(resload_DiskLoad,a5)
		move.l	a3,a0
		move.l	(a0),d3			;unpacked length
		move.l	#$20000,a1
		move.l	a1,a6
		movem.l	d0-a6,-(a7)
		bsr	_decrunch
		movem.l	(a7)+,d0-a6
		move.l	d3,d0
		move.l	a4,a0
		move.l	a6,a1
		jsr	(resload_SaveFile,a5)
		add.w	#16,a4
		dbf	d7,.lp
		pea	TDREASON_OK
		jmp	(resload_Abort,a5)
	ENDC
	
		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use
		move.l	a0,a2			;A2 = resload

		bsr	_detect_controller_types
		
		lea	_tags(pc),a0
		jsr	(resload_Control,a2)
		
		lea	_boot(pc),a0
		lea	$50000,a1
		move.l	a1,a3			;A3 = 50000
		jsr	(resload_LoadFileDecrunch,a2)
	IFD BW
		move.l	#$4E714EB9,D0
		lea	WaitBlit(pc),A0
		move.l	A0,D1
		lea	Table(pc),A0
		move.l	#((EndTable-Table)/4)-1,D2
.loop		move.l	(A0)+,A1
		move.l	D0,(A1)+
		move.l	D1,(A1)
		dbf	D2,.loop
	ENDC

		lea	_pl_boot(pc),a0
		move.l	a3,a1
		jsr	(resload_Patch,a2)


		jmp	($de,a3)

_pl_boot	PL_START
		PL_S	$f2,6			;set sp
		PL_IFC5
		PL_S	$192,6			;skip Factor5, requires removal of jsr $30008
		PL_ENDIF
		PL_P	$1ae,_code
	IFD DEBUG
		PL_PS	$206,_log2
	ENDC
		PL_P	$342,Load
		PL_P	$54c,_loadhighs
		PL_P	$73c,_decrunch
		PL_IFC5
		PL_R	$bb4			;skip Hudson
		PL_ENDIF
		PL_ORW	$f2c,$200		;bplcon0.color
		PL_END

	IFD BW
WaitBlit	BLITWAIT
		rts

Table		dc.l	$500E4,$50BF8,$50E08,$50F10,$50FAA,$51036
EndTable
Table2		dc.l	$26A,$15B4,$1624,$1864,$1B30,$1BBE,$1BD4,$1E2E,$1E46
		dc.l	$1E92,$1ED0,$1EF4,$1F14,$4B66,$4B9A,$4C64,$4C98,$4CD4
		dc.l	$4D0E,$4FC8,$4FF0,$50D8,$5170,$5226,$52C6,$5382,$541C
		dc.l	$54CC,$553E,$557A,$30258,$303BE,$305C8,$3063E,$30658
		dc.l	$30682
EndTable2
	ENDC

;--------------------------------
; player routines are called via $3dd4a or ($676)
; on subsequent levels the player seems to be moved as it is only
; contained in SND0

_loadsound	movem.l	d0-d2/a0-a4,-(a7)
		move.l	(8*4,a7),a1
		move.l	(a1),a1
		jsr	(a1)			;loadbyname1/2
		cmp.b	#'0',(3,a7)		;SND0 only
		bne	.skip
		lea	_pl_snd0(pc),a0
		move.l	(4,a7),a1
		move.l	(_resload,pc),a2
		jsr	(resload_Patch,a2)
.skip		movem.l	(a7)+,d0-d2/a0-a4
		addq.l	#8,(a7)
		rts

_pl_snd0	PL_START
		PL_P	$14354,.int1
		PL_P	$15978,.int2
		PL_PS	$159a0,.smc
		PL_END

.int1		movem.l	(a7)+,d0/a5
		tst.w	_custom+intreqr
		rte

.int2		move.w	#$400,_custom+intreq
		tst.w	_custom+intreqr
		rte

.smc		swap	d5
		movem.l	a5-a6,-(a7)
		move.l	(8,a7),a5

		addq.l	#2,a5
		move.b	(a0,d0.w),d4
		move.w	(a5),a6
		add.l	a5,a6
		move.b	(a6,d4.w),d4

		add.w	#12,a5
		move.b	(a1,d1.w),d5
		move.w	(a5),a6
		add.l	a5,a6
		move.b	(a6,d5.w),d5
		add.w	d5,d4

		add.w	#14,a5
		move.b	(a2,d2.w),d5
		move.w	(a5),a6
		add.l	a5,a6
		move.b	(a6,d5.w),d5
		add.w	d5,d4

		add.w	#14,a5
		move.b	(a3,d3.w),d5
		move.w	(a5),a6
		add.l	a5,a6
		move.b	(a6,d5.w),d5

		movem.l	(a7)+,a5-a6
		add.l	#$9d6-$9a0-6,(a7)
		rts

;--------------------------------
; interrupts from factor5 (DEMO) are still active here!
; 30008 from CODE will stop it

_code
	IFD BW
		move.l	#$4E714EB9,D0
		lea	WaitBlit(pc),A0
		move.l	A0,D1
		lea	Table2(pc),A0
		moveq	#((EndTable2-Table2)/4)-1,D2
.loop		move.l	(A0)+,A1
		move.l	D0,(A1)+
		move.l	D1,(A1)
		dbf	D2,.loop
	ENDC

		move.w	_nb_lives+2(pc),d0
		add.w	#2,d0
		move.b	D0,$178DA   ; start lives
		lea	_pl_code(pc),a0
		sub.l	a1,a1
		move.l	(_resload,pc),a2
		jsr	(resload_Patch,a2)


		moveq	#50,d7
		move.l	_mon(pc),d0
		cmp.l	#PAL_MONITOR_ID,d0
		beq	.monok
		moveq	#60,d7
.monok
		move.l	_skip_factor5_logos(pc),d0
		bne	.1
		jsr	$30008			;terminate Factor5
.1
	; make sure that VBL won't become active
		lea	_illegal(pc),a0
		move.l	a0,$6c

		move.l	#$ff0,a7
		add.l	_expmem(pc),a7
		jmp	$204.W

_illegal	illegal

_pl_code	PL_START
		PL_I	$200
		PL_S	$208,6			;skip copy memory map
		PL_S	$226,6			;jsr $30008, disable Factor5
		;;PL_PS	$496,_waitmusic
		PL_PS	$544,_loadsound
		PL_ORW	$1640,$200		; bplcon0.color
		PL_S	$1678,4			;skip copjmp1
		PL_W	$16dc,$1fe		; fix for snoop
		PL_W	$16e2,$1fe
		PL_W	$170e,$1fe
		PL_W	$1716,$1fe
		PL_W	$1736,$1fe
		PL_W	$1776,$1fe
		PL_W	$17e2,7			; wrong amount of writes to custom.color
		PL_S	$2A1C,6			; skip add to VPOSW
		PL_P	$2a36,.int78ack
		PL_P	$2ada,.int68ack
		PL_PSS	$2a96,.ack_kb,2
		PL_IFC1
		PL_NOP	$1564,2		; don't substract lives
		PL_B	$1566,$60	; BRA instead of BPL
		PL_R	$17300		; don't save highscores, skip write
		PL_ELSE
		PL_IFC3
		PL_R	$17300		; don't save highscores, skip write
		PL_ELSE
		; save highscores only if no trainer active
		PL_P	$17300,_savehighs
		PL_ENDIF
		PL_ENDIF
	IFD DEBUG
		PL_PS	$17f56,_log1
	ENDC
	;	PL_BKPT	$17820
		PL_PS	$17b52,_loadsound
		PL_P	$182d0,Load
		PL_P	$186d2,_decrunch
		;
		PL_PSS	$178B4,.set_start_level,4
		; access fault avoidance (odd read on 68000)
		PL_PS	$6D32,.fix_access_fault
		
		PL_IFC2
		PL_NOP	$172c4,6
		PL_NOP	$172ce,4	; don't set button option from highs
		PL_W	$4FAC,1		; set 2 button option
		PL_B	$17e11,$32	; option for menu coherence
		PL_ENDIF
		
		; jmp instead of jsr, handle everything in slave
		PL_P	$624,.read_second_button

		PL_PSS	$00410,.pause,2
		PL_PSS	$00420,.unpause,4
		; skip pause with right mouse button (doesn't work!)
		PL_S	$00430,$10
		; this was completely missed in slaves pre v1.5
		; the code was loaded with caches not flushed
		; and there's an access fault there too... (continue)
		PL_PS	$230,.load_extra
		
		PL_END

.load_extra
	movem.l	d0-d1/a0-a2,-(a7)
	sub.l	a1,a1
	lea	pl_extra(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	$2978.W
	
.read_second_button
	movem.l	D0/a0,-(a7)
	moveq	#1,d0
	bsr	_read_joystick
	lea	joy1(pc),a0
	move.l	d0,(a0)		; for later
	btst	#JPB_BTN_BLU,d0
	beq.b	.noblue
	MOVE.W	#$0001,196(A1)	; jump flag
.noblue
	btst	#JPB_BTN_FORWARD,D0
	beq.b	.nofwd
	btst	#JPB_BTN_REVERSE,D0
	beq.b	.nobwd
	move.b	#$45,$2AE4
	btst	#JPB_BTN_PLAY,d0
	bne		quit
.nobwd
	btst	#JPB_BTN_GRN,D0
	beq.b	.nogrn
.waitgrel
	moveq	#1,d0
	bsr	_read_joystick
	btst	#JPB_BTN_GRN,D0
	bne.b	.waitgrel
	bsr	.levelskip
.nogrn
.nofwd	
	movem.l	(a7)+,D0/a0
	rts

.pause:
	movem.l	D0,-(a7)
	move.l	joy1(pc),d0
	btst	#JPB_BTN_PLAY,D0
	bne.b	.pressed
	movem.l	(A7)+,D0

	CMPI.B	#$19,$2ae4
	rts
	; wait for button released
.pressed
	moveq	#1,d0
	bsr	_read_joystick
	btst	#JPB_BTN_PLAY,D0
	bne.b	.pressed
	movem.l	(A7)+,D0
	rts
	
.unpause:
	
	; wait for pause pressed
	movem.l	D0,-(a7)
.notpressed
	moveq	#1,d0
	CMPI.B	#$19,$2ae4.W
	beq.b	.unpaused
	bsr	_read_joystick
	btst	#JPB_BTN_PLAY,D0
	beq.b	.notpressed
	; wait for pause not pressed
.pressed2
	moveq	#1,d0
	bsr	_read_joystick
	btst	#JPB_BTN_PLAY,D0
	bne.b	.pressed2
.unpaused
	movem.l	(A7)+,D0
	rts
	
.set_start_level:
	move.w	_start_level+2(pc),$644
	MOVE.W #$0003,$0000067c	;stolen, what is it? never mind
	rts
		
.fix_access_fault:
	movem.l	d0,-(a7)
	move.l	a0,d0
	btst	#0,d0
	movem.l	(a7)+,d0
	bne.b	.avoid
	
	cmp.l	#$80000,A0
	bcc.b	.avoid
	; at least it's in chipmem
	MOVE.W (2,A0),D4
	SUB.W #1,D4
	rts
.avoid
	; like we read 0, and then substract (simulate wrong read / odd read on 68000)
	move.w	#-1,d4
	rts
	
.int78ack	tst.b	_ciab+ciaicr
		move.w	d7,_custom+intreq
		tst.w	_custom+intreqr
		move.l	(a7)+,d7
		rte

.int68ack	move.w	#8,_custom+intreq
		tst.w	_custom+intreqr
		rte

.ack_kb:
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	movem.l	(A7)+,D0

	cmp.l	#'PLAY',$636.W
	bne.b	.nolskip
	cmp.w	#$F,$644
	bcc		.nolskip	; skipping last boss: can't do
	tst.w	$644
	bmi.b	.nolskip	; bonus level
	
	cmp.b	#$50,d1		; F1: levelskip
	bne.b	.nof1
.nextlevel
	bsr	.levelskip
	bra.b	.nolskip
.nof1
	cmp.b	#$51,d1		; F2: sub-level skip
	bne.b	.nolskip
	add.w	#1,$646
	cmp.w	#3,$646
	bcc.b	.nextlevel
	
	move.l	#'DONE',$636.W
	
.nolskip
	; D1 holds rawkey
	cmp.b	_keyexit(pc),d1
	beq		quit		; quitkey on 68000 works now

	RTS
.levelskip
	move.l	a0,-(a7)
	; level skip: don't save highscores
	lea	dont_save_highs(pc),a0
	st.b	(a0)
	move.l	(a7)+,a0
	clr.w	$646
	add.w	#1,$644
	move.l	#'DONE',$636.W
	rts
	
quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
pl_extra
	PL_START
	; this doesn't work, and the problem occurs probably only
	; in winuae if "more compatible" isn't checked
	; it crashes when continuing the game
	;PL_PS	$29222,avoid_af_continue
	PL_END

avoid_af_continue
	cmp.l	#$80000,a0
	bcs.b	.ok
	; avoid AF, put zero
	move.w	#$F00,$dff180
	move.l	#-1,18(a6)
	rts
	
.ok
	MOVE.L	0(A0,D0.W),18(A6)	;29222: 2d7000000012
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

;--------------------------------
	IFD DEBUG
_log2		move.l	(12,a1),d2
		move.l	(8,a1),d0
_log1		movem.l	d0/a0-a1,-(a7)
		move.l	(a1),$e0		; for saving after decrunch
		clr.b	$e4
		lea	.msg,a0
		moveq	#0,d0
		move.b	(15,a1),d0
		move.w	d0,-(a7)
		move.b	(14,a1),d0
		move.w	d0,-(a7)
		move.l	(8,a1),-(a7)
		move.l	(8,a1),-(a7)
		move.l	(4,a1),-(a7)
		move.l	a1,-(a7)
		move.l	d1,-(a7)
		move.l	(_resload,pc),a1
		jsr	(resload_Log,a1)
		add.w	#24,a7
		movem.l	(a7)+,d0/a0-a1
		addq.l	#2,(a7)
		rts
.msg		dc.b	"adr=%lx name=%s strk=%4x trko=%4x length=%lx=%ld packed=%d cached=%d",0
	EVEN
	ENDC
;--------------------------------
; after end game it hangs

_waitmusic	tst.w	(a0)
		beq	.leave
		btst	#6,$bfe001
		beq	.leave
		btst	#7,$bfe001
		bne	_waitmusic
.leave		jmp	($28,a4)

;--------------------------------

Load		movem.l	d0-d2/a0-a2,-(a7)

		ext.l	D1
		exg.l	D0,D1

		subq.l	#2,D0
		mulu	#$1964,D0
		add.l	D2,D0

		moveq	#1,D2

		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)

		movem.l	(a7)+,d0-d2/a0-a2
		rts

;--------------------------------

_loadhighs	movem.l	d0-d1/a0-a2,-(a7)

		lea	$61000,a0
		moveq	#388/4-1,d0
.clr		clr.l	(a0)+
		dbf	d0,.clr

		lea	_highs(pc),a0
		move.l	(_resload,pc),a2
		jsr	(resload_GetFileSize,a2)
		tst.l	d0
		beq	.end

		lea	_highs(pc),a0
		lea	$61000,a1		;address
		jsr	(resload_LoadFileDecrunch,a2)
.end
		; at offset $89, $8B the joystick settings are saved
		; besides the highscores
;		lea	$61000,a1		;address
;		move.l	_2button(pc),d0
;		beq.b	.no2b
;		move.l	#$FF321C45,($88,A1)
;.no2b
		movem.l	(a7)+,d0-d1/a0-a2
		rts

;--------------------------------

_savehighs	movem.l	d0-d1/a0-a2,-(a7)
		move.l	dont_save_highs(pc),d0
		bne.b	.skip
		move.l	#388,d0			;len
		lea	_highs(pc),a0		;filename
		lea	$5CE6E,a1		;address
		move.l	_resload(pc),a2
		jsr	(resload_SaveFile,a2)
.skip
		movem.l	(a7)+,d0-d1/a0-a2
		rts

;======================================================================
; a0=source a1=dest a2=temp($400)

_decrunch
	IFD DEBUG_
		move.l	a1,-(a7)	;destination
		move.l	(a0),-(a7)	;length
		bsr	.dec
		move.l	(a7)+,d0
		lea	$e0,a0
		move.l	(a7)+,a1
		move.l	(_resload,pc),a2
		jsr	(resload_SaveFile,a2)
		rts
.dec
	ENDC

	move.l	_expmem(pc),a2

	MOVE.L	(A0)+,-(SP)	;unpacked length
	MOVE.L	(A0)+,-(SP)

	MOVE.W	#$400,D0
	MOVEA.L	A1,A3
	ADDA.L	(4,SP),A3
lbC00000E	MOVE.B	(A3)+,(A2)+
	SUBQ.W	#1,D0
	BNE.B	lbC00000E

	MOVEM.L	A2/A3,-(SP)
	MOVE.L	A1,-(SP)
	MOVE.L	A2,-(SP)
	BSR.B	lbC000060
	MOVEA.L	(SP)+,A3
	MOVEA.L	A1,A0
	MOVEA.L	(8,SP),A2
	MOVEA.L	A2,A1
	SUBA.L	(12,SP),A1
	BSR.W	lbC00017C
	MOVEA.L	A2,A0
	MOVEA.L	A5,A3
	MOVEA.L	(SP)+,A1
	MOVEA.L	A1,A2
	ADDA.L	(12,SP),A2
	MOVEM.L	A1/A2,(8,SP)
	BSR.W	lbC0003EA
	MOVEM.L	(SP)+,A2/A3

	MOVE.W	#$400,D0
lbC00004E	MOVE.B	-(A2),-(A3)
	SUBQ.W	#1,D0
	BNE.B	lbC00004E

	MOVEM.L	(SP)+,A0/A1
	LEA	($DFF000).L,A6
	RTS

lbC000060
	LEA	(_fuck1,PC),A3
	MOVE.W	#$FF,(A3)+
	MOVEQ	#-2,D0
	MOVE.W	D0,(A3)+
	MOVE.W	D0,(A3)+
	MOVE.W	D0,(A3)+
	MOVE.L	(A0)+,D3
	SUBQ.L	#1,D3
	MOVE.L	D3,D5
	SWAP	D5
	MOVE.W	(A0)+,D4
	MOVEQ	#0,D6
	MOVE.B	(A0)+,D6
	MOVEM.L	D3-D6,-(SP)
	MOVEQ	#2,D5
	MOVE.L	#$100,D6
	MOVEQ	#0,D7
	MOVEQ	#0,D0
	MOVE.B	(A0)+,D0
	MOVEA.L	A2,A6
	MOVE.L	D0,D1
	ADD.L	D1,D1
	LEA	(_fuck1,PC),A5
lbC0000A6	MOVEQ	#0,D2
	MOVEQ	#0,D4
	MOVE.B	(A0)+,D2
	MOVE.B	(A0)+,D4
	ADD.W	D4,(A5)
	ADD.W	D4,(A5)
	ADD.W	D2,D4
	MOVE.W	D2,(A6)
	ADDA.L	D1,A6
	MOVE.W	D4,(A6)
	ADDA.L	D1,A6
	MOVE.W	D6,(A6)
	ADD.W	D2,D2
	SUB.W	D2,(A6)
	LSR.W	#1,D2
	ADDA.L	D1,A6
	MOVE.W	D7,(A6)
	SUB.W	D4,(A6)
	SUBA.L	D1,A6
	SUBA.L	D1,A6
	SUBA.L	D1,A6
	ADDQ.L	#2,A6
	MOVE.L	D5,D3
	SUB.L	D4,D3
	ADD.L	D3,D7
	SUB.L	D2,D4
	ADD.L	D4,D6
	ADD.L	D4,D6
	MOVE.L	D2,D5
	ADD.L	D5,D5
	SUBQ.W	#1,D0
	BNE.B	lbC0000A6
	addq.l	#2,a5
	ADD.W	D1,(A5)+
	ADD.W	D1,(A5)
	ADD.W	D1,(A5)
	ADD.W	D1,(A5)+
	ADD.W	D1,(A5)
	ADD.W	D1,(A5)
	LSL.L	#2,D1
	LEA	(A2,D1.L),A6
	MOVEA.L	A6,A5
	MOVE.W	(_fuck1,pc),D0
lbC00010A
	MOVE.B	(A0)+,(A5)+
	DBRA	D0,lbC00010A
	MOVEM.L	(SP)+,D3-D6
	lea	(-2,a2,d6.l),a5
	ADDA.L	D6,A5
	MOVEQ	#0,D1
lbC00011E
	CMP.W	D6,D1
	BCS.B	lbC00012E
	SUB.W	D6,D1
	ROL.W	D6,D0
	MOVE.W	D0,D2
	AND.W	D4,D2
	MOVEA.L	A5,A3
	BRA.B	lbC00013E

lbC00012E
	MOVEQ	#0,D2
	MOVEA.L	A2,A3
	DBRA	D1,lbC00013A
	MOVE.W	(A0)+,D0
	MOVEQ	#15,D1
lbC00013A
	ADD.W	D0,D0
	ADDX.W	D2,D2
lbC00013E
	CMP.W	(A3)+,D2
	DBCC	D1,lbC00013A
	BCC.B	lbC00014C
	MOVE.W	(A0)+,D0
	MOVEQ	#15,D1
	BRA.B	lbC00013A

lbC00014C
	move.w	(_fuck2,pc),d7
	cmp.w	(a3,d7.w),d2
	BCS.B	lbC000164
	move.w	(_fuck3,pc),d7
	add.w	(a3,d7.w),d2
	MOVE.B	(A6,D2.W),(A1)+
	DBRA	D3,lbC00011E
	DBRA	D5,lbC00011E
	RTS

lbC000164
	ADD.W	D2,D2
	move.w	(_fuck4,pc),d7
	add.w	(a3,d7.w),d2
	MOVE.B	(A6,D2.W),(A1)+
	MOVE.B	(1,A6,D2.W),(A1)+
	SUBQ.W	#2,D3
	BCC.B	lbC00011E
	DBRA	D5,lbC00011E
	RTS

lbC00017C	MOVEA.L	A3,A5
	MOVEA.L	A5,A6
	MOVE.W	#$FF,D7
lbC000184	CLR.W	(A6)+
	DBRA	D7,lbC000184
	LEA	(lbL0003D4,PC),A6
	LEA	(-$6C).W,A3
	MOVEQ	#9,D7
lbC000194	MOVEQ	#0,D6
	MOVE.B	-(A0),D6
	ADD.W	D6,D6
	MOVE.W	(A6)+,D5
	ADD.W	A3,D5
	MOVE.W	D5,(A5,D6.W)
	DBRA	D7,lbC000194
	LEA	($10E).W,A3
	MOVEQ	#15,D7
lbC0001AC	MOVEQ	#0,D6
	MOVE.B	-(A0),D6
	ADD.W	D6,D6
	MOVE.W	A3,(A5,D6.W)
	ADDQ.W	#6,A3
	DBRA	D7,lbC0001AC
	MOVEQ	#0,D6
	MOVE.B	-(A0),D6
	ADD.W	D6,D6
	LEA	($196).W,A3
	MOVE.W	A3,(A5,D6.W)
	LEA	(lbC0001FE,PC),A4
	LEA	(lbC0001D2,PC),A3
lbC0001D2	CMPA.L	A1,A2
	BLS.W	lbC0003E8
	MOVE.B	-(A0),D0
	MOVEQ	#0,D7
	MOVE.B	D0,D7
	ADD.W	D7,D7
	MOVE.W	(A5,D7.W),D7
	JMP	(lbC0001E8,PC,D7.W)

lbC0001E8	MOVE.B	D0,-(A2)
	JMP	(A3)

	MOVEQ	#0,D1
	MOVE.B	-(A0),D1
	BEQ.B	lbC0001E8
	LEA	(A2,D1.W),A6
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
lbC0001FE	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	JMP	(A3)

	MOVE.B	-(A0),D1
	MOVE.B	D1,D2
	AND.W	#$FC,D1
	BEQ.B	lbC0001E8
	LSR.W	#2,D1
	AND.W	#3,D2
	LEA	(A2,D1.W),A6
	ADD.W	D2,D2
	NEG.W	D2
	JMP	(A4,D2.W)

	MOVEQ	#0,D2
	MOVE.B	-(A0),D2
	BEQ.B	lbC0001E8
	MOVE.W	D2,D1
	LSR.W	#2,D2
	LSL.W	#8,D1
	MOVE.B	-(A0),D1
	AND.W	#$3FF,D1
	LEA	(1,A2,D1.W),A6
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
lbC00023C	MOVE.B	-(A6),-(A2)
	DBRA	D2,lbC00023C
	JMP	(A3)

	MOVEQ	#0,D1
	MOVE.B	-(A0),D1
	BEQ.B	lbC0001E8
	LSL.W	#8,D1
	MOVE.B	-(A0),D1
	CMP.W	#$C000,D1
	BCC.B	lbC000262
	LEA	(A2,D1.L),A6
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	JMP	(A3)

lbC000262	MOVE.W	#$401,D3
lbC000266	AND.W	#$3FFF,D1
	MOVE.B	D1,D2
	AND.W	#7,D2
	LSR.W	#3,D1
	ADD.W	D3,D1
	LEA	(A2,D1.W),A6
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
lbC00027E
	MOVE.B	-(A6),-(A2)
	DBRA	D2,lbC00027E
	JMP	(A3)

	MOVEQ	#0,D1
	MOVE.B	-(A0),D1
	BEQ.W	lbC0001E8
	LSL.W	#8,D1
	MOVE.B	-(A0),D1
	MOVE.W	#$2C01,D3
	CMP.W	#$C000,D1
	BCC.B	lbC000266
	MOVEQ	#0,D2
	MOVE.B	-(A0),D2
	SUBQ.W	#1,D2
	SUB.W	#$100,D1
	LEA	(A2,D1.L),A6
lbC0002AA	MOVE.B	-(A6),-(A2)
	DBRA	D2,lbC0002AA
	JMP	(A3)

	MOVE.W	#$C01,D3
	BRA.B	lbC0002CE

	MOVE.W	#$9401,D3
	BRA.B	lbC0002CE

	MOVE.W	#$7401,D3
	BRA.B	lbC0002CE

	MOVE.W	#$5401,D3
	BRA.B	lbC0002CE

	MOVE.W	#$3401,D3
lbC0002CE	MOVEQ	#0,D2
	MOVE.B	-(A0),D2
	BEQ.W	lbC0001E8
	MOVE.L	D2,D1
	LSR.W	#5,D2
	LSL.W	#8,D1
	MOVE.B	-(A0),D1
	AND.W	#$1FFF,D1
	ADD.W	D3,D1
	LEA	(A2,D1.L),A6
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
lbC0002EE	MOVE.B	-(A6),-(A2)
	DBRA	D2,lbC0002EE
	JMP	(A3)

	MOVE.W	#$3F,D3
	BRA.B	lbC00035A

	MOVE.W	#$7E,D3
	BRA.B	lbC00035A

	MOVE.W	#$BD,D3
	BRA.B	lbC00035A

	MOVE.W	#$FC,D3
	BRA.B	lbC00035A

	MOVE.W	#$13B,D3
	BRA.B	lbC00035A

	MOVE.W	#$17A,D3
	BRA.B	lbC00035A

	MOVE.W	#$1B9,D3
	BRA.B	lbC00035A

	MOVE.W	#$1F8,D3
	BRA.B	lbC00035A

	MOVE.W	#$237,D3
	BRA.B	lbC00035A

	MOVE.W	#$276,D3
	BRA.B	lbC00035A

	MOVE.W	#$2B5,D3
	BRA.B	lbC00035A

	MOVE.W	#$2F4,D3
	BRA.B	lbC00035A

	MOVE.W	#$333,D3
	BRA.B	lbC00035A

	MOVE.W	#$372,D3
	BRA.B	lbC00035A

	MOVE.W	#$3B1,D3
	BRA.B	lbC00035A

	MOVE.W	#$3F0,D3
	BRA.B	lbC00035A

	MOVE.W	#$42F,D3
lbC00035A	MOVE.B	-(A0),D1
	MOVE.B	D1,D2
	AND.W	#$FC,D1
	BEQ.W	lbC0001E8
	LSR.W	#2,D1
	AND.W	#3,D2
	ADD.W	D3,D1
	LEA	(A2,D1.W),A6
	MOVE.B	-(A6),-(A2)
	MOVE.B	-(A6),-(A2)
lbC000376	MOVE.B	-(A6),-(A2)
	DBRA	D2,lbC000376
	JMP	(A3)

	MOVE.B	-(A0),D1
	BEQ.W	lbC0001E8
	MOVE.B	D1,D2
	AND.W	#$3F,D1
	ROL.B	#2,D2
	AND.W	#3,D2
	ADD.W	D2,D2
	LEA	(lbL0003CC,PC),A6
	MOVE.W	(A6,D2.W),D3
	EXT.L	D3
	MOVE.B	-(A0),D4
	ROR.L	#8,D4
	MOVE.B	-(A0),D4
	ROR.L	#8,D4
	MOVE.B	-(A0),D4
	ROR.L	#8,D4
	MOVE.B	-(A0),D4
	ROR.L	#8,D4
lbC0003AC	MOVE.B	D4,-(A2)
	ROR.L	#8,D4
	MOVE.B	D4,-(A2)
	ROR.L	#8,D4
	MOVE.B	D4,-(A2)
	ROR.L	#8,D4
	MOVE.B	D4,-(A2)
	ROR.L	#8,D4
	MOVEQ	#0,D5
	MOVE.B	-(A0),D5
	ADD.L	D3,D5
	SUB.L	D5,D4
	DBRA	D1,lbC0003AC
	ADDQ.L	#1,A0
	JMP	(A3)

lbL0003CC
	dc.l	$FF800000
	dc.l	$1000200
lbL0003D4
	dc.l	$70008A
	dc.l	$A600C8
	dc.l	$136010A
	dc.l	$14E0148
	dc.l	$142013C

lbC0003E8	RTS

lbC0003EA	MOVEA.L	A3,A6
	MOVEQ	#0,D0
lbC0003EE	CLR.B	(A3)+
	SUBQ.B	#1,D0
	BNE.B	lbC0003EE
	MOVE.B	(A0)+,D0
	MOVE.B	#4,(A6,D0.W)
	MOVE.B	(A0)+,D0
	MOVE.B	#14,(A6,D0.W)
	MOVE.B	(A0)+,D0
	MOVE.B	#$1A,(A6,D0.W)
	MOVEQ	#0,D7
lbC00040E	CMPA.L	A2,A1
	BCC.B	lbC0003E8
	MOVE.B	(A0)+,D0
	MOVE.B	(A6,D0.W),D7
	JMP	(lbC00041C,PC,D7.W)

lbC00041C	MOVE.B	D0,(A1)+
	BRA.B	lbC00040E

	MOVEQ	#0,D2
	MOVE.B	(A0)+,D2
	BEQ.B	lbC00041C
	MOVEQ	#0,D1
	BRA.B	lbC00043E

	MOVE.B	(A0)+,D1
	BEQ.B	lbC00041C
	MOVE.B	D1,(A1)+
	MOVE.B	D1,(A1)+
	MOVE.B	D1,(A1)+
	BRA.B	lbC00040E

	MOVE.B	(A0)+,D1
	BEQ.B	lbC00041C
	MOVEQ	#0,D2
	MOVE.B	(A0)+,D2
lbC00043E	SUBQ.B	#3,D2
	BCS.B	lbC00044E
	MOVE.B	D1,(A1)+
	MOVE.B	D1,(A1)+
lbC000446	MOVE.B	D1,(A1)+
	DBRA	D2,lbC000446
	BRA.B	lbC00040E

lbC00044E	ADDQ.B	#1,D2
	BNE.B	lbC00045A
	MOVE.B	(A0)+,D2
	LSL.W	#8,D2
	MOVE.B	(A0)+,D2
	LSL.L	#8,D2
lbC00045A	MOVE.B	(A0)+,D2
	LSL.L	#8,D2
	MOVE.B	(A0)+,D2
	SUBQ.L	#1,D2
	MOVE.L	D2,D3
	SWAP	D3
lbC000466	MOVE.B	D1,(A1)+
	DBRA	D2,lbC000466
	DBRA	D3,lbC000466
	BRA.B	lbC00040E

	CNOP	0,8
_fuck1	dc.w	0
_fuck2	dc.w	0
_fuck3	dc.w	0
_fuck4	dc.w	0

;======================================================================

_tags		dc.l	WHDLTAG_MONITOR_GET
_mon		dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_2button		dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
_nb_lives		dc.l	0
		dc.l	WHDLTAG_CUSTOM4_GET
_start_level		dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
_skip_factor5_logos		dc.l	0
	IFD DEBUG
		dc.l	WHDLTAG_CUST_DISABLE,vposw
		dc.l	WHDLTAG_CUST_DISABLE,vhposw
	;	dc.l	WHDLTAG_CUST_DISABLE,copjmp1
	;	dc.l	WHDLTAG_CUST_DISABLE,copjmp2
	ENDC
		dc.l	0
_resload	dc.l	0		;address of resident loader
dont_save_highs
	dc.l	0
;======================================================================

	END
