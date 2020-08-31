;*---------------------------------------------------------------------------
;  :Program.   NewZealandStoryHD.asm
;  :Contents.  Slave for "NewZealandStory" from
;  :Authors.   JOTD & Hungry Horace
;  :History.   28.01.05 - v1.3
;              28.04.09 - v2.0 Final
;         - rewritten for whdload (JOTD)
;         - bugfix for endgame buttonwait (HH)
;         - enter round as END on scoreboard when complete
;         - load / save highscores if cheats unused
;         - no sound emulator bugfix
;         - Tooltypes added:
;            - CUSTOM1=1 infinite lives
;            - CUSTOM1=2 infinite oxygen
;            - CUSTOM1=4 enable levelskip
;            - CUSTOM2=1 "fastcheater" by JOTD
;            - CUSTOM3=1 use arcade style 2-button control
;         - Full support for both versions
;               10.07.13 - v2.1
;         - fixed 68000 "blackscreen"bug
;         - added v17 options
;  :Notes.
;     Ver.1 is the common "FLUFFYKIWIS" version
;     Ver.2 is the original "MOTHERFUCKENKIWIBASTARD" version
;  :Requires.  -
;  :Copyright. Public Domain
;  :Language.  68000 Assembler
;  :Translator.   Barfly 1.131
;  :To Do.
;     Add title-screen - with buttonwait from tooltype
;     use 7 digit score-system ?
;*---------------------------------------------------------------------------

	INCDIR   Include:
	INCLUDE  whdload.i
	INCLUDE  whdmacros.i

   IFD BARFLY
   OUTPUT		NewZealandStory.slave
   BOPT  O+		;enable optimizing
   BOPT  OG+            ;enable optimizing
   BOPT  ODd-           ;disable mul optimizing
   BOPT  ODe-           ;disable mul optimizing
   BOPT  w4-            ;disable 64k warnings
   BOPT  wo-            ;disable optimizer warnings
   SUPER
   ENDC

;USE_FASTMEM
CHIPMEMSIZE = $80000
EXPMEMSIZE = $0

;======================================================================

_base
		SLAVE_HEADER			;ws_Security + ws_ID
   		dc.w  17 			;ws_Version
		dc.w  WHDLF_Disk|WHDLF_NoError	;ws_flags
      IFD   USE_FASTMEM
		dc.l  CHIPMEMSIZE		;ws_BaseMemSize
      ELSE
		dc.l  CHIPMEMSIZE+EXPMEMSIZE
      ENDC
		dc.l  0				;ws_ExecInstall
		dc.w  start-_base		;ws_GameLoader
		dc.w  0				;ws_CurrentDir
		dc.w  0				;ws_DontCache
_keydebug	dc.b  69			;ws_keydebug
_keyexit	dc.b  $5D			;ws_keyexit = '*'
_expmem  
   IFD   USE_FASTMEM 
  		dc.l  EXPMEMSIZE	;ws_ExpMem
   ELSE
		dc.l  0
   ENDC
		dc.w  _name-_base    ;ws_name
		dc.w  _copy-_base    ;ws_copy
		dc.w  _info-_base    ;ws_info
		dc.w	0		; ws_kickname
		dc.l	0		; ws_kicksize
		dc.w	0		; ws_kickcrc
		dc.w	_config-_base		
_config:	dc.b    "C1:X:Infinite Lives:0;"			; ws_config
		dc.b    "C1:X:Infinite Oxygen:1;"
		dc.b    "C1:X:Enable Levelskip (Help Key):2;"
		dc.b    "C2:B:Enable Single Button Cheat Activation;"
		dc.b    "C3:B:Enable 2 Button Support;"
		dc.b    0
	
		EVEN
;============================================================================

	EVEN
   IFD BARFLY
   DOSCMD   "WDate  >T:date"
   ENDC


DECL_VERSION:MACRO
   dc.b  "2.2"
   IFD BARFLY
      dc.b  " "
      INCBIN   "T:date"
   ENDC
   ENDM

_name    dc.b  "The New Zealand Story"
      dc.b  0
_copy    dc.b  "1988 Ocean",0
_info    dc.b  "Adapted & fixed by JOTD & Abaddon",10
      dc.b  "Additions by Hungry Horace",10,10
      dc.b  "Version "
      DECL_VERSION
      dc.b  0
_savename   dc.b  "NewZealandStory.highs",0
      dc.b  0


; version xx.slave works

   dc.b  "$","VER: slave "
   DECL_VERSION
   dc.b  $A,$D,0

BASE_ADDRESS = $400



;======================================================================
start ;  A0 = resident loader
;======================================================================

      even

      lea	_resload(pc),a1
      move.l   a0,(a1)        ;save for later use
      move.l   a0,a2
      
      lea   (_tags,pc),a0
      jsr   (resload_Control,a2)

      lea   CHIPMEMSIZE-$100,a7
      move.w   #$2700,SR


   ; load & version check

      lea   BASE_ADDRESS,A0
      move.l   #$5E,D0
      move.l   #$32,D1
      bsr   read_tracks

;     lea   BASE_ADDRESS,A0
;     move.l   #$F4,d0
;     jsr   resload_CRC16(a2)

   ; *** unpack data

	lea   BASE_ADDRESS,A0
	bsr   decrunch

   ; *** shift data by 4 bytes ($404 -> $400 and so on)

	lea   $404,A1
;;;     move.w   #$B83,D0
	move.w   #$C00,D0
.tr
	move.l   (A1),-4(A1)
	addq.l   #4,A1
	dbf   D0,.tr

	sub.l a1,a1
	lea   pl_boot_v1(pc),a0


   ; main patches (JOTD)

	lea   version(pc),a3
	move  #1,(a3)			; assume version 1
   
	cmp.l #$35400058,$C1C4		; check version
	beq   .v1

	lea   pl_boot_v2(pc),a0
	move  #2,(a3)			; it is version 2

.v1	move.l   _resload(pc),a2
	jsr   resload_Patch(a2)

	bsr   _loadscore		; load scoreboard
	bsr   _tooltypes		; set tooltype extras
   
	move.l	(_resload,pc),a2		; 
 	jsr 	(resload_FlushCache,a2)		; flush cache 
	waitvb

	jmp   BASE_ADDRESS		; begin game


; *** custom tooltypes routine

_tooltypes	
	movem.l  D0-D1/A0-A2,-(A7)

	move	version(pc),d0		; get version
	move.l	custom3(pc),d1		; CUSTOM3 tooltype (2 button)
   
	cmpi.l	#0,d1      		; check if =0
      	beq	.skip1         		; skip
      
	move.l   #0,a1			; patch from start            
      
	lea	pl_arcade_control_v2(pc),a0   ; patch 2 button control

	cmp	#2,d0			; if version 2
	beq	.patchctrl		; goto patch

	lea	pl_arcade_control_v1(pc),a0   ; patch 2 button control   

.patchctrl	
	jsr	resload_Patch(a2)    ; do patch



.skip1	;  move.l	custom4(pc),d1	; CUSTOM4 tooltype (sound test)
	;  cmpi.l	#0,d1		; if active
	;  bne		.skip2		; no easycheat

	move.l	custom2(pc),d1	; CUSTOM2 tooltype (easy cheater)
	cmpi.l	#0,d1		; check if =0
	beq	.skip2		;  skip
      
      
	cmp   	#2,d0      	; if version 2
	beq   	.easycheatver2	; goto other exit    

	move.w   #$601E,$B794	; *** easier original cheat (JOTD)  
	bra   	.skip2            

.easycheatver2		
	move.w   #$6028,$BA0A   	; *** easier original cheat (HH) 

.skip2
      
	move.l	custom1(pc),d1			; CUSTOM1 tooltype (trainers)
   
	btst.l	#0,d1       			; check if bit1 true
	beq	.nolives    			; otherwise skip

	move.l   #0,a1       			; patch from start

	lea	pl_trainer_lives_v2(pc),a0	; assume ver 2

	cmp	#2,d0				; if version 2
	beq	.livespatch			; skip to patch

	lea	pl_trainer_lives_v1(pc),a0	; make ver 1

.livespatch	
	jsr	resload_Patch(a2)		; do patch  


.nolives
	move.l   custom1(pc),d1   		; CUSTOM1 tooltype (trainers)

	btst.l	#1,d1				; check if bit1 true
	beq	.nooxygen			; otherwise skip

	move.l	#0,a1				; patch from start

	lea	pl_trainer_oxygen_v2(pc),a0	; assume ver 2
	cmp	#2,d0				; if version 2
	beq	.oxygenpatch			; skip to patch

	lea	pl_trainer_oxygen_v1(pc),a0	; make ver 1

.oxygenpatch   
		jsr	resload_Patch(a2)	; do patch  

.nooxygen   
		move.l	custom1(pc),d1		; CUSTOM1 tooltype (trainers)
		btst.l	#2,d1			; check if bit1 true
		beq	.exit			; otherwise skip

		cmp	#2,d0			; if version 2
		beq	.levelskipver2    	; goto other exit    

		move.w	#$3E8,$4FBA		; *** levelskip on v1   
		bra	.exit          

.levelskipver2 
		move.w   #$3E8,$4F48		; *** levelskip on v2

.exit		movem.l (a7)+,D0-D1/A0-A2
		rts


; *** end game bugfix (HH)

_endgame	movem.l	D0/A0,-(A7)		; preseve regs
		lea	complete(pc),a0		; link complete
		move	#1,(a0)			; set as "complete"

		lea	version(pc),a0		; link version
		cmp	#2,(a0)			; check for version 2
		beq	.ver2

.ver1		movem.l	(A7)+,D0/A0		; restore regs
		jmp	$40DC			; goto "Game Over" buttonwait

.ver2		movem.l	(A7)+,D0/A0		; restore regs
		jmp	$40DA			; goto "Game Over" buttonwait

   
   
   
; *** level entry to scoreboard after completion (HH)

_endround	
		movem.l	(a7),a0-a1		; original score entry code
		moveq	#$f,d6
.loop		move.b	(a0),d0
		move.b	(a1),(a0)+
		move.b	d0,(a1)+
		dbf	d6,.loop

.checkend	movem.l	A2-A6,-(sp)		; preseve regs
		lea	complete(pc),a2		; link complete
		cmp	#1,(a2)			; complete?
		bne	.skip

		clr	(a2)			; remove complete 
		move.l	#$454E4420,-8(a1)	; round END
      
.skip		lea	version(pc),a3		; check version
		cmp	#2,(a3)
		beq	.ver2       

.ver1		movem.l	(sp)+,a2-a6		; reg restore
		movem.l	(a7)+,a0-a1		; original code
		jmp	$4714

.ver2		movem.l	(sp)+,a2-a6		; reg restore
		movem.l	(a7)+,a0-a1		; original code
		jmp	$46D6


; *** 2 button support - launch jump (HH)
_jump		movem.l	D1/A1,-(A7)		; preserve reg
		bclr	#2,d0			; clear original

.go		lea   button_held(pc),a1	; read "held"

		move.w   $DFF016,d1		; read joypad
		btst  #14,d1			; test for blue
		bne   .clear			; not true, skip routine

		cmp   #1,(a1)			; held
		beq   .exit 
         
		move  #1,(a1)			; set as held
		bset  #2,d0			; set jump!
		bra   .exit 

.clear		clr.l (a1)			; clear button held

.exit		movem.l  (A7)+,D1/A1		; restore reg  
		rts


; *** 2 button support - hold jump (HH)
_hold		movem.l	D1/A1,-(A7)	; preserve reg
		bclr	#2,d0		; clear original

		move.w	$DFF016,d1	; read joypad
		btst	#14,d1		; test for blue
		bne.b	.exit		; not true, skip routine
      
		bset	#2,d0		; set held! 

.exit		movem.l  (A7)+,D1/A1	; restore reg
   		rts


; *** 2 button support - rider up (HH)

_ride		movem.l  D1/A1,-(A7)    ; preserve reg

		tst.w	$66(a6)		; "joystick" collected
		bne	.exit		; so act as normal
      
		cmpi.w	#$29,$1c(a4)	; little spaceship thing
		beq	.exit		; so act as normal
      
		bclr	#2,d7		; clear original button
      
		move.w	$DFF016,d1	; read joypad
		btst	#14,d1	; test for blue
		bne.b	.exit	; not true, skip outine

		bset	#2,d7	; set jump!

.exit   	movem.l  (A7)+,D1/A1    ; restore reg
		rts
      

; *** inserted joystick jump routines (HH)
jump_patch: 
		bsr	_jump 
		bclr	#7,d0    ; original code
		rts

hold_patch: 
		bsr	_hold
		btst	#2,d0    ; original code
		rts

ride_patch: 
		bsr	_ride
		btst	#2,d7    ; original code
		rts


; *** inserted blitter waits (JOTD)

wait_blit_D0A2:
  		 bsr		wait_blit
  		 move.w		D0,($58,A2)
  		 rts
   
wait_blit_D2A5:
		bsr		wait_blit
		move.w		D2,($58,A5)
		rts


wait_blit
	;TST.B dmaconr+$DFF000
	;BTST  #6,dmaconr+$DFF000
	;BNE.S .wait
	;bra.s .end
.wait
	;TST.B $BFE001
	;TST.B $BFE001
	;BTST  #6,dmaconr+$DFF000
	;BNE.S .wait
	;TST.B dmaconr+$DFF000
.end   
	BLITWAIT    ; WHDload macro (HH)
	rts


; *** the read track routine (JOTD)

read_tracks:
	movem.l	D0-d7/a0-A6,-(a7)
	and.l	#$FFFF,D0
	and.l	#$FFFF,D1

	mulu	#$B,D0
	add.l	D0,D0
	lsl.l	#8,D0    ; * $1600: offset

	mulu	#$B,D1
	add.l	D1,D1
	lsl.l	#8,D1    ; * $1600 (length)

	moveq.l	#1,D2    ; 1 disk only
	move.l	_resload(pc),a2
	jsr	resload_DiskLoad(a2)

	movem.l	(a7)+,D0-d7/a0-A6
	moveq	#0,D0    ; always return 0 (no error)
	rts

kb_int:
	move.b   $BFEC01,D0  ; original game
	move.l   D0,-(sp)
	ror.b #1,D0
	not.b D0

	cmp.b _keyexit(pc),D0
	beq	_exit

	cmp.b _keydebug(pc),D0
	bne	.next
	move.l	(a7)+,d0
	move.w	(a7),(6,a7)	;sr
	move.l	(2,a7),(a7)	;pc
	clr.w	(4,a7)		;ext.l sr
	bra	_debug		;coredump & quit

.next	;cmp.b	#$42,D0
	;bne	.noquit
	;clr.b	d0
	;jump	BASE_ADDRESS	; restart game


.noquit
   	movem.l  D1,-(a7)

	;  move.l	custom4(pc),d1    ; CUSTOM3 tooltype (2 button
	;  cmp		#0,d1
	;  beq		.nosound
	;  cmp		#$c,d0  
	;  bgt		.nosound
	;  bsr		_soundtest

.nosound
	movem.l	(sp)+,D1
	move.l	(sp)+,D0
	rts


; WHD-EXIT CODE
;============================================================================
_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
_end		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts


; *** sound test (HH)

; _soundtest
;
;  movem.l  a0,-(sp)
;  lea   version(pc),a0    ; link version
;
;  cmp   #2,(a0)
;  beq   .exit
;
;  movem.l  (sp)+,a0
;  jsr   $BB46       ; ver 1 play sound
;
;  bra   .exit
;
;.v2  movem.l  (sp)+,a0
;  jsr   $BDC0       ; ver 2 play sound
;
;.exit   rts



; *** decrunch routine (JOTD)
; *** re-sourced from the game and relocated
; *** in fast memory for better speed

decrunch:
   MOVEM.L  D0-D3/A0-A2,-(A7) ;71E: 48E7F0E0
   MOVE.L   A0,-(A7)    ;722: 2F08
   MOVEA.L  A0,A1       ;724: 2248
   MOVE.L   (A1)+,D3    ;726: 2619
   MOVE.L   (A1)+,D1    ;728: 2219
   ADDA.L   D1,A1       ;72A: D3C1
   ADDQ.L   #1,A1       ;72C: 5289
   ADDA.L   D3,A0       ;72E: D1C3
   ADDQ.L   #1,A0       ;730: 5288
LAB_003B:   
   MOVE.B   -(A1),-(A0)    ;732: 1121
   SUBQ.L   #1,D1       ;734: 5381
   BPL.S LAB_003B    ;736: 6AFA
   EXG   A1,A0       ;738: C348
   MOVEA.L  (A7)+,A0    ;73A: 205F
   MOVE.B   (A1)+,D2    ;73C: 1419
LAB_003C:
   MOVE.B   (A1)+,D0    ;73E: 1019
   CMP.B D0,D2       ;740: B400
   BEQ.S LAB_003D    ;742: 6708
   MOVE.B   D0,(A0)+    ;744: 10C0
   SUBQ.L   #1,D3       ;746: 5383
   BPL.S LAB_003C    ;748: 6AF4
   BRA.S LAB_003F    ;74A: 6012
LAB_003D:
   CLR   D1       ;74C: 4241
   MOVE.B   (A1)+,D0    ;74E: 1019
   MOVE.B   (A1)+,D1    ;750: 1219
LAB_003E:
   MOVE.B   D0,(A0)+    ;752: 10C0
   SUBQ.L   #1,D3       ;754: 5383
   DBF   D1,LAB_003E    ;756: 51C9FFFA
   TST.L D3       ;75A: 4A83
   BPL.S LAB_003C    ;75C: 6AE0
LAB_003F:
   MOVEM.L  (A7)+,D0-D3/A0-A2 ;75E: 4CDF070F
   RTS            ;762: 4E75

_Menu		movem.l	D0-d7/a0-A6,-(A7)		; preserve reg
		
	;	move.l	custom4(pc),d0	 	 ; CUSTOM4 tooltype 
	;	tst.l	d0			 ; if active
	;	beq	.exit1

		lea	reload(pc),a0
		cmp.b	#$FF,$2FF
		bne	.exit2

.exit1		movem.l	(A7)+,D0-d7/a0-A6	; restore regs
		lea	$3174(pc),a0		; original code
		moveq	#$F,d1
		rts

.exit2		move.b	#$FF,$2FF
		waitvb
		movem.l	(A7)+,D0-d7/a0-A6	; restore regs		
		JMP	BASE_ADDRESS



; *** load / save highscores (HH)

_savescore	
		movem.l	D0-d7/a0-A6,-(A7)		; preserve reg
		move.l	_resload(PC),A2
		move.l	#$60,D0			; data length
		moveq.l	#0,D1			; offset of zero
		lea	_savename(pc),A0	; filename
		lea   version(pc),a4
		cmp   #2,(a4)			; check version
		beq   .ver2save
.ver1save
		lea	$4828,A1		; position of ver 1 scores
		cmp.w	#$3E8,$4FBA		; Check in-game cheat active ver 1
		beq.b	.skip			; dont save if active
		bra	.save

.ver2save
		lea   $47E0,A1			; position of ver 2 scores
		cmp.w  #$3E8,$4F48		; Check in-game cheat active ver 2
		beq.b .skip			; dont save if active

.save		jsr	(resload_SaveFileOffset,a2)   

.skip		cmp   #2,(a4)		; check version
		beq   .ver2exit
	
.ver1exit	movem.l	(A7)+,D0-d7/a0-A6	; restore regs
		jmp	$C8BE			; goto normal score-entry end

.ver2exit
		movem.l	(A7)+,D0-d7/a0-A6	; restore regs
		jmp	$C6A8			; goto normal score-entry end



_loadscore  
	movem.l	D0-d7/a0-A6,-(A7)		; store registers
	lea	(_savename,pc),A0
	move.l	(_resload,pc),a2
	jsr	(resload_GetFileSize,a2)	; get highscore filesize
	tst.l	d0				; check exists
	beq	.skip				; skip loadscore

	move.l	_resload(PC),A2
	move.l	#$60,D0				;data length
	moveq.l	#0,D1				;offset of zero
	lea	_savename(pc),A0		;filename
            
	lea	version(pc),a3			; link version
	cmp	#2,(a3)				; check for version 2
	beq	.ver2

.ver1	lea	$4828,a1			; ver1 highscore position
	bra	.jump

.ver2	lea	$47E0,a1			; ver2 highscore position

.jump	jsr	(resload_LoadFileOffset,a2)	; Load scores

.skip	movem.l	(A7)+,D0-d7/a0-A6       		; register restore
	rts


; *** set game start lives - to allow levelskip (HH)

_startlives_v1
		clr.w		8(a6)			; orig code
		move.w		defaultlives(pc),d0	; set lives
		jmp		$4fbc      		; return to code

_startlives_v2   
		clr.w		8(a6)			; orig code
		move.w		defaultlives(pc),d0  	; set lives
		jmp		$4f4A			; return to code


; *** in game cheat activated - to allow levelskip (HH)
_cheat_v1	move.w		#$3E8,$4FBA		; activate levelskip
		bsr		_cheat_share
		jmp		$b7bc			; return to code

_cheat_v2      	move.w		#$3E8,$4F48 		; activate levelskip
		bsr		_cheat_share
        	jmp		$BA3C			; return to code

_cheat_share	movem.l		A0,-(A7)		; preserve regs      
		lea		defaultlives(pc),a0	; link lives
		move.w		#$3E8,(a0)		; set lives 1000
		movem.l		(A7)+,A0		; restore regs
		rts


; *** PATCHLISTS

pl_boot

   PL_START

   ; *** install quit key
   PL_PS $1308,kb_int

   ; *** fix for 68000
	PL_PS	$2AB0,_Menu

   ; *** install in-game load
   PL_P  $C24,read_tracks

   ; *** remove exception vectors patch
   PL_W  $5B6,$6018

   ; *** patch cia/disk stuff
   PL_R  $9DA

   PL_P  $C6,wait_blit_D0A2
   PL_P  $CC,wait_blit_D2A5
   PL_P  $CC,wait_blit_D2A5

   ; *** patch joystick second button routines (HH)
   PL_P  $D2,jump_patch
   PL_P  $D8,hold_patch
   PL_P  $DE,ride_patch

   ; ***  emulator with no sound fix. (HH)  
 ;  PL_W  $F002,$6008    
   
   ; *** flushes caches and start

   PL_L  $24,$f974db7d        ;RN diskkey (Abaddon)

   PL_END


pl_boot_v1
   PL_START

   ; *** patch blitter waits (JOTD)
   
	PL_L  $C1C4,$4EB800C6
	PL_L  $C1DE,$4EB800C6
	PL_L  $C1F8,$4EB800C6
	PL_L  $C218,$4EB800C6

	PL_L  $BDCA,$4EB800CC
	PL_L  $C27A,$4EB800CC
   
   ; *** score related bugfixes (HH)

	PL_P  $B76C,_endgame   ; use "Game Over" buttonwait on outro
	PL_B  $492F,$02     ; limit name-entry delete to 3 characters
	PL_W  $494A,$600E   ; make both score-entry ends the same         
	PL_P  $4700,_endround     ; enter "END" for round if complete
	PL_P  $495A,_savescore  ; score-saving routine  

   ; ***   levelskip bypasses

	PL_P  $4Fb4,_startlives_v1 ; for setting no, of lives
	PL_P  $B7B4,_cheat_v1      ; for activating cheat 

	PL_NEXT  pl_boot


pl_boot_v2
   PL_START
      
  ; *** patch blitter waits (JOTD)

	PL_L	$B8F4,$4EB800C6
	PL_L	$B90E,$4EB800C6
	PL_L	$B928,$4EB800C6
	PL_L	$B948,$4EB800C6

	PL_L	$C042,$4EB800CC
	PL_L	$B9AA,$4EB800CC

  ; *** score-related bugfixes (HH)
	PL_P	$B9E8,_endgame		; use "Game Over" buttonwait on outro
	PL_B	$48E7,$02		; limit name-entry delete to 3 characters
	PL_P	$46C2,_endround		; enter "END" for round if complete
	PL_W	$4902,$600E		; make both score-entry ends the same
	PL_P	$4912,_savescore	; score-saving routine

  ; ***   levelskip bypasses
	PL_P	$4F42,_startlives_v2 ; for setting no, of lives
	PL_P	$BA34,_cheat_v2      ; for activating cheat 
	PL_NEXT	pl_boot


; *** CUSTOM tooltypes

pl_arcade_control_v1
	PL_START 			; *** 2 button support (HH)
	PL_L  $935A,$4EB800D2	; first jump routine
	PL_L  $9530,$4EB800D8	; hold jump routine
	PL_L  $9024,$4EB800DE	; up on rider routine
	PL_END

pl_arcade_control_v2
	PL_START			; *** 2 button support (HH)
	PL_L  $9210,$4EB800D2	; first jump routine
	PL_L  $93DA,$4EB800D8	; hold jump routine   e
	PL_L  $8EDA,$4EB800DE	; up on rider routine
	PL_END
  
pl_trainer_lives_v1
	PL_START		; *** remove life decrements  
	PL_W $79C8,$4A6E
	PL_W $8A72,$4A6E
	PL_W $8B2E,$4A6E
	PL_W $8BEE,$4A6E
	PL_W $990A,$4A6E
	PL_END

pl_trainer_lives_v2
	PL_START		; *** remove life decrements  
	PL_W $787E,$4A6E
	PL_W $8928,$4A6E
	PL_W $89E4,$4A6E
	PL_W $8AA4,$4A6E
	PL_W $97B4,$4A6E
	PL_END

pl_trainer_oxygen_v1
	PL_START		; *** remove oxygen decrement
	PL_W $9922,$4A6E
	PL_END

pl_trainer_oxygen_v2
	PL_START		; *** remove oxygen decrement
	PL_W $97CC,$4A6E
	PL_END




; ================
_resload	dc.l  0
_tags		dc.l  WHDLTAG_CUSTOM1_GET
custom1		dc.l  0
		dc.l  WHDLTAG_CUSTOM2_GET
custom2		dc.l  0
		dc.l  WHDLTAG_CUSTOM3_GET
custom3		dc.l  0
		dc.l  WHDLTAG_CUSTOM4_GET
custom4		dc.l  0
	dc.l	0
defaultlives	dc.w  3
version		dc.w  0
complete	dc.w  0
reload		dc.w  0
button_held	dc.w  0
CPU		dc.l  0 
		EVEN
		dc.l  0


