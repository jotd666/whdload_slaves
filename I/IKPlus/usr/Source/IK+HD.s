;*---------------------------------------------------------------------------
;  :Program.	ik+.asm
;  :Contents.	Slave for "IK+"
;  :Author.	Wepl, StingRay
;  :Version.	$Id: ik+.asm 1.6 2001/08/29 16:12:44 wepl Exp wepl $
;  :History.	22.09.97 initial
;		01.10.97 debug key changed because F9 is used in game
;		24.11.98 adapted for v8 (obsoletes novbrmove)
;		13.07.01 supports another version
;		01.08.01 highscore saving added
;		29.08.01 some int stuff fixed, highscore saving fixed
;		27.06.16 (StingRay): writes to INTREQR fixed
;                                    proper NTSC support (replayer etc.
;				     runs at same speed as on PAL machines!,
;                                    CIA interrupt added to emulate VBI)
;                                    source is ASM-One/Pro compatible
;				     flickering on very fast machines fixed
;                                    uses WHDLoad v17+ features 
;				     bonus rounds can be disabled with CUSTOM2
;				     graphics bug with IK+ shield in bonus
;				     round fixed
;		14.08.16 NTSC support changed, now only the music is played
;			 at PAL speed, everything else runs at NTSC speed
;			 code optimised by using PLIF/PLENDIF features
;			 started to add cheat for 2 player mode as requested
;			 (Mantis issue 3509) but decided not to include
;			 it, too much of a hack and the game should be played
;		         without cheating anyway in my opinion
;		26.11.17 DMA wait in level 4 interrupt fixed, samples
;			 are now played properly (issue #3644)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131, Asm-Pro V1.16d
;  :To Do.	- fix sound problems on fast machines
;---------------------------------------------------------------------------*

	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

;DEBUG

	IFD	BARFLY
	OUTPUT	"wart:i/ik+/IK+.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_NoKbd	;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		IFD	DEBUG
		dc.w	_dir-_base		; ws_CurrentDir
		ELSE
		dc.w	0			;ws_CurrentDir
		ENDC
		dc.w	0			;ws_DontCache
		dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	$1000			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-_base	; ws_config


.config	
	dc.b	"C1:B:Enable cheat keys;"
	dc.b	"C2:B:Disable Bonus Rounds;"
	dc.b	"C3:B:Disable Timing Fix;"	
	;dc.b	"C3:B:Blue Player never wins (2 player mode)"
	dc.b	0



;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.9"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	
_name		dc.b	"International Karate +",0
_copy		dc.b	"1987/8 Archer Maclean",0
_info		dc.b	"installed and fixed by Wepl/StingRay/JOTD",10
		dc.b	"Version "
		DECL_VERSION
	dc.b	0
_file		dc.b	"IK+.Image",0
_savename	dc.b	"IK+.Highs",0
		IFD	DEBUG
_dir		dc.b	"SOURCES:WHD_Slaves/IK+",0
		ENDC

	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)
		move.l	a0,a2

	IFEQ 1
		moveq	#0,d0			;offset
		move.l	#$400,d1		;size
		lea	$1000.w,a0		;destination
		sub.l	a1,a1			;tags
		jsr	(resload_DiskLoadDev,a2)
		skip	6*2,$100c+$1a
		clr.w	$500.w			;stackframe format error
		jmp	$100c.w
	ENDC

		lea	(_file,pc),a0
		lea	$600.w,a1
		jsr	(resload_LoadFileDecrunch,a2)
		lea	$600.w,a0
		jsr	(resload_CRC16,a2)
		cmp.w	#$8570,d0		;Original
		beq	.ok
		cmp.w	#$bfb0,d0		;CDTV/HitSquad
		beq	.ok
		pea	(TDREASON_WRONGVER).w
		jmp	(resload_Abort,a2)
.ok
		lea	(_pl,pc),a0
		sub.l	a1,a1
		jsr	(resload_Patch,a2)

		lea	(_ciaa),a1
		tst.b	(ciaicr,a1)				;clear requests
		move.b	#CIAICRF_SETCLR|CIAICRF_SP,(ciaicr,a1)	;allow ints
		and.b	#~(CIACRAF_SPMODE),(ciacra,a1)		;input mode


; stingray, 27-jun-2016: NTSC stuff
	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)
	move.l	MON(pc),d0
	cmp.l	#NTSC_MONITOR_ID,d0
	bne.b	.isPAL

	lea	PLNTSC(pc),a0
	lea	$600.w,a1
	jsr	resload_Patch(a2)

.isPAL


		jmp	$600.w

TAGLIST		dc.l	WHDLTAG_MONITOR_GET
MON		dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
cheat	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
NOBONUSROUND	dc.l	0

		dc.l	TAG_DONE


PLNTSC	PL_START
	PL_PSS	$134e,.setLev6,2	; install level 6 interrupt
	PL_ORW	$141e+2,1<<13		; enable level 6 interrupt
	PL_S	$9c8,6			; don't call replayer in VBI
	PL_END


.setLev6
	pea	.NewLev6(pc)
	move.l	(a7)+,$78.w

	move.b	#$7f,$bfdd00	; stop CIA interrupts

	move.l	d0,-(a7)
	move.b	#0,$bfde00
	move.w	#$3781,d0

	move.b	d0,$bfd400	; timer A, lo
	lsr.w	#8,d0
	move.b	d0,$bfd500	; timer A, hi

	move.b	#$81,$bfdd00	; start interrupt
	move.b	#$11,$bfde00	; start timer A in cont. mode
	move.l	(a7)+,d0

	rts

.NewLev6
	movem.l	d0-a6,-(a7)
	tst.b	$bfdd00		; clear timer interrupt (CIA A, timer A)

	jsr	$600+$d3c.w	; call replayer every 1/50th second

	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	movem.l	(a7)+,d0-a6
	rte	



_pl	PL_START
	PL_R	$2475c			;copylock
;	PL_W	$500,0			;stackframe format error
	PL_P	$1098,_strt
	PL_R	$1976			;preserve NMI
	PL_P	$1aaa,_keyb
	PL_PS	$12bc+$600,_loadhighs
	PL_IFC1
	PL_ELSE
	PL_PS	$9cde+$600,_savehighs
	PL_ENDIF
	PL_S	$11a0+$600,$ba-$a0	;trap stuff
	PL_S	$c30+$600,4		;move #,sr
	PL_S	$99a+$600,4		;move #,sr

; stingray, 27-jun-2016
	PL_PSS	$1394+$600,.fixint,2	; fix write to INTREQR
	PL_PSS	$13a0+$600,.fixint2,2	; fix write to INTREQR
	PL_PSS	$cd0+$600,.fixint3,2	; fix write to INTREQR

	PL_IFC3
	PL_ELSE
	PL_P	$715c+$600,.waitraster	; fix flickering on fast machines
	PL_ENDIF
	
; disable bonus rounds if CUSTOM 2 <> 0
	PL_IFC2
	PL_P	$b106+$600,.skipbonus	; shields
	PL_P	$bfac+$600,.skipbonus	; bombs
	PL_ENDIF

	PL_PS	$b3da+$600,.fixgfx	; fix gfx bug when shield 2 is selected

;	PL_IFC3
;	PL_P	$55c+$600,.cheat	; blue player never wins (2 player mode)
;	PL_ENDIF



; v1.8, 26-Nov-2017, fix CPU  dependent DMA wait
; in level 4 interrupt so samples are played properly
	PL_PSS	$12e8,FixDMAWait,4	; $ce8+$600 fix DMA wait in level 4 interrupt
	PL_PSS	$1300,.dma_bounce,2
	PL_END

.dma_bounce
	move.w	#8,_custom+dmacon	; stop channel 4
	move.w  d0,-(a7)
	move.w	#3,d0   ; make it 7 if still issues
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	move.w	(a7)+,d0
	rts 

; $7d2.w: white
; $7d3.w: red
; $7d4.w: blue

;.cheat	cmp.b	#3,$678.w
;	bne.b	.no
;	
;
;	;cmp.b	#6,$7d4.w		; did blue player win?
;	;blt.b	.ok
;	clr.b	$7d4.w			; not anymore! :)
;	move.b	#6,$7d2.w		; white six points
;	move.b	#6,$7d3.w		; red too
;.ok
;	
;.no	jmp	$600+$5ec.w


.fixgfx	subq.w	#1,d6			; fix height -> no graphics bugs!
	lea	$600+$2339c,a0		; shield gfx (original code)
	rts


.skipbonus
	move.b	#1,$678.w
	rts


.waitraster
	btst	#0,$dff005
	bne.b	.waitraster
.wait2	btst	#0,$dff005
	beq.b	.wait2
	rts


.fixint	btst	#4,$dff01e+1
	rts

.fixint2
	btst	#5,$dff01e+1
	rts

.fixint3
	btst	#10-8,$dff01e
	rts


FixDMAWait
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	dbf	d0,.loop
	rts


_strt		move	#$2000,sr
		jmp	$ad4.w

_loadhighs	lea	_savename(pc),a0
		move.l	_resload(pc),a2
		jsr	(resload_GetFileSize,a2)
		tst.l	d0
		beq.b	.end
		lea	_savename(pc),a0
		move.l	_expmem(pc),a1
		jsr	(resload_LoadFile,a2)
		bsr.b	_swaphighs
		move.b	#1,$610.w	;original
.end		rts

_savehighs	bsr.b	_swaphighs
		move.l	#6*51,d0
		lea	_savename(pc),a0
		move.l	(_expmem,pc),a1
		move.l	_resload(pc),a2
		jsr	(resload_SaveFile,a2)
		bsr.b	_swaphighs
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		rts

_swaphighs	move.l	(_expmem,pc),a0
		lea	$a27.w,a1	;name x..
		bsr.b	.swap
		lea	$a5a.w,a1	;name .x.
		bsr.b	.swap
		lea	$a8d.w,a1	;name ..x
		bsr.b	.swap
		lea	$98e.w,a1	;score xx..00
		bsr.b	.swap
		lea	$9c1.w,a1	;score ..xx00
		bsr.b	.swap
		lea	$9f4.w,a1	;belt
.swap		moveq	#51-1,d0
.loop		move.b	(a0),d1
		move.b	(a1),(a0)+
		move.b	d1,(a1)+
		dbf	d0,.loop
		rts

_keyb	
		move.l	cheat(pc),d1
		beq.b	.no_cheat_keys
		cmp.b	#1,d0
		bne.b	.no_white_wins
		move.b	#6,$7D2.W	; awards 6 points, ends round now
.no_white_wins
		cmp.b	#2,d0
		bne.b	.no_red_wins
		move.b	#6,$7D3.W	; awards 6 points, ends round now
.no_red_wins
.no_cheat_keys
		cmp.b	(_keyexit,pc),d0
		beq.b	_exit
		jsr	$1b5e.w			;original
		moveq	#3-1,d1			;wait because handshake min 75 탎
.int2_w1	move.b	(_custom+vhposr),d0
.int2_w2	cmp.b	(_custom+vhposr),d0	;one line is 63.5 탎
		beq.b	.int2_w2
		dbf	d1,.int2_w1		;(min=127탎 max=190.5탎)
		jmp	$1ace.w

;--------------------------------

_exit		move	#$2700,sr		;otherwise freeze inside whdload
		lea	($80000),a7		;otherwise "bad stackpointer" on exit
		pea	(TDREASON_OK).w
		move.l	(_resload,pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

;--------------------------------

_resload	dc.l	0			;address of resident loader

;======================================================================

	END

