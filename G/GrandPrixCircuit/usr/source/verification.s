; Measurement instruments only. Included exclusively by VERIFY builds.
; Offsets below are for the size-checked 94,708-byte executable.
; Requires WHDLoad 17.2+ for PL_IFC3/PL_IFC5 (tested with 20.0).
; CUSTOM3 pins only the beam contribution to the native RNG; CUSTOM5 returns
; raw JOY1DAT values indexed by native fields since the first gameplay loop.
; C5 bit 1 selects human driving; bit 2 fixes the initial start gate; bits 3/4
; record/replay joystick-only laps. The default attract driver remains native.
; Higher-rate physics is selected separately by CUSTOM2, never by this fixture.
verify_race_start:
	movem.l d0/a0-a1,-(sp)
	bsr verify_drive_start
	lea verify_epoch(pc),a0
	move.l -31790(a4),(a0)
	lea verify_races(pc),a0
	move.l (a0),a1
	addq.l #1,a1              ; address arithmetic preserves the incoming X flag
	move.l a1,(a0)
	movem.l (sp)+,d0/a0-a1
	bra render_camera_start  ; same race-history reset and native gate release

verify_read_joydat:
	movem.l d1/a0,-(sp)
	lea verify_joy_calls(pc),a0
	addq.l #1,(a0)
	moveq #0,d0               ; neutral until the first race
	move.l verify_races(pc),d1
	beq.w .done
	move.l -31790(a4),d1
	sub.l verify_epoch(pc),d1
    move.l verify_drive_options(pc),d0
    and.l #$f00,d0
    cmp.l #$600,d0
    bne.w .drive
    cmp.l #180,d1
    bcs.w .drive
    moveq #0,d0
    bra .done
.drive
    ; Bit 6 is an interval-command tape: a native endpoint sample is held
    ; over its six-field integration interval. Raw wall-field replay (bit 4
    ; alone) stays available and is not silently retimed.
    move.l verify_drive_options(pc),d0
    btst #6,d0
    beq.b .wall_field
    addq.l #5,d1
    divu.w #6,d1
    and.l #$ffff,d1
    mulu.w #6,d1
.wall_field
    move.l verify_drive_options(pc),d0
    btst #4,d0
    bne .tape
    btst #3,d0
    bne .pilot
	move.w #$0100,d0          ; accelerate
	cmp.l #100,d1
	bcs.w .done
	cmp.l #106,d1
	bcc.w .right
	move.w #$0200,d0          ; up + left
	bra.w .done
.right
	cmp.l #112,d1
	bcc.w .brake
	move.w #$0103,d0          ; up + right
	bra.w .done
.brake
	cmp.l #200,d1
	bcs.w .done
	cmp.l #300,d1
	bcc.w .coast
	moveq #1,d0               ; brake
	bra.w .done
.coast
	cmp.l #400,d1
	bcc.w .done
	moveq #0,d0               ; coast
    bra.w .done
.pilot
    bsr verify_pilot_input
    bra.w .done
.tape
    bsr verify_tape_input
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
	beq.w .restore
	move.l -31790(a4),d0
	moveq #7,d1
.wait
	cmp.l -31790(a4),d0
	beq.w .wait
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
	beq.w .done
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

; Explicit test fixture, not a user-facing gameplay change. Initialise through
; the guest because the debugger is read-only. All arms use the same fixture.
verify_drive_start:
    move.l verify_drive_options(pc),d0
    btst #1,d0
    beq.w .start
    clr.w 3598(a4)            ; select human steering, keep native auto gears
    clr.w -20716(a4)
.start
    btst #2,d0
    beq.w .done
    move.w #1,4020(a4)        ; identical running state, bypass draw start latency
    clr.w 4024(a4)
    clr.w -2014(a4)
    clr.w 4022(a4)
    clr.w -29942(a4)
    move.w #100,-29930(a4)
    move.w -29926(a4),-29928(a4)
    lea sim_phase(pc),a0
    clr.w (a0)
.done
    move.l verify_drive_options(pc),d0
    btst #5,d0
    beq.b .no_perturbation
    move.w #1,-30012(a4)     ; diagnostic sensitivity: 1/256 of one road segment
.no_perturbation
    rts

; C5 bits 8..11 choose one forced event after 180 native fields: 1 overheat,
; 2 damaged-engine coast, 3 spin, 4 actual Ctrl-P/Space keyboard queue sequence,
; 5 neutral RPM, 6 native pit entry/service/return, 7 off-road penalties.
; These enter native event paths. No event/recovery replacement is installed.
verify_event_field:
    addq.l #1,-31790(a4)
    movem.l d0-d2/a0,-(sp)
    move.l verify_races(pc),d0
    beq .done
    move.l -31790(a4),d1
    sub.l verify_epoch(pc),d1
    move.l verify_drive_options(pc),d2
    lsr.l #8,d2
    and.w #15,d2
    cmp.l #180,d1
    bne.w .resume
    cmp.w #7,d2
    beq.w .penalty
    cmp.w #6,d2
    beq.w .pit
    cmp.w #5,d2
    beq.w .neutral
    cmp.w #4,d2
    beq.w .pause
    tst.w d2
    beq.w .done
    cmp.w #3,d2
    bhi.w .done
    move.w #25600,-29944(a4)
    cmp.w #3,d2
    beq.w .spin
    move.w #2,-29942(a4)
    move.w #-1,-29940(a4)
    cmp.w #1,d2
    bne.w .done
    move.w #3,-29942(a4)
    bra.w .done
.spin
    move.w #1,-31134(a4)     ; beginner mode suppresses spins altogether
    move.w #1,-30610(a4)
    bra.w .done
.penalty
    move.w #25600,-29944(a4)
    move.w #1400,-29976(a4)
    move.w #1,-31134(a4)     ; native damage quantum, not beginner immunity
    bra.w .done
.pit
    clr.w -29944(a4)
    move.w #-1400,-29976(a4)
    move.w #-1,-1864(a4)
    move.w #160,3708(a4)
    bra.w .done
.neutral
    clr.w -29818(a4)
    clr.w -31130(a4)
    clr.w -29814(a4)
    clr.w -29820(a4)
    move.w #800,-29960(a4)
    bra.w .done
.pause
    move.b #$19,3424(a4)     ; P with Ctrl qualifier -> native ASCII 16
    move.w #8,3434(a4)
    move.w #1,3454(a4)
    bra.w .done
.resume
    cmp.w #6,d2
    bne.b .pause_resume
    cmp.l #780,d1
    bne.w .done
    move.b #$44,3424(a4)     ; leave the native pit summary with Return
    clr.w 3434(a4)
    move.w #1,3454(a4)
    bra.w .done
.pause_resume
    cmp.w #4,d2
    bne.w .done
    cmp.l #240,d1
    bne.w .done
    move.b #$40,3424(a4)     ; Space consumed by native pause UI
    clr.w 3434(a4)
    move.w #1,3454(a4)
.done
    movem.l (sp)+,d0-d2/a0
    move.w -31736(a4),d0
    rts

    include "verification-driving.s"

; Return key after 60 service fields, through the pit menu's existing input
; result. Native selection, repair, animation and elapsed-fields/6 stay intact.
verify_pit_key:
    move.l verify_drive_options(pc),d0
    and.l #$f00,d0
    cmp.l #$600,d0
    bne.w .native
    move.l -31790(a4),d0
    sub.l -8(a5),d0
    cmp.l #60,d0
    bcs.w .native
    moveq #$44,d0
    bra.w .done
.native
    move.l sim_code(pc),a0
    adda.l #$158,a0
    jsr (a0)
.done
    move.w d0,-12(a5)
    rts
