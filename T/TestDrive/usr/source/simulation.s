; Test Drive fixed-time arithmetic. Original simulation period: five PAL fields.
; All private carries belong to their accumulator, not to a draw buffer.
; Gameplay installation is in simulation-patches.i (CUSTOM2).

; d0 signed rate, a0 signed word remainder. Result = trunc((rate*p+carry)/5).
; Splitting BEFORE multiplication handles INT_MIN without a wide multiply or
; a 68000 DIVS quotient overflow. Five p=2 calls compose to two original rates.
sim_scale_long:
    movem.l d1-d2,-(sp)
    moveq #0,d1
    move.w sim_p(pc),d1
    moveq #5,d2
    bsr sim_ratio
    movem.l (sp)+,d1-d2
    rts

; d0 signed 32-bit input; d1 numerator, d2 denominator (positive words).
; a0 signed word carry, abs(carry)<denominator. Preserve every register but d0.
; The caller must bound quotient*numerator and final result to signed 32 bits.
; For scale_long this holds for every input at p=2/5, including INT_MIN.
; Numerator*remainder+carry must fit signed 32 bits; denominator <=32767.
; Division is truncation toward zero; a sign change consumes the old carry.
sim_ratio:
    movem.l d1-d6,-(sp)
    move.l d0,d6
    bpl.b .magnitude
    neg.l d0
.magnitude
    move.l d0,d3
    clr.w d0
    swap d0
    divu.w d2,d0
    move.w d0,d4
    clr.w d0
    move.w d3,d0
    divu.w d2,d0
    swap d4
    move.w d0,d4               ; unsigned magnitude quotient
    swap d0
    and.l #$ffff,d0            ; unsigned magnitude remainder
    mulu.w d1,d0
    move.l d4,d3
    mulu.w d1,d3
    swap d4
    mulu.w d1,d4
    swap d4
    clr.w d4
    add.l d3,d4               ; quotient * numerator
    tst.l d6
    bpl.b .carry
    neg.l d4
    neg.l d0
.carry
    move.w (a0),d5
    ext.l d5
    add.l d5,d0
    divs.w d2,d0              ; small residual quotient and signed remainder
    move.w d0,d5
    ext.l d5
    add.l d5,d4
    swap d0
    move.w d0,(a0)
    ; A residual opposing the whole quotient needs truncation normalization.
    ; E.g. 1 + (-2/5) is 0 remainder +3, not 1 remainder -2.
    tst.l d4
    beq.b .done
    bmi.b .negative
    tst.w (a0)
    bpl.b .done
    subq.l #1,d4
    add.w d2,(a0)
    bra.b .done
.negative
    tst.w (a0)
    ble.b .done
    addq.l #1,d4
    sub.w d2,(a0)
.done
    move.l d4,d0
    movem.l (sp)+,d1-d6
    rts

; Counted PAL clock: input 1 for count, integer mph for speed-weighted sum.
; Output in legacy twelfths of a second; distinct signed carries for both.
; No call while neutral-start excluded or while the original event path blocks.
sim_clock_delta:
    movem.l d1-d2,-(sp)
    moveq #0,d1
    move.w sim_p(pc),d1
    mulu.w #6,d1
    moveq #25,d2
    bsr sim_ratio
    movem.l (sp)+,d1-d2
    rts

; Semi-implicit coarse Euler: post-step v, full original-step acceleration A.
; d0=v, d1=A; a0 signed word carry in units of 1/3200 distance LSB.
; At dt=p/5, dx=dt*(v+(1-dt)*A/2)/64. Thus the numerator is
; p*(10*v+(5-p)*A), denominator 3200. This is ONE distance scaling.
; For constant A, five p=2 steps and two p=5 steps have the same unrounded
; displacement. Collision impulses must never enter A.
; Domain: 0<=v<=0x00ffffff, abs(A)<=0x00100000 (well above game rates).
; At p=5 retain the original per-step /64 truncation, including its low-bit
; loss: original-mode rate/travel comparisons must not hide a carry change.
sim_distance:
    movem.l d1-d3,-(sp)
    move.w sim_p(pc),d3
    cmp.w #5,d3
    bne.b .fine
    lsr.l #6,d0
    clr.w (a0)
    bra.b .done
.fine
    move.l d0,d2
    lsl.l #2,d0
    add.l d2,d0
    add.l d0,d0               ; 10*v
    move.l d1,d2
    add.l d1,d2
    add.l d2,d1               ; (5-2)*A
    add.l d1,d0
    bpl.b .forward
    moveq #0,d0
    clr.w (a0)
.forward
    moveq #2,d1
    move.w #3200,d2
    bsr sim_ratio
.done
    movem.l (sp)+,d1-d3
    rts

; d0 signed word state, d1 Q16 loss coefficient, a0 unsigned word carry.
; Return state-floor((state*loss+carry)/65536), retaining the low product.
; Loss must be <=32767; signed MULS then covers the full signed word domain.
; For RPM, p=2 loss=round(65536*(1-(31/32)^(2/5)))=827.
; The p=5 RPM hook uses the original shift/subtract instead (no new carry).
sim_relax_word:
    movem.l d1-d3,-(sp)
    move.w d0,d2
    ext.l d2
    muls.w d0,d1
    moveq #0,d3
    move.w (a0),d3
    add.l d3,d1
    move.w d1,(a0)
    swap d1
    ext.l d1
    sub.l d1,d2
    move.l d2,d0
    movem.l (sp)+,d1-d3
    rts

; Advance the original five-field decision cadence. d0=elapsed fields (2/5),
; a0 phase word [0,4]. Returns number of crossed boundaries (0/1).
; Unlike a reset-to-zero counter, the remainder retains the 2/5 phase.
sim_cadence:
    add.w (a0),d0
    cmp.w #5,d0
    bcs.b .not_due
    subq.w #5,d0
    move.w d0,(a0)
    moveq #1,d0
    rts
.not_due
    move.w d0,(a0)
    moveq #0,d0
    rts

sim_p: dc.w 5

; Read configuration and resolve the data hunk before PatchSeg. No game writes.
sim_init:
    lea sim_tags(pc),a0
    move.l _resload(pc),a2
    jsr resload_Control(a2)
    lea sim_p(pc),a0
    move.w #5,(a0)
    move.l sim_attn(pc),d0
    btst #1,d0                ; AFB_68020
    beq.b .data
    move.w #2,(a0)
.data
    move.l d7,a0
    adda.l a0,a0
    adda.l a0,a0
    move.l (a0),d0
    lsl.l #2,d0
    addq.l #4,d0
    lea sim_data(pc),a0
    move.l d0,(a0)
    rts

; The overlay export is rewritten at every load. Original $42 is also the
; installation guard; VERIFY's independent entry/anchor hooks can coexist.
sim_overlay_loaded:
    movem.l d0-a6,-(sp)
    move.l sim_enabled(pc),d0
    beq.b .done
    move.l sim_data(pc),a0
    cmp.w #$4ef9,668(a0)
    bne.b .done
    move.l 670(a0),a1
    cmp.l #$4e55ffcc,(a1)
    bne.b .done
    cmp.l #$2b7c0000,$42(a1)
    bne.b .done
    lea sim_h4(pc),a0
    move.l a1,(a0)
    lea sim_patches(pc),a0
    move.l _resload(pc),a2
    jsr resload_Patch(a2)
.done
    movem.l (sp)+,d0-a6
    rts
sim_patches:
    PL_START
    include "simulation-patches.i"
    PL_END

sim_period:
    move.l d0,-(sp)
    moveq #0,d0
    move.w sim_p(pc),d0
    move.l d0,-16(a5)
    movem.l (sp)+,d0
    rts
sim_reset:
    movem.l d0/a0,-(sp)
    lea sim_carries(pc),a0
    moveq #SIM_CARRY_WORDS-1,d0
.clear
    clr.w (a0)+
    dbf d0,.clear
    lea sim_visual_seed(pc),a0
    move.w #$1234,(a0)
    bsr sim_visual_samples
    lea sim_phase(pc),a0
    moveq #5,d0
    sub.w sim_p(pc),d0
    move.w d0,(a0)
    movem.l (sp)+,d0/a0
    move.l -31782(a4),-20(a5)  ; original epoch; blocking event path unchanged
    rts
sim_begin:
    movem.l d0/a0,-(sp)
    lea sim_force(pc),a0
    move.l (a0),sim_previous_force-sim_force(a0)
    clr.l (a0)
    lea sim_phase(pc),a0
    moveq #0,d0
    move.w sim_p(pc),d0
    bsr sim_cadence
    lea sim_due(pc),a0
    move.w d0,(a0)
    beq.b .visual_done
    bsr sim_visual_step
.visual_done
    tst.l -29564(a4)
    bne.b .police_active
    lea sim_police_force(pc),a0
    clr.l (a0)
    lea sim_police_speed_carry(pc),a0
    clr.w (a0)
    lea sim_traffic_carries(pc),a0
    clr.w (a0)               ; slot 5 maps to loop index zero
.police_active
    bsr sim_geometry
    bsr sim_verge_drag
    movem.l (sp)+,d0/a0
    tst.w -29322(a4)          ; original police-stop test/branch
    beq.b .vehicle
    addq.l #4,(sp)            ; skip only original vehicle call at h4:$130
.vehicle
    rts
sim_count:
    movem.l d0/a0,-(sp)
    lea sim_sum_carry(pc),a0
    bsr sim_clock_delta
    add.l d0,-44(a5)
    moveq #1,d0
    lea sim_clock_carry(pc),a0
    bsr sim_clock_delta
    add.l d0,-36(a5)
    movem.l (sp)+,d0/a0
    rts
sim_shifter:
    movem.l d0/a0,-(sp)
    moveq #0,d0
    move.w sim_p(pc),d0
    lea sim_shifter_phase(pc),a0
    bsr sim_cadence           ; post-wait time, distinct from pre-step decisions
    tst.w d0
    movem.l (sp)+,d0/a0
    beq.b .input
    bsr .original
.input
    jsr -32712(a4)            ; displaced input call at h4:$19C
    rts
.original
    move.l sim_h4(pc),-(sp)
    add.l #$472,(sp)
    rts

; Accumulate unscaled continuous force separately from game collision impulses.
; One signed carry belongs to speed, shared by its continuous additive terms.
sim_speed_add:
    move.l a0,-(sp)
    lea sim_force(pc),a0
    add.l d0,(a0)
    lea sim_speed_carry(pc),a0
    bsr sim_scale_long
    add.l d0,-22360(a4)
    move.l (sp)+,a0
    tst.w -26340(a4)          ; displaced test, original clamp consumes CCR
    rts
sim_brake:
    movem.l d0/a0,-(sp)
    move.l #-270336,d0
    bra.b sim_speed_rate
sim_neutral_drag:
    movem.l d0/a0,-(sp)
    move.l #-32767,d0
    bra.b sim_speed_rate
sim_scrub:
    movem.l d0/a0,-(sp)
    move.l #-16384,d0
sim_speed_rate:
    lea sim_force(pc),a0
    add.l d0,(a0)
    lea sim_speed_carry(pc),a0
    bsr sim_scale_long
    add.l d0,-22360(a4)
    movem.l (sp)+,d0/a0
    tst.l -22360(a4)          ; preserve the original underflow branch decision
    rts
sim_player_motion:
    movem.l d1/a0,-(sp)
    move.l sim_force(pc),d1
    lea sim_distance_carry(pc),a0
    bsr sim_distance
    move.l d0,-22344(a4)
    movem.l (sp)+,d1/a0
    tst.l d0                 ; displaced BGE at h4:$3FF8
    rts
sim_free_rpm:
    movem.l d0/a0,-(sp)
    move.l #500,d0
    lea sim_rpm_carry(pc),a0
    bsr sim_scale_long
    add.w d0,-26340(a4)
    movem.l (sp)+,d0/a0
    rts
sim_rpm_decay:
    move.w -26340(a4),d0
    move.w d0,d1
    lsr.w #5,d1
    move.l d2,-(sp)
    move.w sim_p(pc),d2
    cmp.w #5,d2
    bne.b .fine
    sub.w d1,-26340(a4)       ; original truncation at p=5
    bra.b .done
.fine
    movem.l d0/a0,-(sp)
    move.w #827,d1
    lea sim_rpm_decay_carry(pc),a0
    bsr sim_relax_word
    move.w d0,-26340(a4)
    movem.l (sp)+,d0/a0
.done
    movem.l (sp)+,d2
    rts

sim_carries:
sim_shifter_phase: dc.w 0
sim_speed_carry: dc.w 0
sim_rpm_carry: dc.w 0
sim_distance_carry: dc.w 0
sim_clock_carry: dc.w 0
sim_sum_carry: dc.w 0
sim_rpm_decay_carry: dc.w 0
sim_grip_carry: dc.w 0
sim_steer_carry: dc.w 0
sim_return_carry: dc.w 0
sim_edge_carry: dc.w 0
sim_centre_carry: dc.w 0
sim_lane_carries: ds.w 6,0
sim_traffic_carries: ds.w 6,0
sim_oncoming_carries: ds.w 5,0
sim_police_speed_carry: dc.w 0
sim_police_force: dc.l 0
sim_force: dc.l 0
sim_previous_force: dc.l 0
SIM_CARRY_WORDS equ (*-sim_carries)/2
sim_phase: dc.w 0
sim_due: dc.w 0
sim_data: dc.l 0
sim_h4: dc.l 0
sim_tags:
    dc.l WHDLTAG_CUSTOM2_GET
sim_enabled: dc.l 0
    dc.l WHDLTAG_ATTNFLAGS_GET
sim_attn: dc.l 0
    dc.l 0

; Road descriptor byte: high/low nibbles select 320+64*n widths.
; d0 byte (not $ff, which means inherit); return d0 left, d1 right.
sim_width_decode:
    move.l d2,-(sp)
    move.w d0,d1
    and.w #15,d1
    lsl.w #6,d1
    add.w #320,d1
    lsr.w #4,d0
    and.w #15,d0
    lsl.w #6,d0
    add.w #320,d0
    move.l (sp)+,d2
    rts

; d0 longitudinal integer position. Read-only map walk, independent of either
; rendering pass. An inherited width is the nearest earlier explicit descriptor.
; Unlike original h4:$A2A this cannot shorten the stage as a side effect.
; Return d0/d1 widths, preserving the other registers.
sim_road_widths:
    movem.l d2/a0-a1,-(sp)
    move.l -26232(a4),a0      ; road index bytes
    move.l -26228(a4),a1      ; four-byte descriptors
    cmp.w -26234(a4),d0
    blt.b .scan
    move.w -26234(a4),d0
    subq.w #1,d0
.scan
    tst.w d0
    bmi.b .default
    moveq #0,d2
    move.b (a0,d0.w),d2
    cmp.b #$ff,d2
    beq.b .previous
    lsl.w #2,d2
    move.b (a1,d2.w),d2
    cmp.b #$ff,d2
    bne.b .found
.previous
    subq.w #1,d0
    bra.b .scan
.default
    moveq #0,d0
    bra.b .decode
.found
    moveq #0,d0
    move.b d2,d0
.decode
    bsr sim_width_decode
    movem.l (sp)+,d2/a0-a1
    rts

; Run once per simulation step, before vehicle collision and traffic tests.
; Drawing continues to project its snapshots, but no longer owns any of these
; road widths, lane returns or collision origins. Empty traffic slots retain
; their previous origin; spawning is followed by this computation next step.
sim_geometry:
    movem.l d0-d7/a0-a3,-(sp)
    moveq #0,d0
    move.w -22352(a4),d0
    bsr sim_road_widths
    move.w d0,-29290(a4)
    move.w d1,-29288(a4)
    lea -29584(a4),a1
    lea -29500(a4),a2
    lea -29524(a4),a3
    lea sim_lane_carries(pc),a0
    moveq #0,d7
.forward
    tst.l (a1)
    beq .next
    moveq #0,d0
    move.w (a1),d0
    bsr sim_road_widths
    sub.w #224,d1            ; slots 0/2/3/4 use the right edge minus 224
    cmp.w #1,d7
    beq.b .centre
    cmp.w #5,d7
    bne.b .ordinary
.centre
    move.w #224,d1           ; slot 1 and police are drawn from the centre
.ordinary
    cmp.w #5,d7
    beq.b .police
    tst.w (a3)
    ble.b .store
    move.l #-56,d0
    bsr sim_scale_long
    add.w (a3),d0
    cmp.w #224,d0
    ble.b .lane
    move.w #224,d0
.lane
    move.w d0,(a3)
    add.w d0,d1
    bra.b .store
.police
    cmp.w #10,-29316(a4)
    bcs.b .police_return
    move.w -29318(a4),d0
    cmp.w #60,d0
    bls.b .clock
    moveq #60,d0
.clock
    sub.w #30,d0
    bpl.b .absolute
    neg.w d0
.absolute
    sub.w #30,d0
    lsl.w #4,d0
    add.w d0,d1
    bra.b .store
.police_return
    tst.w (a3)
    bge.b .store
    moveq #56,d0
    bsr sim_scale_long
    add.w (a3),d0
    cmp.w #-224,d0
    bge.b .police_lane
    move.w #-224,d0
.police_lane
    move.w d0,(a3)
    add.w d0,d1
.store
    move.w d1,(a2)
.next
    addq.l #4,a1
    addq.l #4,a2
    addq.l #4,a3
    addq.l #2,a0
    addq.w #1,d7
    cmp.w #6,d7
    bcs .forward
    lea -29452(a4),a1
    lea -29398(a4),a2
    moveq #4,d7
.oncoming
    tst.l (a1)+
    beq.b .oncoming_next
    move.w #-224,(a2)         ; original centre-lane oncoming origin
.oncoming_next
    addq.l #4,a2
    dbf d7,.oncoming
    movem.l (sp)+,d0-d7/a0-a3
    rts

; Traffic integrates BEFORE updating police speed (explicit Euler). Its stored
; velocity already has road-distance units: do not divide by the player's 64.
; d0=velocity, d1=preceding continuous full-step acceleration, a0 signed carry.
; dx=dt*(v-(1-dt)*A/2), so p=2 uses 2*(10*v-3*A)/50. Constant traffic has A=0.
; Domain: 0<=v<=0x00ffffff, abs(A)<=0x00100000. Clamped negative motion is zero.
sim_traffic_delta:
    tst.l d0
    bne.b .moving
    clr.w (a0)               ; a stopped/clamped car must never creep
    rts
.moving
    movem.l d1-d3,-(sp)
    move.w sim_p(pc),d3
    cmp.w #5,d3
    bne.b .fine
    clr.w (a0)
    bra.b .done
.fine
    move.l d0,d2
    lsl.l #2,d0
    add.l d2,d0
    add.l d0,d0
    move.l d1,d2
    add.l d1,d2
    add.l d2,d1
    sub.l d1,d0
    bpl.b .forward
    moveq #0,d0
    clr.w (a0)
.forward
    moveq #2,d1
    moveq #50,d2
    bsr sim_ratio
.done
    movem.l (sp)+,d1-d3
    rts

sim_traffic_forward:
    movem.l d1/a0,-(sp)
    lea sim_traffic_carries(pc),a5
    move.w d6,d0              ; original loop counts slots 5 down to 0
    add.w d0,d0
    lea (a5,d0.w),a0
    move.l (a1),d0
    moveq #0,d1
    tst.w d6
    bne.b .motion
    move.l sim_police_force(pc),d1
.motion
    bsr sim_traffic_delta
    movem.l (sp)+,d1/a0
    add.l (a0),d0
    lea -29500(a4),a5         ; displaced traffic collision origins
    rts
sim_traffic_oncoming:
    movem.l d1/a0,-(sp)
    lea sim_oncoming_carries(pc),a3
    move.w d6,d0
    add.w d0,d0
    lea (a3,d0.w),a0
    move.l (a1),d0
    moveq #0,d1
    bsr sim_traffic_delta
    movem.l (sp)+,d1/a0
    neg.l d0
    add.l (a0),d0
    lea -29452(a4),a3         ; displaced oncoming positions
    rts
sim_police_accel:
    movem.l d0/a0,-(sp)
    move.l #1536,d0
    bra.b sim_police_rate
sim_police_brake:
    movem.l d0/a0,-(sp)
    move.l #-1536,d0
sim_police_rate:
    lea sim_police_force(pc),a0
    move.l d0,(a0)
    lea sim_police_speed_carry(pc),a0
    bsr sim_scale_long
    add.l d0,-29528(a4)
    movem.l (sp)+,d0/a0
    rts
sim_police_follow:
    movem.l d0/a0,-(sp)
    move.l -22344(a4),d0
    move.w sim_p(pc),-(sp)
    cmp.w #5,(sp)+
    beq.b .store
    move.l -22360(a4),d0
    lsr.l #6,d0
.store
    move.l d0,-29528(a4)      ; velocity stays in original units, not p/5 distance
    lea sim_police_force(pc),a0
    clr.l (a0)
    lea sim_police_speed_carry(pc),a0
    clr.w (a0)
    movem.l (sp)+,d0/a0
    rts
sim_test_due:
    move.l d0,-(sp)
    move.w sim_due(pc),d0
    movem.l (sp)+,d0
    rts
sim_police_seen:
    bsr sim_test_due
    beq.b .done
    addq.w #1,-29320(a4)
.done
    move.w -26234(a4),d0
    rts
sim_police_clock:
    bsr sim_test_due
    beq.b .done
    addq.w #1,-29318(a4)
.done
    cmp.w #60,-29318(a4)
    rts
sim_police_stop:
    bsr sim_test_due
    beq.b .done
    addq.w #1,-29322(a4)
.done
    add.l #$2e,(sp)          ; displaced BRA to h4:$16D8 from return $16AA
    rts

; Continuous steering slew and return limits, in original 16.16 units.
; Limit comparisons and centre clamps downstream remain in their original units.
sim_steer_limits:
    move.l a0,-(sp)
    move.l #393216,d0
    lea sim_steer_carry(pc),a0
    bsr sim_scale_long
    move.l d0,-(sp)
    move.l #65536,d0
    lea sim_return_carry(pc),a0
    bsr sim_scale_long
    move.l d0,d1
    move.l (sp)+,d0
    move.l (sp)+,a0
    rts
sim_edge_rate:
    movem.l d0/a0,-(sp)
    move.l #393216,d0
    lea sim_edge_carry(pc),a0
    bsr sim_scale_long
    move.l d0,d2
    move.l d0,d3
    movem.l (sp)+,d0/a0
    rts
sim_lane_centre:
    movem.l d0/a0,-(sp)
    move.w d2,d0
    ext.l d0
    swap d0
    clr.w d0                 ; signed integer lateral units -> 16.16
    lea sim_centre_carry(pc),a0
    bsr sim_scale_long
    sub.l d0,-22376(a4)
    movem.l (sp)+,d0/a0
    add.l #$c,(sp)           ; displaced BRA to h4:$801A
    rts

; These are discrete decisions in the original five-field clock, unlike input
; sampling and vehicle integration. Never change limits or shift impulses.
sim_gear_hold:
    bsr sim_test_due
    bne.b .original
    add.l #$42,(sp)          ; skip to h4:$4366; still read input and move vehicle
    rts
.original
    clr.w -26332(a4)
    move.w #7,-23364(a4)
    rts
sim_rev_counter:
    bsr sim_test_due
    beq.b .compare
    addq.w #1,-27130(a4)
.compare
    cmp.w #10,-27130(a4)
    rts
sim_station_gear:
    bsr sim_test_due
    bne.b .original
    add.l #$32,(sp)          ; h4:$441C: preserve braking; defer gear decision
    rts
.original
    cmp.w #4000,-26340(a4)
    rts
sim_auto_gear:
    bsr sim_test_due
    bne.b .original
    add.l #$26,(sp)          ; h4:$4426: throttle without another gear decision
    rts
.original
    move.w -26336(a4),d0
    cmp.w -26330(a4),d0
    rts

; Match coarse Euler's force sampling as well as its displacement. For dt=2/5,
; sample the curve at max(0,v-(1-dt)*A_previous/2) = max(0,v-3*A_previous/10).
; d0 velocity, d1 previous unscaled force; preserves all but d0. This is a
; lookup reference, not an accumulated rate: both lookups use zero remainder.
; Period 5 is exactly the original reference. Domain matches sim_distance.
sim_reference_velocity:
    movem.l d1-d2/a0,-(sp)
    move.w sim_p(pc),d2
    cmp.w #5,d2
    beq.b .done
    move.l d0,-(sp)
    clr.w -(sp)
    move.l sp,a0
    move.l d1,d0
    moveq #3,d1
    moveq #10,d2
    bsr sim_ratio
    addq.l #2,sp
    move.l (sp)+,d1
    sub.l d0,d1
    move.l d1,d0
    bpl.b .done
    moveq #0,d0
.done
    movem.l (sp)+,d1-d2/a0
    rts
sim_force_reference:
    move.l d1,-(sp)
    move.l -22360(a4),d0
    move.l sim_previous_force(pc),d1
    bsr sim_reference_velocity
    move.l (sp)+,d1
    rts
sim_torque_curve:
    bsr sim_force_reference
    lsr.l #8,d0
    mulu.w -26334(a4),d0
    swap d0
    lsr.w #7,d0
    rts
sim_drag_curve:
    move.l d0,-(sp)
    bsr sim_force_reference
    swap d0
    move.w d0,d1
    lsr.w #2,d1
    move.l (sp)+,d0
    rts

; The game's signed-word LCG, without the beam operand. d0 seed -> full result.
; This pure arithmetic is shared by the simulation-owned visual stream only.
sim_lcg:
    muls.w #6907,d0
    add.l #130253,d0
    rts
sim_visual_samples:
    movem.l d0/d1/a0-a1,-(sp)
    lea sim_visual_seed(pc),a0
    lea sim_visual_values(pc),a1
    move.w (a0),d0
    moveq #3,d1
.next
    bsr sim_lcg
    move.l d0,(a1)+
    dbf d1,.next
    ; An odd stride is essential: four draws lock each lane to one parity,
    ; making the low-ten-bit zero test impossible for this initial seed.
    bsr sim_lcg
    move.w d0,(a0)
    movem.l (sp)+,d0/d1/a0-a1
    rts
; Drawing reads a published sample, never advances either RNG stream.
sim_visual_1023:
    move.l sim_visual_values(pc),d0
    and.w #1023,d0
    rts
sim_visual_255:
    move.l sim_visual_values+4(pc),d0
    and.w #255,d0
    rts
sim_visual_127:
    move.l sim_visual_values+8(pc),d0
    and.w #127,d0
    rts
sim_visual_3:
    move.l sim_visual_values+12(pc),d0
    and.w #3,d0
    rts
sim_visual_seed: dc.w $1234
sim_visual_values: ds.l 4,0

; Advance visual state on the original five-field cadence. Publishing samples
; alone is insufficient: repeated draws must not spawn or age several effects
; from one random sample. The original 30-slot windscreen table remains the
; drawing source; no bitmap operation or OS wait occurs in this routine.
sim_visual_step:
    movem.l d0-d3/a0-a2,-(sp)
    bsr sim_visual_samples
    addq.b #1,-27138(a4)      ; police lamp animation phase
    move.l sim_h4(pc),a0
    lea $22a8(a0),a1
    move.w -22328(a4),d0
    move.w -29280(a4),d1
    move.w d0,-29280(a4)
    jsr (a1)                 ; original wrapped heading difference
    lsl.w #2,d0
    lea $21e0(a0),a1
    jsr (a1)                 ; original background wind/heading phase update
    lea $1f9a(a0),a2
    cmp.w #30,(a2)
    bge.b .animate
    cmp.w #85,-22360(a4)
    bcs.b .animate
    move.l sim_visual_values(pc),d0
    and.w #1023,d0
    bne.b .animate
    move.w (a2),d3
    mulu.w #14,d3
    lea 2(a2,d3.w),a1
    move.l sim_visual_values+4(pc),d0
    and.w #255,d0
    add.w #32,d0
    move.w d0,(a1)
    move.l sim_visual_values+8(pc),d0
    and.w #127,d0
    move.w d0,2(a1)
    move.l -23266(a4),4(a1)
    move.l -23270(a4),8(a1)
    move.w #5,12(a1)
    addq.w #1,(a2)
.animate
    move.w (a2)+,d3
    subq.w #1,d3
    bmi.b .done
.slot
    move.w 12(a2),d0
    beq.b .next
    subq.w #2,2(a2)
    subq.w #1,12(a2)
    cmp.w #3,d0
    bge.b .next
    cmp.w #1,d0
    beq.b .last
    move.l -23258(a4),4(a2)
    move.l -23262(a4),8(a2)
    bra.b .next
.last
    move.l sim_visual_values+12(pc),d0
    and.w #3,d0
    lsl.w #2,d0
    lea -23238(a4),a1
    move.l (a1,d0.w),4(a2)
    lea -23254(a4),a1
    move.l (a1,d0.w),8(a2)
.next
    adda.w #14,a2
    dbf d3,.slot
.done
    movem.l (sp)+,d0-d3/a0-a2
    rts
sim_windscreen_draw:
    add.l #$50,(sp)          ; return $1EE2 -> $1F32, draw existing slots only
    rts
sim_windscreen_draw_next:
    move.w (a2)+,d0          ; retain the original fourteen-byte record stride
    add.l #$3e,(sp)          ; return $1F52 -> $1F90, skip all aging/mutation
    rts

; Original h4:$1DA6 applies verge drag from Road Drawer, at most once after
; the CLI sets its draw-side latch. Enhanced mode owns this rate explicitly.
; Geometry inequalities and the 23-mph threshold are unchanged. Sound/visual
; verge detection remains in drawing, but cannot change speed or RPM there.
sim_verge_drag:
    movem.l d0-d1/a0,-(sp)
    cmp.w #23,-22360(a4)
    ble.b .done
    move.w -22376(a4),d1
    add.w d1,d1
    move.w d1,d0
    add.w -29290(a4),d0
    sub.w #127,d0
    ble.b .drag
    neg.w d1
    add.w -29288(a4),d1
    subq.w #3,d1
    bgt.b .done
.drag
    move.l #-12288,d0
    lea sim_force(pc),a0
    add.l d0,(a0)
    lea sim_speed_carry(pc),a0
    bsr sim_scale_long
    add.l d0,-22360(a4)
    bpl.b .rpm
    clr.l -22360(a4)
.rpm
    tst.w -22786(a4)
    bne.b .done
    move.l sim_h4(pc),a0
    lea $3e6c(a0),a0
    jsr (a0)
.done
    movem.l (sp)+,d0-d1/a0
    rts
sim_draw_verge:
    add.l #$12,(sp)          ; return $1E26 -> original RTS at h4:$1E38
    rts

; Convert a step displacement back to original-step units for a threshold or
; instantaneous pose. This is NOT an integrated quantity: no carried remainder.
; d0 signed input, abs(input)<=858993459 for p=2; all other registers preserved.
; Period 5 is bit-exact. Round toward zero, including negative near-zero input.
sim_coarse_rate:
    movem.l d1-d2/a0,-(sp)
    move.w sim_p(pc),d2
    cmp.w #5,d2
    beq.b .done
    clr.w -(sp)
    move.l sp,a0
    moveq #5,d1
    bsr sim_ratio
    addq.l #2,sp
.done
    movem.l (sp)+,d1-d2/a0
    rts

; Steering motion already includes dt through displacement and edge-response
; rates. The original grip routine compares against an unscaled car limit.
; Normalize its input, run its original clamp/impulse logic, then return only
; the clamped motion to step units. An unclamped input passes through exactly,
; avoiding a lossy scale/unscale round trip. The tyre speed loss has its own
; continuous-rate hook; spatial impacts and the grip threshold are untouched.
sim_steer_grip:
    move.l d0,-(sp)
    move.w sim_p(pc),d0
    cmp.w #5,d0
    movem.l (sp)+,d0
    beq.b .coarse
    movem.l d1-d3,-(sp)
    move.l -26200(a4),d3
    move.l d3,d0
    bsr sim_coarse_rate
    move.l d0,d2
    move.l d0,-26200(a4)
    bsr .original
    move.l -26200(a4),d0
    cmp.l d2,d0
    bne.b .clamped
    move.l d3,d0
    bra.b .store
.clamped
    move.l a0,-(sp)
    lea sim_grip_carry(pc),a0
    bsr sim_scale_long
    move.l (sp)+,a0
.store
    move.l d0,-26200(a4)
    movem.l (sp)+,d1-d3
    rts
.coarse
    bsr .original
    move.l -26200(a4),d0       ; displaced load after original grip call
    rts
.original
    move.l sim_h4(pc),-(sp)
    add.l #$8104,(sp)
    rts

; Banking is an instantaneous visual pose, reset by the grip routine each
; step, not an accumulated angle. Preserve its original coarse-rate units so
; shortening a step does not make the same turn appear 2/5 as banked.
sim_bank_pose:
    move.l -26204(a4),d0
    bsr sim_coarse_rate
    asr.l #4,d0
    rts                         ; original ADDQ #1 remains outside the hook
