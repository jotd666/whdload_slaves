; Human-code full-lap fixture. The pilot supplies joystick directions only;
; it never writes steering, position, speed or condition. Record its field tape
; on period 6, then replay that same ignored tape on both periods.
verify_pilot_input:
    movem.l d2-d3/a1,-(sp)
    lea verify_pilot_field(pc),a0
    cmp.l (a0),d1
    beq .cached
    move.l d1,(a0)
    move.w -29516(a4),d2
    ext.l d2
    neg.l d2
    move.w -29526(a4),d3
    ext.l d3
    asr.l #3,d3
    sub.l d3,d2
    move.w -29522(a4),d3
    ext.l d3
    asr.l #1,d3
    sub.l d3,d2
    move.w -29976(a4),d3
    ext.l d3
    sub.l d3,d2
    move.w -29528(a4),d3
    ext.l d3
    sub.l d3,d2
    move.w #$0100,d0         ; accelerate below 70 mph
    cmp.w #70*256,-29944(a4)
    bcs.b .steer
    moveq #0,d0
    cmp.w #74*256,-29944(a4)
    bls.b .steer
    moveq #1,d0              ; brake above 74 mph
.steer
    cmp.l #88,d2
    bgt.b .left
    cmp.l #-88,d2
    bge.b .store
    cmp.w #$100,d0
    bne.b .right_slow
    move.w #$0103,d0
    bra.b .store
.right_slow
    tst.w d0
    bne.b .right_brake
    moveq #3,d0
    bra.b .store
.right_brake
    moveq #2,d0
    bra.b .store
.left
    cmp.w #$100,d0
    bne.b .left_slow
    move.w #$0200,d0
    bra.b .store
.left_slow
    or.w #$0300,d0
.store
    move.w d0,verify_pilot_value-verify_pilot_field(a0)
    cmp.l #12288,d1
    bcc.b .done
    lea verify_pilot_tape(pc),a1
    move.l d1,d3
    add.w d3,d3
    move.w d0,(a1,d3.w)
    bra.b .done
.cached
    move.w verify_pilot_value-verify_pilot_field(a0),d0
.done
    movem.l (sp)+,d2-d3/a1
    rts
verify_tape_input:
    moveq #0,d0
    cmp.l #12288,d1
    bcc.b .done
    lea verify_pilot_tape(pc),a0
    add.w d1,d1
    move.w (a0,d1.w),d0
.done
    rts
verify_pilot_field: dc.l -1
verify_pilot_value: dc.w 0
