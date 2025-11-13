    IFD     BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
    ENDC
DECL_VERSION:MACRO
	dc.b	"2.2"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM    
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$0
    even
    
TEST_BUTTON:MACRO
    btst    #JPB_BTN_\1,d0
    beq.b   .no\1\3
    btst    #JPB_BTN_\1,d1
    beq.b   .\1_just_pressed\3
    ; got to release space!
	move.b	#$00,(a5,d2.w)		;805fe: 0c2d001b07fd
    bra.b   .no\1\3
.\1_just_pressed\3:
	move.b	#$\2,(a5,d2.w)		;805fe: 0c2d001b07fd
.no\1\3
    ENDM
    
JOY_FUNCS:MACRO

_pause_test_\1
    CMPI.B	#$50,\2(A5)
    beq.b   .p_pressed
    movem.l d0,-(a7)
    move.l  joy0(pc),d0
    btst    #JPB_BTN_PLAY,d0
    bne.b   .press_neg
    move.l  joy1(pc),d0
    btst    #JPB_BTN_PLAY,d0
    bne.b   .press_neg
    moveq.l #1,d0   ; unset Z
.press
    movem.l (a7)+,d0
    rts
.press_neg
    cmp.b   d0,d0   ; set Z
    bra.b   .press    
.p_pressed
    rts
    
; test for quit with keyboard or joypad
_joypad_buttons_loop_\1:
    movem.l d0-d3/a0,-(a7)
    move.w  #\2,d2
    lea _previous_joystate_0(pc),a0
    move.l  (a0),d3
    move.l  joy0(pc),(a0)


    lea _previous_joystate_1(pc),a0
    move.l  (a0),d1
    move.l  joy1(pc),d0
    move.l  d0,(a0)
    
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .noquit
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noquit
    btst    #JPB_BTN_YEL,d0
    beq.b   .noyel
    cmp.b   d0,d0   ; to set Z
    bra   .out
.noyel
    btst    #JPB_BTN_GRN,d0
    beq.b   .noquit
    bra _exit
.noquit
    TEST_BUTTON BLU,20,p1
    TEST_BUTTON YEL,15,p1
    ; player 1 can change player 2 ability
    ; even in 2 player mode
    TEST_BUTTON GRN,16,p1
    ; player 2
    move.l  d3,d1
    move.l  joy0(pc),d0
    TEST_BUTTON BLU,20,p2
    TEST_BUTTON YEL,16,p2
    ;;TEST_BUTTON GRN,16    ; no need to pester player 1 with that!
    
    ; original test for ESC
	CMPI.B	#$1b,(a5,d2.w)
.out
    movem.l (a7)+,d0-d3/a0
    rts
    
    ENDM

; level 3 during game
_level3_interrupt_hook:
	LEA	_custom,A3		;: 47f900dff000
	BTST	#5,31(A3)		;83dca: 082b0005001f
	BEQ.W	.noblank		;83dd0: 67000194
    ; read joypad in vblank: solves multi-read/spurious reads
    bsr _joystick

.noblank:
    rts
 
_level_loaded
.w
    btst    #6,$bfe001
    beq.b   .o
    btst    #7,$bfe001
    bne.b   .w
.o
    MOVE.W	D0,D1			;832bc: 3200
	ADDI.W	#$0031,D1		;832be: 06410031
    rts
    

    
set_lives
	move.w	#$63,$50(A5)		; 99 lives player 1
	move.w	#$63,$52(A5)		; 99 lives player 2
	rts
; len is useless +B670  MOVE.W D1,(A5,$0ff8)

; < A1: destination
restore_password:
	movem.l	d0-d4/a0-a3,-(a7)
    move.l  a1,a0   ; destination
	; enter password if set
	move.l	#11,d0	; len
	lea	password(pc),a1
	tst.b	(a1)
	beq.b	.zero
	
	lea	code_letters(pc),a2
	lea	code_values(pc),a3

.loop
	move.b	(a1)+,d4	; letter from user code
	moveq.l	#0,d2
.lookup
	move.b	(a2,d2.w),d3	; letter from table
	beq.b	.out
	cmp.b	d3,d4
	beq.b	.match
	addq.l	#1,d2
	bra.b	.lookup
.match
	; index + $15
	move.b	(a3,d2.w),(a0)+	; store decoded in destination
	dbf	d0,.loop
.out
	movem.l	(a7)+,d0-d4/a0-a3
	rts
.zero:
	; clear zone, no password passed
    ; this isn't necessary
	;move.b	#$3E,(a0)+
	;dbf	d0,.zero
	bra.b	.out
password:
	ds.b	14,0
code_letters:
	dc.b	"BCDFGHJKLMNPQRSTVWXYZ0123456789#",0
code_values:
    ;		B   C   D   F   G   H   J   K   L   M   N   P   Q   R   S   T   V   W   X   Y   Z
    dc.b	$15,$16,$17,$19,$1A,$1B,$1D,$1E,$1F,$20,$21,$23,$24,$25,$26,$27,$29,$2A,$2B,$2C,$2D
	;       0   1   2   3   4   5   6   7   8   9   #
	dc.b	$2F,$30,$31,$32,$33,$34,$35,$36,$37,$38,$3A


    even
