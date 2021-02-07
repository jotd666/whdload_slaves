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
;     Ver.1 is the common "FLUFFYKIWIS" version (SPS 1180)
;     Ver.2 is the original "MOTHERFUCKENKIWIBASTARD" version (SPS 2875)
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
		dc.w  WHDLF_NoError|WHDLF_ClearMem	;ws_flags
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
		dc.b    "C1:X:Enable Single Key Cheat Activation:3;"
		dc.b    "C2:B:Enable 2 Button Support;"
        dc.b    "C4:L:Start level:1_1,1_2,1_3,1_4,2_1,2_2,2_3,2_4,3_1,3_2,3_3,3_4,"
                dc.b    "4_1,4_2,4_3,4_4,5_1,5_2,5_3,5_4;"
        dc.b    "BW;"
		dc.b    0
	

;============================================================================

 	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

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

_name    dc.b  "The New Zealand Story"
      dc.b  0
_copy    dc.b  "1988 Ocean",0
_info    dc.b  "Adapted & fixed by JOTD & Abaddon",10
      dc.b  "Additions by Hungry Horace, fixes by Stingray",10,10
      dc.b  "Version "
      DECL_VERSION
      dc.b  0
_savename   dc.b  "NewZealandStory.highs",0
      dc.b  0


; version xx.slave works

   dc.b  "$","VER: slave "
   DECL_VERSION
   dc.b  0

    even
    
    include     ReadJoyPad.s
    
BASE_ADDRESS = $400



;======================================================================
start ;  A0 = resident loader
;======================================================================

      lea	_resload(pc),a1
      move.l   a0,(a1)        ;save for later use
      move.l   a0,a2
      
      lea   (_tags,pc),a0
      jsr   (resload_Control,a2)

      bsr   _detect_controller_types
      
      lea   CHIPMEMSIZE-$100,a7
      move.w   #$2700,SR

      ; I slightly cheated to skip the first copylock at boot
      ; after this it loads at $400 then transfers to $76000
      lea   $76000-$4,A0
      move.l   #$5A,D0
      move.l   #$1,D1
      bsr   read_tracks
      
      lea   $76000,a1
      lea   pl_boot_76000(pc),a0
      move.l    _resload(pc),a2
      jsr   resload_Patch(a2)
      
      jmp   $7600C
next_part:
      ; we could have used the code at 76668 (after the copylock)
      ; with proper copylock key in D0 = F974DB7D but in the previous slave
      ; version I had already skipped that part. Putting the 76000 part back in
      ; was only to be able to display title picture
      ; so after having displayed the pic, we just jump back here (after waiting
      ; for fire button)
      move.l    #20,d0  ; 2 seconds
      move.l    _resload(pc),a2
      jsr   resload_Delay(a2)
      
      move.l    buttonwait(pc),d0
      beq.b .nobw
.wf
    move.b  $BFE001,d0
    and.b   #$C0,d0
    cmp.b   #$C0,d0
    beq.b   .wf
.nobw
      
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
   ; this was probably to make up for the RN copy protection boot
   ; sequence that I (jotd) cowardly skipped

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
	move  #1,(a3)			; assume version 1 (SPS 1180)
   
	cmp.l #$35400058,$C1C4		; check version
	beq   .v1

	lea   pl_boot_v2(pc),a0
	move  #2,(a3)			; it is version 2 (SPS 2875)

.v1	move.l   _resload(pc),a2
	jsr   resload_Patch(a2)

	bsr   _loadscore		; load scoreboard
	waitvb

	jmp   BASE_ADDRESS		; begin game

pl_boot_76000:
    PL_START
    PL_R    $798        ; floppy shit
    PL_R    $764        ; floppy shit
    PL_R    $9d2        ; floppy shit
    PL_P    $698,read_tracks
    PL_P    $064,next_part
    PL_END
    
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

        move.l  joy1(pc),d1
		btst  #JPB_BTN_BLU,d1			; test for blue
		beq   .clear			; not true, skip routine

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

		move.l  joy1(pc),d1
		btst  #JPB_BTN_BLU,d1			; test for blue
		beq   .exit			; not true, skip routine
      
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
      
		move.l  joy1(pc),d1
		btst  #JPB_BTN_BLU,d1			; test for blue
		beq.b	.exit	; not true, skip outine

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

	mulu.w	#512*11,d0
	mulu.w	#512*11,d1
	moveq.l	#1,D2    ; 1 disk only
	move.l	_resload(pc),a2
	jsr	resload_DiskLoad(a2)

	movem.l	(a7)+,D0-d7/a0-A6
	moveq	#0,D0    ; always return 0 (no error)
	rts

; < D0: ciaa sdr contents
kb_int:
	
	move.l   D0,-(sp)
    BSET	#6,$bfee01
    ; keyboard handshake
	move.w  d0,-(a7)
	move.w	#4,d0
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	move.w	(a7)+,d0
    BCLR	#6,$bfee01
 	    
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
_exit		pea	(TDREASON_OK).w
		bra.b	_end
_debug		pea	(TDREASON_DEBUG).w
_end		move.l	(_resload,pc),-(a7)
		addq.l	#resload_Abort,(a7)
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
		cmp.b	#$FF,$2FF.w
		bne.b	.exit2

.exit1		movem.l	(A7)+,D0-d7/a0-A6	; restore regs
		lea	$3174.W,a0		; original code
		moveq	#$F,d1
		rts

.exit2		move.b	#$FF,$2FF.w
	bsr.b	WaitRaster
		movem.l	(A7)+,D0-d7/a0-A6	; restore regs		
		JMP	BASE_ADDRESS


WaitRaster
.wait	btst	#0,$dff005
	beq.b	.wait
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts

; *** load / save highscores (HH)

_savescore	
		movem.l	D0-d7/a0-A6,-(A7)		; preserve reg
        move.l  trainer(pc),d0
        bne.b   .skip               ; no save if trainer
        move.l  startlevel(pc),d0
        bne.b   .skip               ; no save if trainer
		move.l	_resload(PC),A2
		moveq	#$60,D0			; data length
		moveq.l	#0,D1			; offset of zero
		lea	_savename(pc),A0	; filename
		lea   version(pc),a4
		cmp.w	#2,(a4)			; check version
		beq.b	.ver2save
.ver1save
		lea	$4828.w,A1		; position of ver 1 scores
		cmp.w	#$3E8,$4FBA.w		; Check in-game cheat active ver 1
		beq.b	.skip			; dont save if active
		bra.b	.save

.ver2save
		lea	$47E0.w,A1		; position of ver 2 scores
		cmp.w	#$3E8,$4F48.w		; Check in-game cheat active ver 2
		beq.b .skip			; dont save if active

.save		jsr	(resload_SaveFileOffset,a2)   

.skip		
        cmp   #2,(a4)		; check version
        movem.l	(A7)+,D0-d7/a0-A6	; restore regs
		beq.b   .ver2exit
	
.ver1exit	
		jmp	$C8BE			; goto normal score-entry end

.ver2exit
		jmp	$C6A8			; goto normal score-entry end



_loadscore  
	movem.l	D0-d7/a0-A6,-(A7)		; store registers
	lea	(_savename,pc),A0
	move.l	(_resload,pc),a2
	jsr	(resload_GetFileSize,a2)	; get highscore filesize
	tst.l	d0				; check exists
	beq.b	.skip				; skip loadscore

	move.l	_resload(PC),A2
	moveq	#$60,D0				;data length
	moveq	#0,D1				;offset of zero
	lea	_savename(pc),A0		;filename
            
	lea	version(pc),a3			; link version
	cmp	#2,(a3)				; check for version 2
	beq.b	.ver2

.ver1	lea	$4828.w,a1			; ver1 highscore position
	bra.b	.jump

.ver2	lea	$47E0.w,a1			; ver2 highscore position

.jump	jsr	(resload_LoadFileOffset,a2)	; Load scores

.skip	movem.l	(A7)+,D0-d7/a0-A6       		; register restore
	rts


; set game start lives - to allow levelskip without setting 1000 lives (HH)
; infinite lives is a separate trainer option now
; JOTD added start level there

_startlives
		move.w		defaultlives(pc),d0	; set lives
        MOVE.W	D0,26(A6)		;04fbc: 3d40001a

		move.l		startlevel(pc),d0
        beq.b   .normalstart
        lsl.w #4,d0     ; level is like $00, $10, $20, $30, ...
        move.w  d0,44(a6)			; start level
.normalstart
        MOVE.W	44(A6),8(A6)		; copy start level to current level
		rts


; *** in game cheat activated - to allow levelskip (HH)
_cheat_v1	move.w		#$3E8,$4FBA.w		; activate levelskip
		bsr		_cheat_share
		jmp		$b7bc			; return to code

_cheat_v2      	move.w		#$3E8,$4F48.w 		; activate levelskip
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
   PL_PSS      $2A92,fire_test,2

   ; *** install quit key
   PL_PSS   $130E,kb_int,2
   PL_W    $01338,$4E73     ; remove handshake
   PL_NOP   $01342,8     ; remove handshake
   
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
   ; regulation
   
   PL_PS    $42A2,mainloop_hook
   
   ; install vbl hook
   
   PL_PSS     $0bb6a,vbl_hook,2
   
   ; fix end screen (self-modifying code)
   PL_PS    $B260,store_a1
   PL_PS    $B26A,get_d3
   
   ; audio fix, don't seem to fix the high pitches
   ; probably only audible in winuae with chipsethack...
   
   ;;PL_PS    $EFC8,dma_wait
   
   ; ** levelskip with joypad too
   PL_PS    $043f6,check_skip_key

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

	PL_PSS  $4FbC,_startlives,4 ; for setting no, of lives / start level
	PL_P  $B7B4,_cheat_v1      ; for activating cheat 


    PL_IFC2
	PL_L  $935A,$4EB800D2	; first jump routine
	PL_L  $9530,$4EB800D8	; hold jump routine
	PL_L  $9024,$4EB800DE	; up on rider routine
    PL_ENDIF

    PL_IFC1X    0
	PL_W $79C8,$4A6E
	PL_W $8A72,$4A6E
	PL_W $8B2E,$4A6E
	PL_W $8BEE,$4A6E
	PL_W $990A,$4A6E
    PL_ENDIF

    PL_IFC1X    1
	PL_W $9922,$4A6E
    PL_ENDIF

    PL_IFC1X    2
    PL_W    $4FBA,$3E8,	; *** levelskip on v1   
    PL_ENDIF
   
    PL_IFC1X    3
	PL_W   $B794,$601E,	; *** easier original cheat (JOTD)  
    PL_ENDIF
    
	PL_NEXT  pl_boot

       

pl_boot_v2
   PL_START
   PL_PSS     $0bde2,vbl_hook,2

   PL_PS    $04298,mainloop_hook

   ; fix end screen (self-modifying code)
   PL_PS    $0b09e,store_a1
   PL_PS    $0b0a8,get_d3
   
   ; ** levelskip with joypad too
   PL_PS    $043e6,check_skip_key

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
	PL_P	$4f4a,_startlives ; for setting no, of lives
	PL_P	$BA34,_cheat_v2      ; for activating cheat 

    PL_IFC2
	PL_L  $9210,$4EB800D2	; first jump routine
	PL_L  $93DA,$4EB800D8	; hold jump routine   e
	PL_L  $8EDA,$4EB800DE	; up on rider routine
    PL_ENDIF

    PL_IFC1X    0
	PL_W $787E,$4A6E
	PL_W $8928,$4A6E
	PL_W $89E4,$4A6E
	PL_W $8AA4,$4A6E
	PL_W $97B4,$4A6E
    PL_ENDIF

    PL_IFC1X    1   ; *** remove oxygen decrement
	PL_W $97CC,$4A6E
    PL_ENDIF

    PL_IFC1X    2
    PL_W    $4F48,$3E8,	; *** 1000 lives means levelskip on v2   
    PL_ENDIF
    
    PL_IFC3
	PL_W   $BA0A,$6028   	; *** easier original cheat (HH) 
    PL_ENDIF
    
	PL_NEXT	pl_boot

; returns Z flag if not level skip

check_skip_key
    movem.l d0,-(a7)
    jsr $404.W
    bne.b   .levelskip
    move.l  joy1(pc),d0
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .levelskip
    btst    #JPB_BTN_GRN,d0
.levelskip
    movem.l (a7)+,d0
    rts
    
    
store_a1:
    move.l  a0,-(a7)
    lea a1_value(pc),a0
    move.l  a1,(a0)
    move.l  (a7)+,a0
    rts
    
get_d3:
    move.l  a0,-(a7)
    move.l a1_value(pc),a0
    move.w  (a0),d3
    move.l  (a7)+,a0
    rts
    
dma_wait
    MOVE.W D0,(A6,$0096)
    MOVE.W D0,D1
	move.w  d0,-(a7)
	move.w	#7,d0
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	;;;addq.l	#2,(a7)  harmful if not used with PSS!!
	move.w	(a7)+,d0
    rts
    
fire_test
    movem.l d1,-(a7)
    move.l  joy1(pc),d1
    not.l   d1
    btst    #JPB_BTN_RED,d1
    movem.l (a7)+,d1
    rts
    
PAUSE_RAWKEY = $3177

mainloop_hook:
    bsr vbl_reg
    ; pause test from keyboard
    btst    #1,PAUSE_RAWKEY
    beq.b   .nopause
.norel
    btst    #1,PAUSE_RAWKEY
    bne.b   .norel
.norel2
    btst    #1,PAUSE_RAWKEY
    beq.b   .norel2
.norel3
    btst    #1,PAUSE_RAWKEY
    bne.b   .norel3
    
.nopause
    movem.l d0,-(a7)
    ; pause test from joypad
    move.l  joy1(pc),d0
    btst    #JPB_BTN_PLAY,d0
    beq.b   .nopause_joy
.norel_joy
    move.l  joy1(pc),d0
    btst    #JPB_BTN_PLAY,d0
    bne.b   .norel_joy
.norel_joy2
    move.l  joy1(pc),d0
    btst    #JPB_BTN_PLAY,d0
    beq.b   .norel_joy2
.norel_joy3
    move.l  joy1(pc),d0
    btst    #JPB_BTN_PLAY,d0
    bne.b   .norel_joy3
.nopause_joy
    movem.l (a7)+,d0
    ; original code
	TST.W	84(A6)			;042a2: 4a6e0054
	BNE.S	.noskip
    add.l   #$1E,(a7)    
.noskip
   rts
   
vbl_reg:    
    movem.l d0-d1/a0-a1,-(a7)
    moveq.l #1,d1       ; the bigger the longer the wait
    lea vbl_counter(pc),a0
    move.l  (a0),d0
    cmp.l   #10,d0
    bcc.b   .nowait     ; first time called/lost sync/pause/whatever
    ; wait till at least x vblanks passed after last zeroing
.wait
    cmp.l   (a0),d1
    bcc.b   .wait
.nowait
    clr.l   (a0)
    movem.l (a7)+,d0-d1/a0-a1
    rts
    

vbl_hook
    bsr _joystick
    movem.l d0,-(a7)
    move.l  joy1(pc),d0
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .noquit
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noquit
    btst    #JPB_BTN_YEL,d0
    bne   _exit
    
.noquit
    move.l  a0,d0   ; reuse d0 to save a0
    lea vbl_counter(pc),a0
    addq.l  #1,(a0)
    move.l  d0,a0
    
    movem.l (a7)+,d0
	BCLR	#7,$bfdf00
    rts
    

; ================
_resload	dc.l  0
_tags		dc.l  WHDLTAG_CUSTOM1_GET
trainer		dc.l  0
    dc.l    WHDLTAG_BUTTONWAIT_GET
buttonwait
    dc.l    0
	dc.l	WHDLTAG_CUSTOM4_GET
startlevel
    dc.l    3
    dc.l    0
    
    
vbl_counter dc.l    0
defaultlives	dc.w  3

version		dc.w  0
complete	dc.w  0
reload		dc.w  0
button_held	dc.w  0
a1_value
    dc.l    0
		EVEN
		dc.l  0


