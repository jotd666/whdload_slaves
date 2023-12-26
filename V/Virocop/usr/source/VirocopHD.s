;*---------------------------------------------------------------------------
;  :Program.	Virocop.asm
;  :Contents.	Slave for "Virocop" from Renegade
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
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly
;
; A-5f		H-56	O-51	V-48
; B-5c		I-57	P-4e	W-49
; C-5d		J-54	Q-4f	X-46
; D-5a		K-55	R-4c	Y-47
; E-5b		L-52	S-4d	Z-44
; F-58		M-53	T-4a    SPC-3e
; G-59		N-50	U-4b
;---------------------------------------------------------------------------*


        INCDIR  Include:
        INCLUDE whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
        OUTPUT  Virocop.slave
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
		dc.l	$100000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-base		;ws_GameLoader
                dc.w    0		       	;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	$58			;ws_keydebug = F9
_keyexit	dc.b	$59			;ws_keyexit = F10
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
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM


_name           dc.b    "Virocop",0
_copy           dc.b    "1995 Renegade",0
_info           dc.b    "Installed by Keith Krellwitz",10
                dc.b    "Version "
                DECL_VERSION
                dc.b    0
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
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
		move.l		a0,(a1)				;save for later use
		move.l		a0,a2
		lea     	(_Tags,pc),a0
		jsr     	(resload_Control,a2)


		move.w		#$7fff,$dff09a
		move.w		#$7fff,$dff09c
		move.w		#$7fff,$dff096

 
		move.l		#$1,d2
		lea		$b960,a0
		move.l		#$0,d0				;offset 
		move.l		#$400,d1			;length 
		move.l  	(_resload,pc),a2
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
		;waitbutton
		movem.l		D0-D7/A0-A6,-(sp)
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
		PL_PS		$BA34,_PatchIntroPicture	;Add waitbutton if tooltype set
		PL_PS		$BA56,_PatchMain
		PL_END


_PL_MAIN	PL_START					;Main patchlist
		PL_P		$4582e,_LoadTracks2
		PL_P		$45930,_SaveTracks
		PL_P		$44020,_PatchMemoryCheck
		PL_PS		$447d4,_PatchQuit
		PL_P		$43e94,_PatchDecrypted		;After a section is decoded jump to patch to remove disk access
		PL_END

_PL_DECRYPT	PL_START
		PL_R		$6392				;Remove disk access
		PL_W		$680e,$6026			;Remove disk access
		PL_END


_PL_MAIN2	PL_START
		PL_PSS		$90c3a,_DiskSwap,4		;simulate disk swap
		PL_L		$8ffc8,$60000062		;bypass protection
		PL_P		$9677c,_FixAddressingError
		PL_NOP		$9107a,2			;remove check for freeze
		PL_W		$e54dc,$e			;Fix copperlist - COP1LCL
		PL_W		$e54e0,$54d2
		PL_W		$724c,$7342			;Fix copperlist - COP1LCL
		PL_PS		$924d4,_FixAccessFault		;Fix access fault before the game over screen
		PL_PS		$903a0,_SaveHighScoreTable
		PL_END

_PL_BLITTER	PL_START
		PL_PSS		$920E2,_WaitBlitter,2
		PL_PSS		$922A6,_WaitBlitter,2
		PL_PSS		$922CE,_WaitBlitter,2
		PL_PSS		$9230A,_WaitBlitter,2
		PL_PSS		$92322,_WaitBlitter,2
		PL_PSS		$92342,_WaitBlitter,2
		PL_PSS		$95F36,_WaitBlitter,2
		PL_PSS		$95F62,_WaitBlitter,2
		PL_PSS		$960C0,_WaitBlitter,2
		PL_PSS		$9D9C0,_WaitBlitter,2
		PL_PSS		$9DA54,_WaitBlitter,2
		PL_PSS		$9DA76,_WaitBlitter,2
		PL_PSS		$9DA98,_WaitBlitter,2
		PL_PSS		$9DABA,_WaitBlitter,2
		PL_PSS		$9DD80,_WaitBlitter,2
		PL_PSS		$9E142,_WaitBlitter,2
		PL_PSS		$9EB84,_WaitBlitter,2
		PL_PSS		$9EBD2,_WaitBlitter,2
		PL_PSS		$9F0EE,_WaitBlitter,2
		PL_PSS		$9F4B2,_WaitBlitter,2
		PL_PSS		$9F81E,_WaitBlitter,2
		PL_PSS		$9F878,_WaitBlitter,2
		PL_PSS		$9F8CC,_WaitBlitter,2
		PL_PSS		$9F8EC,_WaitBlitter,2
		PL_PSS		$9F90C,_WaitBlitter,2
		PL_PSS		$9F92C,_WaitBlitter,2
		PL_PSS		$9F9A6,_WaitBlitter,2
		PL_PSS		$9FACC,_WaitBlitter,2
		PL_PSS		$9FE92,_WaitBlitter,2
		PL_PSS		$9FF22,_WaitBlitter,2
		PL_PSS		$9FF44,_WaitBlitter,2
		PL_PSS		$9FF66,_WaitBlitter,2
		PL_PSS		$9FF88,_WaitBlitter,2
		PL_PSS		$A022C,_WaitBlitter,2
		PL_PSS		$A05F0,_WaitBlitter,2
		PL_PSS		$A0794,_WaitBlitter,2
		PL_PSS		$A0B5A,_WaitBlitter,2
		PL_PSS		$A0CE4,_WaitBlitter,2
		PL_PSS		$A10AA,_WaitBlitter,2
		PL_END


_PL_TRAINER	PL_START
		PL_NOP		$9ac9e,4			; Infinite Lives
		PL_B		$9aca2,$60
		
		PL_NOP		$96f7e,4			; Infinite Energy
		PL_B		$96f82,$60
		PL_NOP		$96f68,4
		PL_B		$96f72,$60
		
		PL_NOP		$9CC0E,4			; Infinite Cash
		PL_END

;======================================================================
;Memory Patch
;======================================================================

_PatchMemoryCheck
		lea		$100000,a0
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
		movem.l		(a7)+,d0
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
		move.l  	(_resload,pc),a2
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
.load		move.l  	(_resload,pc),a2
		jsr     	(resload_DiskLoad,a2)
		
		bsr		_PatchGame			;Call to see if patching is required

		movem.l		(sp)+,D0-D7/A0-A6
		moveq		#0,d0
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

_DiskSwap	
		movem.l		D1/A0,-(sp)
		moveq		#0,d1
		move.b		d0,d1
		add.l		#$1,d1
		lea		_disknum(pc),a0
		move.l		d1,(a0)
		movem.l		(sp)+,D1/A0
		rts


_SaveHighScoreTable
		jsr		($966c6)
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
		cmp.l		#$610000a2,($8ffc8)			; Check if protection check patched if so all
		bne		.nopatch				; patching is complete

		bsr		_LoadHighScoreTable
		
		lea		_PL_MAIN2(pc),a0
		bsr		_Patch

		move.l  	_Custom1(pc),d0          		; Infinite Energy and Lives 
		beq     	.notrainer
		lea		_PL_TRAINER(pc),a0
		bsr		_Patch
.notrainer

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
		jmp		$96782
_good1		jmp		$96788
		
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
_end      move.l  (_resload,pc),-(a7)
          add.l   #resload_Abort,(a7)
          rts

;======================================================================

        END
