;*---------------------------------------------------------------------------
;  :Program.	ViroCop.asm
;  :Contents.	Slave for "ViroCop" from Renegade
;  :Author.	Keith Krellwitz / Abaddon
;  :History.	12.29.2012 - V1.0
;		 - System friendly disk imager.
;		 - Manual Protection Removed
;		 - Trainer (Custom1=1) - Infinite Energy, Cash & Lives
;		 - Load/Save registration to HD (saves to Disk.1 image)
;		 - Patched quit for 68000
;		 - Fixed 1x access faults 
;		 - Fixed issue with press fire screen.  Issue was with the
;		   diskswap routine.
;		 - Fixed 2x copper snoop bugs
;		 - Custom2=1 - Disable blitter patches
;		 - Fixed access fault which occurs right before the game over
;		   screen.
;		
;
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly
;
; PTDRMSH
;
;---------------------------------------------------------------------------*


        INCDIR  Include:
        INCLUDE whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
        OUTPUT  ViroCop2Meg.slave
	DOSCMD	"WDate  >T:date"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimizer warnings
	SUPER
	ENDC

;======================================================================

base
		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_EmulTrapV|WHDLF_ClearMem  ;ws_flags
		dc.l	$200000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-base		;ws_GameLoader
                dc.w    0		       	;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	$58			;ws_keydebug = F9
_keyexit	dc.b	$59			;ws_keyexit = Help
_expmem		dc.l    $0			;ws_ExpMem
		dc.w    _name-base		;ws_name
		dc.w    _copy-base		;ws_copy
		dc.w    _info-base		;ws_info
                dc.w	0			;ws_kickname
                dc.l	0			;ws_kicksize
                dc.w	0			;ws_kickcrc
                dc.w	_config-base		;ws_config

;======================================================================

DECL_VERSION:MACRO
		dc.b	"1.0"
			IFD BARFLY
		dc.b	" "
			INCBIN	"T:date"
			ENDC
			ENDM




_name           dc.b    "ViroCop (2 Meg)",0
_copy           dc.b    "1995 Renegade",0
_info           dc.b    "Installed by Keith Krellwitz",10
                dc.b    "Version "
                DECL_VERSION
                dc.b    0
                EVEN

_config
                dc.b    "BW;"
                dc.b    "C1:X:Enable Trainer:0;"
                dc.b    "C2:X:Disable Blitter Patches:0;"
                dc.b    0
                even

;======================================================================
_start	;	A0 = resident loader
;======================================================================


		lea		_resload(pc),a1
		move.l		a0,(a1)					;save for later use
		move.l		a0,a2
		lea     	(_Tags,pc),a0
		jsr     	(resload_Control,a2)


		move.w		#$7fff,$dff09a
		move.w		#$7fff,$dff09c
		move.w		#$7fff,$dff096

 
		move.l		#$1,d2
		lea		$b960,a0
		move.l		#$0,d0				;offset 
		move.l		#$400,d1				;length 
		move.l  	(_resload),a2
		jsr     	(resload_DiskLoad,a2)

		lea		_PL_INTRO(pc),a0
		bsr		_Patch
		
		lea 		$100,A5
		move.l 		#$426f6f74,(a5)+
		
		jmp		$B9DA

_PatchIntroPicture
		lea		($4400,a5),a0
		jsr 		(a0)
		
		movem.l		D0,-(sp)
		move.l  	_ButtonWait(pc),d0          
        	beq.b     	.nobuttonwait
		waitbutton
.nobuttonwait
		movem.l		(sp)+,D0
		rts


_PatchMain
		lea		($4404,a5),a0
		jsr 		(a0)

		movem.l		D0-D7/A0-A6,-(sp)
		;waitbutton
		lea		_PL_MAIN(pc),a0
		bsr		_Patch

		movem.l		(sp)+,D0-D7/A0-A6
		rts

_PatchDecrypted
		movem.l		D0-D7/A0-A6,-(sp)
		lea		_PL_DECRYPT(pc),a0
		bsr		_Patch
		movem.l		(sp)+,D0-D7/A0-A6
		jmp		$4af0
	

_Patch
		sub.l		a1,a1
		move.l		_resload(pc),a2
		jsr		resload_Patch(a2)
		rts

;======================================================================
;Patchlists
;======================================================================

_PL_INTRO	PL_START
		PL_P		$BA70,_LoadTracks1
		PL_PS		$BA34,_PatchIntroPicture
		PL_PS		$BA56,_PatchMain
		PL_END


_PL_MAIN	PL_START
		PL_P		$4582e,_LoadTracks2
		PL_P		$45930,_SaveTracks
		PL_P		$44020,_PatchMemoryCheck
		PL_PS		$447d4,_PatchQuit
		PL_P		$43e94,_PatchDecrypted		;After a section 
		PL_END

_PL_DECRYPT	PL_START
		PL_R		$6392				;Remove disk access
		PL_W		$680e,$6026			;Remove disk access
		PL_END



_PL_MAIN2	PL_START
		PL_PSS		$c12ac,_DiskSwap,2
		PL_L		$be7d6,$60000062
		PL_P		$c4f8a,_FixAddressingError
		PL_NOP		$bf888,2
		
		PL_W		$b15d6,$b			;Fix copperlist - COP1LCL
		PL_W		$b15da,$15cc
		PL_W		$724c,$7342			;Fix copperlist - COP1LCL
		PL_PS		$C0CE2,_FixAccessFault		;Fix access fault before the game over screen
		PL_PS		$BEBAE,_SaveHighScoreTable
		PL_END

_PL_BLITTER	PL_START
		PL_PSS		$920E2+2E80E,_WaitBlitter,2
		PL_PSS		$922A6+2E80E,_WaitBlitter,2
		PL_PSS		$922CE+2E80E,_WaitBlitter,2
		PL_PSS		$9230A+2E80E,_WaitBlitter,2
		PL_PSS		$92322+2E80E,_WaitBlitter,2
		PL_PSS		$92342+2E80E,_WaitBlitter,2
		PL_PSS		$95F36+2E80E,_WaitBlitter,2
		PL_PSS		$95F62+2E80E,_WaitBlitter,2
		PL_PSS		$960C0+2E80E,_WaitBlitter,2
		PL_PSS		$9D9C0+2E80E,_WaitBlitter,2
		PL_PSS		$9DA54+2E80E,_WaitBlitter,2
		PL_PSS		$9DA76+2E80E,_WaitBlitter,2
		PL_PSS		$9DA98+2E80E,_WaitBlitter,2
		PL_PSS		$9DABA+2E80E,_WaitBlitter,2
		PL_PSS		$9DD80+2E80E,_WaitBlitter,2
		PL_PSS		$9E142+2E80E,_WaitBlitter,2
		PL_PSS		$9EB84+2E80E,_WaitBlitter,2
		PL_PSS		$9EBD2+2E80E,_WaitBlitter,2
		PL_PSS		$9F0EE+2E80E,_WaitBlitter,2
		PL_PSS		$9F4B2+2E80E,_WaitBlitter,2
		PL_PSS		$9F81E+2E80E,_WaitBlitter,2
		PL_PSS		$9F878+2E80E,_WaitBlitter,2
		PL_PSS		$9F8CC+2E80E,_WaitBlitter,2
		PL_PSS		$9F8EC+2E80E,_WaitBlitter,2
		PL_PSS		$9F90C+2E80E,_WaitBlitter,2
		PL_PSS		$9F92C+2E80E,_WaitBlitter,2
		PL_PSS		$9F9A6+2E80E,_WaitBlitter,2
		PL_PSS		$9FACC+2E80E,_WaitBlitter,2
		PL_PSS		$9FE92+2E80E,_WaitBlitter,2
		PL_PSS		$9FF22+2E80E,_WaitBlitter,2
		PL_PSS		$9FF44+2E80E,_WaitBlitter,2
		PL_PSS		$9FF66+2E80E,_WaitBlitter,2
		PL_PSS		$9FF88+2E80E,_WaitBlitter,2
		PL_PSS		$A022C+2E80E,_WaitBlitter,2
		PL_PSS		$A05F0+2E80E,_WaitBlitter,2
		PL_PSS		$A0794+2E80E,_WaitBlitter,2
		PL_PSS		$A0B5A+2E80E,_WaitBlitter,2
		PL_PSS		$A0CE4+2E80E,_WaitBlitter,2
		PL_PSS		$A10AA+2E80E,_WaitBlitter,2
		PL_END


_PL_TRAINER	PL_START
		PL_NOP		$C94AC,4			; Infinite Lives
		PL_B		$C94B0,$60
		
		PL_NOP		$C578C,4			; Infinite Energy
		PL_B		$C5790,$60
		PL_NOP		$C5776,4
		PL_B		$C5780,$60

		PL_NOP		$CB41C,4			; Infinite Cash
		PL_END

;======================================================================
;Memory Patch
;======================================================================

_PatchMemoryCheck
		lea		$200000,a0
		lea		$0,a1
		move.l		a0,d0
		move.l		d0,($43f8)
		rts
		
;======================================================================
;Blitter Patches
;======================================================================

_WaitBlit1
		move.w		d2,($58,a2)
		bra		_WaitBlitter
_WaitBlit2
		move.w		d7,($58,a6)
		bra		_WaitBlitter

_WaitBlitter	BLITWAIT	
		rts

;======================================================================
;Patch Quit
;======================================================================

_PatchQuit	move.b		($bfec01),d0
		movem.l		d0,-(a7)
		ror.b		#$1,d0
		not.b		d0
		cmp.b		_keyexit(pc),d0                     
		beq		_exit
		;bsr		_BeamDelay
		movem.l		(a7)+,d0
		rts
		
;======================================================================
;Delay 
;======================================================================

_BeamDelay
		move.w  	d0,-(a7)
		move.w		#3,D0
		beq.b		.bexit		; don't wait
.bloop1
		move.w  	d0,-(a7)
        	move.b		$dff006,d0	; VPOS
.bloop2
		cmp.b		$dff006,d0
		beq.s		.bloop2
		move.w		(a7)+,d0
		dbf		d0,.bloop1
.bexit
		move.w		(a7)+,d0
		rts

;======================================================================
;Disk Access Routines
;======================================================================

_LoadTracks1
		movem.l		D0-D7/A0-A6,-(sp)
		move.l		d3,d0
		move.l		d5,d1
		mulu.w  	#$200,d0
		mulu.w  	#$200,d1
		move.l		a3,a0
		moveq		#$1,d2
		move.l  	(_resload),a2
		jsr     	(resload_DiskLoad,a2)
		movem.l		(sp)+,D0-D7/A0-A6
		rts

_LoadTracks2			;(6484)
		movem.l		D0-D7/A0-A6,-(sp)
		move.l		a2,a0
		mulu.w		#$200,d6
		move.l		d6,d1
		moveq		#0,d0
		move.w		d4,d0
		add.w		d0,d0
		add.w		d3,d0
		mulu.w  	#$1600,d0
		sub.w 		#$1,d5
		mulu.w  	#$200,d5
		add.l		d5,d0
		cmpi.b		#1,d2
		bne		.notdisk2
		addi.w		#1,d2
		bra		.load
.notdisk2	move.l		_disknum(pc),d2
.load		move.l  	(_resload),a2
		jsr     	(resload_DiskLoad,a2)
		
		bsr		_PatchGame			;Call to see if patching is required
		
		movem.l		(sp)+,D0-D7/A0-A6
		moveq		#0,d0
		rts

_DiskSwap	
		movem.l		D1/A0,-(sp)
		moveq		#0,d1
		move.b		($bd8d7),d1
		subi.b		#$11,d1
		add.l		#$1,d1
		lea		_disknum(pc),a0
		move.l		d1,(a0)
		movem.l		(sp)+,D1/A0
		rts


_SaveTracks
		movem.l		D0-D7/A0-A6,-(sp)
		move.l		a2,a1
		mulu.w		#$200,d6
		move.l		d6,d0
		moveq		#0,d1
		move.w		d4,d1
		add.w		d1,d1
		add.w		d3,d1
		mulu.w  	#$1600,d1
		sub.w 		#$1,d5
		mulu.w  	#$200,d5
		add.l		d5,d1
		lea     	(_save,pc),a0           ;name
                move.l  	(_resload,pc),a2
                jsr     	(resload_SaveFileOffset,a2)
		movem.l		(sp)+,D0-D7/A0-A6
		moveq		#0,d0
		rts

_SaveHighScoreTable
		jsr		($c4ed4)
		movem.l		D0-D7/A0-A6,-(sp)
		lea		$1242,a1
		lea             _high(pc),a0
		move.l  	#$30,d0
		move.l          (_resload,pc),a2
		jsr             (resload_SaveFile,a2)
		movem.l		(sp)+,D0-D7/A0-A6
		rts


_LoadHighScoreTable
		movem.l		D0-D7/A0-A6,-(sp)
		lea             _high(pc),a0
		move.l  	(_resload,pc),a2
		jsr     	(resload_GetFileSize,a2)
		tst.l           D0
		beq             .noload
		lea             _high(pc),a0
		lea		$1242,a1
		move.l          (_resload,pc),a2
		jsr     	(resload_LoadFile,a2)
.noload		movem.l		(sp)+,D0-D7/A0-A6
		rts

;======================================================================
; Patches applied from the track loader
;======================================================================

_PatchGame
		cmp.l		#$610000a2,($BE7D6)			; Check if protection check patched if so all
		bne		.nopatch				; patching is complete
		
		bsr		_LoadHighScoreTable

		lea		_PL_MAIN2(pc),a0
		bsr		_Patch

		move.l  	_Custom1(pc),d0          		; Infinite Energy and Lives 
		beq     	.notrainer
		lea		_PL_TRAINER(pc),a0
		bsr		_Patch
.notrainer
		;move.l  	_Custom3(pc),d0          
		;beq     	.nocd32
		;lea		_PL_CD32(pc),a0				; CD32 Patch List
		;bsr		_Patch
.nocd32	

		move.l  	_Custom2(pc),d0
		bne     	.nopatch
		lea		_PL_BLITTER(pc),a0			; Blitter Patch List
		bsr		_Patch
.nopatch
		rts

;======================================================================
; Fix 68000 with 1 meg chip 
; 68020+ didn't have this issue as address 0 always contained 0.l while
; 68000 always had an invalid address.  It works from floppy but not 
; from WHDLoad. 
;======================================================================

_FixAddressingError
		cmpa.l		#$0,a0
		bne		.continue		
		rts		
.continue
		MOVE.L 		($2a,A0),D0
		BEQ		_good1
		jmp		$c4f90
_good1		jmp		$c4f96

;access fault just before the gameover screen appears
_FixAccessFault
		move.l		(4,a4),a3
		movem.l		d4,-(sp)
		move.l		a3,d4
		andi.l		#$fffff,d4
		move.l		d4,a3
		movem.l		(sp)+,d4
		cmp.b		(a3),d4
		rts

;======================================================================

_disknum	dc.l	1
		even

_save		dc.b	"Disk.1",0
		even

_high		dc.b	"Virocop.high",0
		even

_resload	dc.l	0
_Tags           dc.l    WHDLTAG_CUSTOM1_GET
_Custom1	dc.l    0
         	dc.l    WHDLTAG_CUSTOM2_GET
_Custom2	dc.l    0
		dc.l    WHDLTAG_BUTTONWAIT_GET
_ButtonWait	dc.l    0
                dc.l    TAG_DONE
                
;======================================================================


_exit     pea     TDREASON_OK
          bra     _end
_debug    pea     TDREASON_DEBUG
          bra     _end
_wrongver pea     TDREASON_WRONGVER
_end      move.l  (_resload),-(a7)
          add.l   #resload_Abort,(a7)
          rts

;======================================================================

        END
