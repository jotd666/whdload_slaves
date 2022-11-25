
main_loop
    st.b    MAINLOOP_FLAG.W     ; set flag to tell we're in mainloop
.wait
	TST.W	$f8
	BEQ.S	.wait		;1540fe: 67fa
    rts
    
; replace joystick UP by 2nd button
; returns JOY1DAT in D0, modified by button 2 press
; (up cancelled if button 2 not pressed)
; < nothing (uses buttons_state 32bit var)
; > D0: modified JOY1DAT
read_joy1dat_d0:
	movem.l	a0,-(a7)
	move.l	prev_buttons_state(pc),d0
	moveq.l	#0,d1
	move.w	(joy1dat,a6),D1
    tst.b   MAINLOOP_FLAG.W
    beq.b   .no_blue
    ; clear flag to tell the difference between in game
    ; and continue screen where up should be active
    clr.b   MAINLOOP_FLAG.W
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d1
	btst	#9,d1
	beq.b	.noneed
	bset	#8,d1	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d1
	btst	#9,d1
	bne.b	.no_blue
	bset	#8,d1	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
	move.l	d1,d0
	movem.l	(a7)+,a0
    rts
 
_flushcache
    movem.l a0,-(a7)
   move.l   _resload(pc),a0
   jsr  (resload_FlushCache,a0)
   movem.l  (a7)+,a0
   rts
   
Unsupported	pea	TDREASON_WRONGVER
    bra.b   _end
_quit
    pea TDREASON_OK
_end		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

 
;key table
TEST_BUTTON:MACRO
    btst    #JPB_BTN_\1,d2
    beq.b   .nochange_\1
    move.b  #\2,d3
    btst    #JPB_BTN_\1,d0
    bne.b   .pressed_\1
    clr.b  (a1,d3.w) ; store in keycode table
    bra.b   .nochange_\1
.pressed_\1
    st.b  (a1,d3.w) ; store in keycode table
.nochange_\1
    ENDM
    
Decrunch	
	MOVE.L	(4,A0),(A5)
	ADDA.L	D7,A0
	MOVEA.L	A1,A2
	MOVE.L	-(A0),D5
	MOVEQ	#0,D1
	MOVE.B	D5,D1
	LSR.L	#8,D5
	ADDA.L	D5,A1
	MOVE.L	A1,-(SP)
	MOVE.L	-(A0),D5
	LSR.L	D1,D5
	MOVEQ	#$1F,D7
	SUB.B	D1,D7
lab11	MOVEQ	#0,D1
	LSR.L	#1,D5
	ROXL.W	#1,D1
	DBRA	D7,lab12
	MOVEQ	#$1F,D7
	MOVE.L	-(A0),D5
lab12	TST.B	D1
	BNE.B	lab2
	MOVEQ	#0,D2
lab14	MOVEQ	#0,D1
	MOVEQ	#1,D0
lab15	LSR.L	#1,D5
	ROXL.L	#1,D1
	DBRA	D7,lab13
	MOVEQ	#$1F,D7
	MOVE.L	-(A0),D5
lab13	DBRA	D0,lab15
	ADD.W	D1,D2
	CMP.W	#3,D1
	BEQ.B	lab14
lab17	MOVEQ	#0,D1
	MOVEQ	#7,D0
lab18	LSR.L	#1,D5
	ROXL.L	#1,D1
	DBRA	D7,lab16
	MOVEQ	#$1F,D7
	MOVE.L	-(A0),D5
lab16	DBRA	D0,lab18
	MOVE.B	D1,-(A1)
	DBRA	D2,lab17
	CMPA.L	A1,A2
	BCS.B	lab2
	MOVE.L	(SP)+,D0
	ADDQ.L	#3,D0
	ANDI.L	#$FFFFFFFC,D0
	RTS

lab2	MOVEQ	#0,D1
	MOVEQ	#1,D0
lab21	LSR.L	#1,D5
	ROXL.L	#1,D1
	DBRA	D7,lab22
	MOVEQ	#$1F,D7
	MOVE.L	-(A0),D5
lab22	DBRA	D0,lab21
	MOVEQ	#0,D0
	MOVE.B	(A5,D1.W),D0
	MOVE.L	D0,D4
	MOVE.W	D1,D2
	ADDQ.W	#1,D2
	CMP.W	#4,D2
	BNE.B	lab3
	MOVEQ	#0,D1
	LSR.L	#1,D5
	ROXL.W	#1,D1
	DBRA	D7,lab23
	MOVEQ	#$1F,D7
	MOVE.L	-(A0),D5
lab23	MOVE.L	D4,D0
	TST.B	D1
	BNE.B	lab29
	MOVEQ	#7,D0
lab29	MOVEQ	#0,D1
	SUBQ.W	#1,D0
lab24	LSR.L	#1,D5
	ROXL.L	#1,D1
	DBRA	D7,lab25
	MOVEQ	#$1F,D7
	MOVE.L	-(A0),D5
lab25	DBRA	D0,lab24
	MOVE.W	D1,D3
lab28	MOVEQ	#0,D1
	MOVEQ	#2,D0
lab27	LSR.L	#1,D5
	ROXL.L	#1,D1
	DBRA	D7,lab26
	MOVEQ	#$1F,D7
	MOVE.L	-(A0),D5
lab26	DBRA	D0,lab27
	ADD.W	D1,D2
	CMP.W	#7,D1
	BEQ.B	lab28
	BRA.B	lab32

lab3	MOVEQ	#0,D1
	SUBQ.W	#1,D0
lab33	LSR.L	#1,D5
	ROXL.L	#1,D1
	DBRA	D7,lab31
	MOVEQ	#$1F,D7
	MOVE.L	-(A0),D5
lab31	DBRA	D0,lab33
	MOVE.W	D1,D3
lab32	MOVE.B	(A1,D3.W),-(A1)
	DBRA	D2,lab32
	CMPA.L	A1,A2
	BCS.W	lab11
	MOVE.L	(SP)+,D0
	ADDQ.L	#3,D0
	ANDI.L	#$FFFFFFFC,D0
	RTS
    
password_test
    moveq.l #0,d0
    move.b  (a0),d0
    sub.b  #'2',d0
    bmi.b   .skip
    cmp.b   #7,d0
    bcc.b   .skip
    add.w   d0,d0
    movem.l a0-a1,-(a7)
    lea levelcode_table(pc),a1
    move.w  (a1,d0.w),d0
    add.w   d0,a1
.copy
    move.b  (a1)+,d0
    beq.b   .out
    move.b  d0,(a0)+
    bra.b   .copy
.out    
    movem.l (a7)+,a0-a1
    
.skip
	CMPI.L	#CHEAT_TEST,(A0)		;: 0c904d723b50
    rts
    
levelcode_table:
    dc.w    l2-levelcode_table
    dc.w    l3-levelcode_table
    dc.w    l4-levelcode_table
    dc.w    l5-levelcode_table
    dc.w    cheat-levelcode_table
l2
    dc.b    "sXr7vgqaGP",0  ; The Spooky Ruins
l3
    dc.b    "sXqkKgqaGd",0  ; way forward
l4
    dc.b    "sXqkKgqaGI",0  ; graveyard
l5
    dc.b    "sXqkK0KaGU",0      ; eeeek
    even