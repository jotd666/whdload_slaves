
		INCDIR	Include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"Warzone.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_EmulTrap|WHDLF_NoError		;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config

_config
	dc.b    "C1:B:Infinite lives/bombs/energy;"			
	;;dc.b    "C2:L:Start level:1,2,3,4,5,6,7,8;"			
			dc.b	0

;============================================================================
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate	>T:date"
.passchk
	ENDC
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

_name		dc.b	"Warzone",0
_copy		dc.b	"1991 Core Design",0
_info		dc.b	"Installed by Codetapper/Action!",10
		dc.b	"Access fault fix by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	-1,"Keys: Help - Toggle infinite lives, bombs and energy"
		dc.b	10,"       1-8 - Select starting level                  "
		dc.b	-1,"Thanks to Chris Vella for the original!",0
_StartingLevel	dc.b	0
		EVEN

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

_restart	move.l	#$2c00,d0		;load initial file
		move.l	#$1e00,d1
		moveq	#1,d2
		lea	$40000,a0
		move.l	a0,a5
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)

		lea	_PL_Boot(pc),a0
		move.l	a5,a1
		jsr	resload_Patch(a2)

		lea	_tags(pc),a0
		jsr	(resload_Control,a2)

		jmp	(a5)

_PL_Boot	PL_START
		PL_P	$148e,_Main
		PL_P	$1494,_debug		;Load error
		PL_P	$14c2,_Loader		;Patch Rob Northen loader
		PL_END

;======================================================================

_Main		movem.l	d0-d1/a0-a2,-(sp)

		lea	_PL_Main(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		move.l	_infinite_lives(pc),d0
		beq.b	.noil
		bsr	toggle
.noil
		;;move.b	_start_level+3(pc),$98f7
		
		lea	$10000,a0
		lea	$15000,a1
		move.l	#$3d430058,d0		;Search for move.w d3,($58,a6)
		move.l	#$4eb80100,d1		;Patch code

		
_CheckNext	cmp.l	(a0),d0
		bne	_NoPatch

		move.l	#$4eb80100,(a0)+	;Insert patch instead
		bra	_SeeIfDone

_NoPatch	addq	#2,a0
_SeeIfDone	cmp.l	a0,a1
		bcc	_CheckNext

		clr.l	-(a7)			;TAG_DONE
                clr.l	-(a7)			;data to fill
		move.l	#WHDLTAG_BUTTONWAIT_GET,-(a7)
		move.l	a7,a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)
		move.l	(4,a7),d0		;d0 = -1 if ButtonWait
		lea	(12,a7),a7		;Restore sp

		tst.l	d0
		beq	_ShortDelay

		move.l	#5*60*50,d0		;Wait 5 minutes
		bra	_Delay

_ShortDelay	move.l	#50,d0
_Delay		bsr	_DelayD0

		movem.l	(sp)+,d0-d1/a0-a2
		jmp	$800			;Stolen code

_PL_Main	PL_START
		PL_P	$100,_BlitWaitD3	;Insert blitter patch
		PL_P	$106,_InfiniteLives	;Infinite lives trainer
		PL_P	$10c,_InfiniteBombs	;Infinite bombs trainer
		PL_P	$112,_InfiniteEnergy	;Infinite energy trainer
		PL_P	$90e0,_Loader		;Rob Northen loader
		PL_L	$99a4,$203c7b86		;Copylock
		PL_L	$99a8,$69f821c0
		PL_L	$99ac,$00606000
		PL_W	$99b0,$0918
		PL_PS	$a33c,_SetStartLevel	;Set starting level
		PL_PS	$DC12,avoid_smc
		PL_L	$11e30,$203c7b86	;2nd copylock
		PL_L	$11e34,$69f821c0
		PL_L	$11e38,$00606000
		PL_W	$11e3c,$0918
		PL_PS	$17806,_Keybd		;Detect quit key
		PL_L	$1780c,$4e714e71
		PL_END

;======================================================================

; sometimes A0 has some value so it writes 8 in $116E0 and it changes
; an address from < $80000 to > $80000: access fault, which happens
; on level 3 boss

avoid_smc:
	cmp.l	#$11670,a0
	bcc.b	.nowrite
	move.w	#8,($38,a0)
.nowrite
	rts

	
_SetStartLevel	move.b	_StartingLevel(pc),$98f7
		rts

;======================================================================

_BlitWaitD3	move.w	d3,($58,a6)
		;BLITWAIT
		btst	#6,$dff002
_Wait		btst	#6,$dff002
		bne	_Wait
		rts

toggle:
		eor.l	#$43fafc72^$4ef80106,$1609a	;Toggle infinite lives and bombs
		eor.l	#$43f90001^$4ef8010c,$160b0	;Toggle infinite bombs
		eor.l	#$4a790001^$33fc000c,$16132	;Toggle infinite energy
		eor.l	#$5d6a6618^$00015d68,$16136
		eor.l	#$4a790001^$4eb90000,$16152
		eor.w	#$5d88^$0112,$16156

		bsr	_FlushLibs
		rts
		
;======================================================================

_Keybd		move.b	$bfec01,d0		;Stolen code
		ror.b	#1,d0
		not.b	d0

		cmp.b	_keyexit(pc),d0
		beq	_exit

		cmp.b	#$5f,d0
		bne	_CheckNumber

		bsr	toggle

_CheckNumber	cmp.b	#1,d0			;Check for starting level
		blt	_NotNumber		;cheat mode
		cmp.b	#8,d0
		bhi	_NotNumber

		movem.l	d0/a0,-(sp)
		lea	_StartingLevel(pc),a0
		subq	#1,d0
		and.l	#7,d0
		move.b	d0,(a0)
		movem.l	(sp)+,d0/a0

_NotNumber	rts

;======================================================================

_FlushLibs	movem.l	d0-d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_FlushCache(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Loader		movem.l	d1-d2/a0-a2,-(sp)
                move.l  _resload(pc),a2		;a0 = dest address
		mulu	#$200,d1		;offset (sectors)
		mulu	#$200,d2		;length (sectors)
		move.l	d1,d0			;d0 = offset (bytes)
		move.l	d2,d1			;d1 = length (bytes)
		moveq	#1,d2			;d2 = disk
		jsr	resload_DiskLoad(a2)	;a0 = destination
		movem.l	(sp)+,d1-d2/a0-a2
		moveq	#0,d0
		rts

;======================================================================

_InfiniteLives	moveq	#2,d0			;Set life counter to 2 :)
		lea	$15d0e,a1
		move.w	d0,$15d64		;move.w	$15d64,d0
		move.b	d0,(a1)
		lea	$15d22,a1
		move.w	d0,$15d82		;move.w	$15d82,d0
		move.b	d0,(a1)
		rts

_InfiniteBombs	moveq	#2,d1
		lea	$15d17,a1
		move.w	d0,$15d66		;move.w	$15d66,d0
		move.b	d0,(a1)
		lea	$15d2b,a1
		move.w	d0,$15d84		;move.w	$15d84,d0
		move.b	d0,(a1)
		rts

_InfiniteEnergy	move.w	#$c,$15d86
		tst.w	$15d88
		rts

;======================================================================

_DelayD0	move.l	a0,-(a7)		;Waits for d0 frames or
		lea	(_custom),a0		;the mouse button
.down		bsr	.wait
		subq	#1,d0
		beq	.done
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)	;LMB
		beq	.up
		btst	#POTGOB_DATLY-8,(potinp,a0)	;RMB
		beq	.up
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)	;FIRE
		bne	.down
.up		bsr	.wait
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)	;LMB
		beq	.up
		btst	#POTGOB_DATLY-8,(potinp,a0)	;RMB
		beq	.up
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)	;FIRE
		beq	.up
		bsr	.wait
		bra	.done
.wait		waitvb	a0
		rts
.done		move.l	(a7)+,a0
		rts

;======================================================================
_resload	dc.l	0		;address of resident loader
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts
_tags
		dc.l	WHDLTAG_CUSTOM1_GET
_infinite_lives		dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_start_level		dc.l	0
	dc.l	0

		END
