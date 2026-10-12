; Measurement instruments only. Included exclusively by VERIFY builds.
; Offsets below are for the size-checked 94,708-byte executable.
; Requires WHDLoad 17.2+ for PL_IFC3/PL_IFC5 (tested with 20.0).
; CUSTOM3 pins only the beam contribution to the native RNG; CUSTOM5 returns
; raw JOY1DAT values indexed by native fields since the first gameplay loop.
; The attract driver remains native. This is a repeatable measurement fixture,
; not a player-handling oracle or a change to the six-field simulation period.
verify_race_start:
	movem.l d0/a0-a1,-(sp)
	lea verify_epoch(pc),a0
	move.l -31790(a4),(a0)
	lea verify_races(pc),a0
	move.l (a0),a1
	addq.l #1,a1              ; address arithmetic preserves the incoming X flag
	move.l a1,(a0)
	movem.l (sp)+,d0/a0-a1
	move.w #0,-31736(a4)       ; original instruction at h0:$707a
	rts

verify_read_joydat:
	movem.l d1/a0,-(sp)
	lea verify_joy_calls(pc),a0
	addq.l #1,(a0)
	moveq #0,d0               ; neutral until the first race
	move.l verify_races(pc),d1
	beq.b .done
	move.l -31790(a4),d1
	sub.l verify_epoch(pc),d1
	move.w #$0100,d0          ; accelerate
	cmp.l #100,d1
	bcs.b .done
	cmp.l #106,d1
	bcc.b .right
	move.w #$0200,d0          ; up + left
	bra.b .done
.right
	cmp.l #112,d1
	bcc.b .brake
	move.w #$0103,d0          ; up + right
	bra.b .done
.brake
	cmp.l #200,d1
	bcs.b .done
	cmp.l #300,d1
	bcc.b .coast
	moveq #1,d0               ; brake
	bra.b .done
.coast
	cmp.l #400,d1
	bcc.b .done
	moveq #0,d0               ; coast
.done
	lea verify_last_joy(pc),a0
	move.w d0,(a0)
	movem.l (sp)+,d1/a0
	tst.w d0                 ; N/Z/V/C as MOVE.W; native LSR at $c1e6 overwrites X
	rts

; Diagnostic traffic fixture: preserve the native one-lap qualifying setup,
; but supply a 0..9 grid permutation and enable opponents BEFORE $9f24.
; Qualifying leaves the grid-order table zeroed: setting only its flag would
; initialise player slot 0 ten times, not create nine opponents.
; This is an artificial attract-with-traffic case, not a recorded UI race.
; Replaces the complete MOVE.W/CLR.W pair at $e06..$e0f.
verify_traffic:
	movem.l d0/a0,-(sp)
	lea 3752(a4),a0
	moveq #9,d0
.grid
	move.w d0,-(a0)
	dbf d0,.grid
	movem.l (sp)+,d0/a0
	move.w #1,3844(a4)
	move.w #1,3846(a4)
	rts

; After the first race anchor, delay presentation by eight native VBL transitions.
; Skip the initial pre-race draw, which would perturb the starting step phase.
; Interrupts keep running: no STOP, host sleep, or game-state writes.
; MOVE/CMP/DBF preserve X.
; Replays both complete four-byte calls displaced at $729a/$729e.
verify_slow_draw:
	movem.l d0-d1,-(sp)
	move.l verify_races(pc),d0
	beq.b .restore
	move.l -31790(a4),d0
	moveq #7,d1
.wait
	cmp.l -31790(a4),d0
	beq.b .wait
	move.l -31790(a4),d0
	dbf d1,.wait
.restore
	movem.l (sp)+,d0-d1
	jsr -32508(a4)
	jsr -32496(a4)
	rts

verify_cache_state:
	move.l attnflags(pc),d0
	btst #AFB_68020,d0
	beq.b .done
	move.l $4.w,a6
	lea .read(pc),a5
	jsr _LVOSupervisor(a6)
	lea verify_cacr(pc),a0
	move.l d0,(a0)
.done
	rts
	MACHINE 68020
.read
	movec cacr,d0
	rte
	MACHINE 68000

; Debugger discovery record. No host writes to the emulated machine are needed.
verify_record
	dc.b "GPCVERIFY",0
	even
verify_hunk0
	dc.l 0
verify_v1
	dc.l 0
verify_epoch
	dc.l 0
verify_races
	dc.l 0
verify_joy_calls
	dc.l 0
verify_cacr
	dc.l 0                   ; no CACR on 68000; guarded read on 68020+
verify_last_joy
	dc.w 0
