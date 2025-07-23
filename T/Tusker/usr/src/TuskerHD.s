;*---------------------------------------------------------------------------
;  :Program.	Tusker.asm
;  :Contents.	Slave for "Tusker" from System 3
;  :Author.	Mr.Larmer
;  :History.	--.--.---- - V1.0 - Initial Release (Mr.Larmer)
;		04.14.1998 - V1.1 - (Mr.Larmer)
;		   - Fixed access fault
;		01.03.2010 - V1.2 - (Abaddon)
;		   - Converted code to use Patchlists
;		   - Patched 2x copylocks
;                    There is a checksum against the 1st copylock, which is
;		     checked when you use the book in the last room of the cave
;		     on level one.  If the check fails the Machete will not be
;		     revealed.  (See commented code below)
;		   - Patched quit for 68000 
;		   - Patched keyboard ack delay
;		   - Mapped spacebar to second firebutton
;		   - Custom1=1 - Trainer
;		     Infinite Lives
;		     Infinite Bullets
;		     Inifnite Magic Stick
;		     Inifnite Water
;		   - Custom2=1 - Trainer 2
;		     Invincibility (testing only)
;		   - Custom4=1 - Music Select enabled.  The developers must 
;		     have disabled this
;		   
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly
;---------------------------------------------------------------------------*


        INCDIR  Include:
        INCLUDE whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
        OUTPUT  Tusker.slave
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
		dc.w	10			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem ;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-base		;ws_GameLoader
                dc.w    0		       	;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	$58			;ws_keydebug = F9
_keyexit	dc.b	$5f			;ws_keyexit = F10
_expmem		dc.l    0			;ws_ExpMem
		dc.w    _name-base		;ws_name
		dc.w    _copy-base		;ws_copy
		dc.w    _info-base		;ws_info

;======================================================================



_name		dc.b	"Tusker",0
_copy		dc.b	"1990 System 3",0
_info		dc.b	"Installed by Mr.Larmer/Wanted Team",10
		dc.b	"Updated by Keith Krellwitz/Abaddon",10
		dc.b	-1,"Version 1.2"
                dc.b    " (01/03/2010) "
		dc.b	0
		EVEN


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


		move.l  	#$0,d0
		lea     	$5d164,a0
		move.l  	#$1,d2
		move.l  	#$400,d1
		move.l		(_resload,pc),a2
		jsr		(resload_DiskLoad,a2)
_PatchLoader
		lea		_PL_LOADER(pc),a0		; Loader Patch List
		bsr		_Patch
		jmp		$5d170
		
_PatchIntro
		movem.l		d0-d7/a0-a6,-(sp)
		lea		_PL_MAIN(pc),a0			; Main Patch List
		bsr		_Patch
		
		move.l  	_Trainer1(pc),d0          
		beq     	.notrainer
		lea		_PL_TRAINER(pc),a0		; Trainer Patch List
		bsr		_Patch
.notrainer
		move.l  	_Trainer2(pc),d0          
		beq     	.notrainer2
		lea		_PL_TRAINER2(pc),a0		; Trainer 2 Patch List
		bsr		_Patch
.notrainer2
		move.l  	_Blitter(pc),d0          	; If set skip blitter patch
		bne     	.nopatchblitter
		lea		_PL_BLITTER(pc),a0
		bsr		_Patch
.nopatchblitter

		move.l  	_MusicSelect(pc),d0          	; The Music select was disabled
		beq     	.nomusicselect			; Haven't tested much of this
		lea		_PL_MUSICSELECT(pc),a0
		bsr		_Patch
.nomusicselect

		lea		_PL_BLITTER2(pc),a0		; Fixed blitter wait addressing errors
		bsr		_Patch

		movem.l		(sp)+,d0-d7/a0-a6
		jmp		$600



_Patch
		sub.l		a1,a1
		move.l		_resload(pc),a2
		jsr		resload_Patch(a2)
		rts

;======================================================================
;Patchlists
;======================================================================

_PL_LOADER
		PL_START
		PL_L		$5d1f2,$78004e75
		PL_P		$5d1e0,_PatchIntro
		PL_P		$5d2da,_LoadTracks
		PL_END

_PL_MAIN
		PL_START
		PL_W		$5d0c,$6dff		; move.w #$6E00,D7 - corrected for 0.5 mb chip
		PL_W		$5dda,$6036		; skip set int vectors
		PL_W		$5e1a,$6006		; skip set division by 0
		PL_W		$5e4a,$6006		; skip ext drive on
		PL_PS		$5b14,_PatchQuit
		PL_P		$613c,_ProtectionCheck1
		PL_P		$8a9a,_ProtectionCheck2
		PL_P		$9512,_DiskSwap
		PL_P		$95de,_PatchLoader	; Repatch after game over
		PL_L		$ee34,$78004e75
		PL_P		$ef1c,_LoadTracks
		PL_L		$11e54,$4bfa04dc	; correct access fault in A5
		PL_L		$11e58,$4a6e002e
		PL_W		$11e5c,$672c
		PL_PSS		$b404,_SecondFire,2
		PL_END

_PL_BLITTER
		PL_START
		PL_NOP		$2450,10
		PL_NOP		$44a2,10
		PL_NOP		$45a2,10
		PL_NOP		$4692,10
		PL_NOP		$47cc,10
		PL_NOP		$4874,10
		PL_NOP		$491a,10
		PL_NOP		$49fc,10

		PL_PSS		$2498,_WaitBlitter,4
		PL_PSS		$44f0,_WaitBlitter,4
		PL_PSS		$45f0,_WaitBlitter,4
		PL_PSS		$46e0,_WaitBlitter,4
		PL_PSS		$481a,_WaitBlitter,4
		PL_PSS		$48c2,_WaitBlitter,4
		PL_PSS		$4968,_WaitBlitter,4
		PL_PSS		$4a44,_WaitBlitter,4
		PL_END

_PL_BLITTER2
		PL_START
		PL_PSS		$f09c,_WaitBlitter,2
		PL_PSS		$f0c0,_WaitBlitter,2
		PL_PSS		$f0e6,_WaitBlitter,2
		PL_END

_PL_TRAINER
		PL_START
		PL_NOP		$2e4e,6			;Infinite Lives
		PL_NOP		$bb12,4			;Infinite Bullets
		PL_NOP		$2c3c,2			;Infinite Magic Stick
		PL_W		$2994,$6016		;Infinite Water
		PL_END

_PL_TRAINER2
		PL_START
		PL_NOP		$1d6a,6			;Infinitie Energy
		PL_NOP		$2090,6	
		PL_NOP		$2220,6	
		;PL_NOP		$2e66,6	
		PL_NOP		$3fac,6	
		PL_NOP		$40c6,6	
		PL_NOP		$4de0,6	
		PL_NOP		$4fb8,6	
		PL_NOP		$5548,6	
		PL_NOP		$5692,6	
		PL_NOP		$6bec,6	
		PL_NOP		$9d24,6	
		PL_NOP		$9e10,6	
		PL_NOP		$a04a,6	
		PL_NOP		$a768,6	
		PL_NOP		$c160,6	
		PL_END

_PL_MUSICSELECT						;Activate Music Select use
		PL_START				;F1-F7
		PL_NOP		$1900,2			;S - SFX only
		PL_END

;======================================================================
;Protection
;
;Protection Check 1 checksum calculated at $a334 and stored in $a364
;Correct value $8f6df251 
;cmp.l at $38d6
;
;The checksum was left intact and I modified how the copylocks are patched
;After the patch executes the original code is restored.
;======================================================================

_ProtectionCheck1					;Corrected Key (Abaddon)
		movem.l         a0,-(sp)		
		lea		$613c,a0
		bsr		_ProtectionCheck
		movem.l         (sp)+,a0
		jmp		$6a1c			

_ProtectionCheck2					;Second Copylock added (Abaddon)
		movem.l         a0,-(sp)
		lea		$8a9a,a0
		bsr		_ProtectionCheck
		movem.l         (sp)+,a0
		jmp		$937a			
		
_ProtectionCheck
		move.l		#$42404241,(a0)		;restore original code
		move.w		#$487a,4(a0)		;restore original code
		move.l		#$b590a736,d0		;sSet key
		moveq		#0,d1
		rts
		
;======================================================================
;Second Button Support
;======================================================================

_SecondFire
		movem.l         D0-D2/A0,-(sp)
		lea		_held_button(pc),a0
		move.l		#14,d1
		moveq		#$64,d2

		
		move.w          $DFF016,D0
		move.w          #$CC01,$DFF034
		btst		d1,d0
		bne		.NotPressed
		btst		d1,(a0)
		beq		.fire
		bra		.CheckKey
.fire
		bset		d1,(a0)
		move.b		#0,($b9ae)
		bra		.exit
.NotPressed
		bclr		d1,(a0)
.CheckKey
		move.b		($6e7c),($b9ae)
.exit		movem.l         (sp)+,D0-D2/A0
		rts
		
;======================================================================
;Delay for title screen, high score screen, etc
;======================================================================

		
_BeamDelay	
		movem.l		d0-d1,-(sp) 
		moveq		#$3,d1
.loop1 
		move.b		(_custom+vhposr),d0 
.loop2	 
		cmp.b		(_custom+vhposr),d0
		beq		.loop2
		dbf		d1,.loop1
		movem.l		(sp)+,d0-d1 
		rts


;======================================================================
;Blitter Patches
;======================================================================


_WaitBlitter	BLITWAIT	
		rts

;======================================================================
;Patch Quit
;======================================================================

_PatchQuit
		
		move.b		($bfec01),d0
		movem.l		d0,-(sp)
		not.b		d0
		ror.b		#1,d0
		cmp.b   	_keyexit(pc),d0                     
		beq     	_exit
		movem.l		(sp)+,d0
		rts
		
;======================================================================
;Loader
;======================================================================

_LoadTracks
		movem.l		D0-D7/A0-A6,-(sp)
		lea		_disknum(pc),a1
		cmpi.w          #1,(a1)
		beq     	.disk1
		tst.w		($402).w
		bne.b		.disk2side2
		subq.w		#2,d0
		bra		.load
.disk2side2	addi.w		#$24,d0
		bra		.load
.disk1		tst.w		($402).w
		beq.b		.load
		addi.w		#$3f,d0
.load		mulu    	#$1400,d0
		mulu    	#$1400,d1
		beq		.ok
		moveq		#0,d2
		move.w		(a1),d2
		move.l  	(_resload,pc),a2
		jsr     	(resload_DiskLoad,a2)
.ok		movem.l		(sp)+,D0-D7/A0-A6
		moveq		#0,d4
		rts

_DiskSwap
		movem.l		d0/a0,-(sp)
		lea             _disknum(pc),a0
		addq.l   	#$1,d0
		move.w		d0,(a0)
		movem.l		(sp)+,d0/a0
		rts

;======================================================================

_disknum
		dc.w    1
		even
_held_button	dc.l	0
		even
		
_resload	dc.l	0
_Tags           dc.l    WHDLTAG_CUSTOM1_GET
_Trainer1	dc.l    0
         	dc.l    WHDLTAG_CUSTOM2_GET
_Trainer2	dc.l    0
         	dc.l    WHDLTAG_CUSTOM3_GET
_Blitter	dc.l    0
         	dc.l    WHDLTAG_CUSTOM4_GET
_MusicSelect	dc.l    0
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
