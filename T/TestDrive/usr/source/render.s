; CUSTOM2: preserve blitter bus priority (DMACON BLTPRI) and suppress
; graphics.library's unused blitter-finished interrupt while TD runs.
; Ported from TD2 render.s; TD's existing root:$434/$444 fixes already enable
; priority during gameplay. The measured additional gain is IRQ suppression.
; Shape blits poll BBUSY at root:$D44; waits and ownership are unchanged.
; Preserves the game entry's registers; restore puts back the original enables.
render_interrupt_option:
    movem.l d0/a0,-(sp)
    move.l sim_enabled(pc),d0
    tst.l d0
    beq.b .done
    IFD VERIFY
    move.l verify_c1(pc),d0
    btst #3,d0               ; measurement control: keep phase-8 simulation
    bne.b .done
    ENDC
    lea render_active(pc),a0
    move.w #1,(a0)
    lea render_saved_priority(pc),a0
    move.w $dff002,d0
    and.w #$400,d0
    move.w d0,(a0)+
    move.w $dff01c,d0
    and.w #$40,d0
    move.w d0,(a0)            ; render_saved_irq
    move.w #$8400,$dff096
    move.w #$40,$dff09a
.done
    movem.l (sp)+,d0/a0
    rts
render_interrupt_restore:
    move.l d0,-(sp)
    move.w render_active(pc),d0
    tst.w d0
    beq.b .done
    move.w render_saved_priority(pc),d0
    bne.b .priority
    move.w #$0400,$dff096
.priority
    move.w render_saved_irq(pc),d0
    beq.b .done
    move.w #$8040,$dff09a
.done
    move.l (sp)+,d0
    rts
render_saved_priority: dc.w 0
render_saved_irq: dc.w 0

render_active: dc.w 0


; TD streams 16.16 road coordinates. Its root:$2108 already interpolates a
; sine table using a full 16.16 argument. Do not transplant TD2's 8.8 tangent
; keys or apply a second camera correction to TD's existing first-span scale.
render_overlay_loaded:
    IFD VERIFY
    move.l verify_c1(pc),d0
    btst #4,d0               ; same-build comparison: phase 10 disabled
    bne.b .done
    ENDC
    lea render_patches(pc),a0
    move.l sim_h4(pc),a1
    move.l _resload(pc),a2
    jsr resload_Patch(a2)
.done
    rts
render_patches:
    PL_START
    include "render-patches.i"
    PL_END

render_reset:
    lea render_heading_state(pc),a0
    move.w #-1,(a0)
    rts

    IFD VERIFY
; C5 bit 5: isolated draw-snapshot fixture. C1 high word selects a pinned
; track segment; C5 high word selects the camera fraction. Simulation state
; and native traffic state are never written. Both comparison arms use it.
render_verify_fixture:
    move.l verify_c5(pc),d0
    btst #5,d0
    beq.b .done
    swap d0
    move.w d0,-22338(a4)
    move.l verify_c1(pc),d0
    swap d0
    move.w d0,-22340(a4)
    move.l #100*65536+16384,-22372(a4)
    clr.l -22364(a4)
    clr.w -22460(a4)
    lea -29374(a4),a0
    lea .positions(pc),a1
    moveq #11,d2
.next
    move.w -22340(a4),d1
    add.w (a1)+,d1
    move.w d1,(a0)+
    move.w (a1)+,(a0)+
    dbf d2,.next
.done
    rts
.positions
    dc.w 100,0,10,$4000,14,$8000,18,$c000,22,$ffff,-14,$8000
    dc.w 12,$4000,-12,$8000,16,$c000,-16,$ffff,20,$8000,100,0
    ENDC

    IFD VERIFY
; C5 bit 6 runs native arithmetic/cache vectors once. Separate result block:
; failure count, assertion count, first failed assertion. Normal builds omit it.
render_verify_units:
    move.l verify_c5(pc),d0
    btst #6,d0
    beq .done
    lea render_verify_results(pc),a0
    tst.l 4(a0)
    bne .done
    movem.l d0-a6,-(sp)
    move.w -28800(a4),-(sp)
    clr.w -28800(a4)
    moveq #0,d6
.angle
    lea .fractions(pc),a1
    moveq #4,d7
.fraction
    move.w d6,d4
    swap d4
    move.w (a1)+,d4
    move.l d4,d0
    jsr -32544(a4)
    mulu.w #80,d0
    move.l d0,d3
    move.l d4,d0
    moveq #80,d1
    bsr render_sine_width
    bsr .equal
    move.l d4,d0
    bsr render_sine_width
    bsr .equal
    move.w #-1,-28800(a4)
    lsr.l #1,d3
    move.l d4,d0
    bsr render_sine_width
    bsr .equal
    clr.w -28800(a4)
    dbf d7,.fraction
    addq.w #1,d6
    cmp.w #90,d6
    ble.b .angle
    move.w (sp)+,-28800(a4)
    move.l -22372(a4),-(sp)
    move.w -29852(a4),-(sp)
    lea .products(pc),a1
    moveq #27,d7
.product
    move.l (a1)+,d0
    move.w (a1)+,-29852(a4)
    move.l (a1)+,d3
    bsr render_fixed_product
    bsr .equal
    move.l -10(a1),-22372(a4)
    move.l (a1)+,d3
    bsr render_lateral_main
    bsr .equal
    dbf d7,.product
    move.w (sp)+,-29852(a4)
    move.l (sp)+,-22372(a4)
    movem.l (sp)+,d0-a6
.done
    rts
.equal
    lea render_verify_results(pc),a0
    addq.l #1,4(a0)
    cmp.l d3,d0
    beq.b .ok
    addq.l #1,(a0)
    tst.l 8(a0)
    bne.b .ok
    move.l 4(a0),8(a0)
.ok
    rts
.fractions: dc.w 0,1,16384,32768,65535
.products
    dc.l -65470465
    dc.w 1
    dc.l -1000
    dc.l -65469466
    dc.l -65470465
    dc.w 32768
    dc.l -32735233
    dc.l -65469466
    dc.l -65470465
    dc.w 65535
    dc.l -65469466
    dc.l -65469466
    dc.l -65470465
    dc.w 20480
    dc.l -20459521
    dc.l -65469466
    dc.l -65536
    dc.w 1
    dc.l -1
    dc.l -65535
    dc.l -65536
    dc.w 32768
    dc.l -32768
    dc.l -65535
    dc.l -65536
    dc.w 65535
    dc.l -65535
    dc.l -65535
    dc.l -65536
    dc.w 20480
    dc.l -20480
    dc.l -65535
    dc.l -32768
    dc.w 1
    dc.l -1
    dc.l -32768
    dc.l -32768
    dc.w 32768
    dc.l -16384
    dc.l -32768
    dc.l -32768
    dc.w 65535
    dc.l -32768
    dc.l -32768
    dc.l -32768
    dc.w 20480
    dc.l -10240
    dc.l -32768
    dc.l 0
    dc.w 1
    dc.l 0
    dc.l 0
    dc.l 0
    dc.w 32768
    dc.l 0
    dc.l 0
    dc.l 0
    dc.w 65535
    dc.l 0
    dc.l 0
    dc.l 0
    dc.w 20480
    dc.l 0
    dc.l 0
    dc.l 65535
    dc.w 1
    dc.l 0
    dc.l 65534
    dc.l 65535
    dc.w 32768
    dc.l 32767
    dc.l 65534
    dc.l 65535
    dc.w 65535
    dc.l 65534
    dc.l 65534
    dc.l 65535
    dc.w 20480
    dc.l 20479
    dc.l 65534
    dc.l 6569984
    dc.w 1
    dc.l 100
    dc.l 6569883
    dc.l 6569984
    dc.w 32768
    dc.l 3284992
    dc.l 6569883
    dc.l 6569984
    dc.w 65535
    dc.l 6569883
    dc.l 6569883
    dc.l 6569984
    dc.w 20480
    dc.l 2053120
    dc.l 6569883
    dc.l 65601535
    dc.w 1
    dc.l 1000
    dc.l 65600534
    dc.l 65601535
    dc.w 32768
    dc.l 32800767
    dc.l 65600534
    dc.l 65601535
    dc.w 65535
    dc.l 65600534
    dc.l 65600534
    dc.l 65601535
    dc.w 20480
    dc.l 20500479
    dc.l 65600534
    dc.b 'TDRENDER10',0
    even
render_verify_results: dc.l 0,0,0
    ENDC

render_subunit_start:
; After all original frame snapshots, while the game's Forbid is held.
render_latch:
    movem.l d0-d2/a0-a1,-(sp)
    IFD VERIFY
    bsr render_verify_fixture
    move.l verify_c5(pc),d0
    btst #3,d0
    beq.b .fractions
    clr.w -22338(a4)
    clr.w -22370(a4)
    clr.w -22362(a4)
    lea -29372(a4),a0
    moveq #11,d0
.zero
    clr.w (a0)
    addq.l #4,a0
    dbf d0,.zero
.fractions
    bsr render_verify_units
    ENDC
    IFD VERIFY
    move.l verify_c1(pc),d0
    btst #4,d0
    bne.b .bound
    ENDC
    bsr render_heading_latch
    lea render_traffic_active(pc),a0
    clr.w (a0)
    lea -29374(a4),a1
    moveq #11,d2
.traffic
    move.w (a1),d0
    beq.b .next_traffic
    sub.w -22340(a4),d0
    bpl.b .distance
    neg.w d0
.distance
    cmp.w #40,d0
    bge.b .next_traffic
    move.w #1,(a0)
    bra.b .traffic_done
.next_traffic
    addq.l #4,a1
    dbf d2,.traffic
.traffic_done
    ; A new root/data binding invalidates the exact memoisation cache.
    move.l -32542(a4),d0     ; target of the root sine jump-table entry
    lea render_sine_source(pc),a0
    cmp.l (a0),d0
    beq.b .bound
    move.l d0,(a0)
    lea render_sine_last_key(pc),a0
    move.l #-1,(a0)
.bound
    movem.l (sp)+,d0-d2/a0-a1
    jsr -32286(a4)           ; original Permit
    jsr -32178(a4)           ; original frame preparation
    rts

; Signed 16.16 lateral x * unsigned Q16 scale -> signed 16.16 screen x.
; Decompose before multiplying; retain the original signed integer product
; and add the unsigned fractional product. This also handles negative x.
render_lateral_product:
    move.l -22372(a4),d0
render_fixed_product:
    tst.w d0
    beq.b .integer
    move.l d1,-(sp)
    move.w d0,d1
    mulu.w -29852(a4),d1
    swap d1
    and.l #$ffff,d1
    swap d0
    tst.w d0
    bpl.b .positive
    neg.w d0
    mulu.w -29852(a4),d0
    neg.l d0
    bra.b .sum
.positive
    mulu.w -29852(a4),d0
.sum
    add.l d1,d0
    move.l (sp)+,d1
    rts
.integer
    swap d0
    tst.w d0
    bpl.b .positive_integer
    neg.w d0
    mulu.w -29852(a4),d0
    neg.l d0
    rts
.positive_integer
    mulu.w -29852(a4),d0
    rts
render_main_fraction:
    move.w -22338(a4),d0
    bne.b .nonzero
    IFD VERIFY
    move.l verify_c5(pc),d0
    btst #3,d0
    beq.b .integer_camera
    moveq #0,d0              ; zero oracle retains the original special case
    rts
.integer_camera
    ENDC
    move.w #32767,-29308(a4)
    move.w #59636,-29852(a4)
    add.l #$1c,(sp)          ; skip old zero seed, return through h4:$11A0 RTS
    rts
.nonzero
    neg.w d0
    rts

render_lateral_main:
    ; Near rows suppress the lane increment. Scaling this initial anchor by
    ; the camera-dependent first-row scale moves the whole road sideways at
    ; each integer crossing. Anchor at the original unit scale instead.
    ; floor(x * 65535 / 65536) = x - ceil(x / 65536), including negative x.
    move.l d1,-(sp)
    move.l -22372(a4),d0
    move.l d0,d1
    swap d1
    ext.l d1
    tst.w d0
    beq.b .integer
    addq.l #1,d1
.integer
    sub.l d1,d0
    move.l (sp)+,d1
    rts
render_lateral_mirror:
    ; Keep the original mirror's integer scaling in the zero oracle.
    IFD VERIFY
    move.l verify_c5(pc),d0
    btst #3,d0
    bne.b .integer
    ENDC
    move.l -22372(a4),d0
    move.l d0,d1
    lsl.l #2,d1
    add.l d1,d0
    asr.l #4,d0
    neg.l d0
    add.l #280*65536,d0
    move.l d0,-29844(a4)
    bra render_mirror_fraction
    IFD VERIFY
.integer
    move.w -22372(a4),d0
    move.w d0,d1
    lsl.w #2,d1
    add.w d1,d0
    asr.w #4,d0
    neg.w d0
    add.w #280,d0
    swap d0
    clr.w d0
    move.l d0,-29844(a4)
    bra render_mirror_fraction
    ENDC
; The rear walker runs towards decreasing segment numbers. Prefix the next
; camera segment by F, then walk the existing stream: scales decay by 0.91.
; At F=0 this is exactly the old rear seed; F=1 approaches the next camera's
; row 1. Main projection already has its own fractional first-span seed.
render_mirror_fraction:
    movem.l d0-d1/d3/a1-a2,-(sp)
    move.w -22338(a4),d3
    lsr.w #1,d3
    beq .done
    move.w -22340(a4),d0
    addq.w #1,d0
    cmp.w -26234(a4),d0
    bcc .done
    move.l -26232(a4),a1
    move.b (a1,d0.w),d0
    and.w #255,d0
    cmp.w #255,d0
    beq .done
    lsl.w #2,d0
    move.l -26228(a4),a2
    adda.w d0,a2
    move.b 1(a2),d0
    ext.w d0
    muls.w d3,d0
    asr.l #2,d0
    move.l d0,-29840(a4)
    ; The prefixed row has the original row-zero slope limit, zero.
    ; Prefix's curve starts at zero. Its lateral contribution is x*S/8.
    bsr render_lateral_product
    asr.l #3,d0
    asr.l #8,d0
    muls.w d3,d0
    asr.l #7,d0
    add.l d0,-29844(a4)
    move.w d3,d0
    mulu.w #5,d0             ; 8*$5000*F, in screen 16.16
    sub.l d0,-29848(a4)
    move.w #-1844,d0         ; high16($5000*$E8F5)-$5000
    muls.w d3,d0
    add.l d0,d0
    swap d0
    add.w d0,-29852(a4)
.done
    movem.l (sp)+,d0-d1/d3/a1-a2
    rts

; Keep the original integer lane multiply in the game. Add only its missing
; fraction at the two terminal updates. Separate fixed-point rounding differs
; from one wide product by at most one 16.16 LSB per row (under 1/1600 pixel
; across 40 rows). Zero fraction executes exactly the original ADD/SUB + RTS.
render_lateral_forward_step:
    add.l d0,-29844(a4)
    move.w -22370(a4),d1
    beq.b .done
    mulu.w -29852(a4),d1
    swap d1
    and.l #$ffff,d1
    lsr.l #2,d1
    move.l d1,d0
    lsr.l #2,d0
    sub.l d0,d1
    add.l d1,-29844(a4)
.done
    rts
render_lateral_rear_step:
    sub.l d0,-29844(a4)
    move.w -22370(a4),d1
    beq.b .done
    mulu.w -29852(a4),d1
    swap d1
    and.l #$ffff,d1
    lsr.l #3,d1
    add.l d1,-29844(a4)
.done
    rts

; Exact last-integer-angle cache of sine * 80; halve for the rear view.
; Fractional arguments vary on moving bends and rarely repeat: send them
; straight to the native full-16.16 interpolation without cache overhead.
render_sine_width:
    tst.l d0
    beq.b .zero
    tst.w d0
    bne.b .fractional
    cmp.l render_sine_last_key(pc),d0
    beq.b .cached
    move.l a0,-(sp)
    lea render_sine_last_key(pc),a0
    move.l d0,(a0)+
    jsr -32544(a4)
    mulu.w #80,d0
    move.l d0,(a0)
    move.l (sp)+,a0
    bra.b .width
.fractional
    jsr -32544(a4)
    mulu.w #80,d0
    bra.b .width
.cached
    move.l render_sine_last_value(pc),d0
.width
    tst.w -28800(a4)
    beq.b .zero
    lsr.l #1,d0
.zero
    rts
; Capture the stream once per view. Records are x/y/scale/crest, eight bytes;
; they are private projection samples, never simulation or road descriptors.
render_walk_start:
    movem.l d0/a0,-(sp)
    lea render_slope(pc),a0
    clr.l (a0)
    clr.w -29836(a4)
    lea render_lane_pending(pc),a0
    move.w #1,(a0)
    tst.w -28800(a4)
    beq.b .main
    clr.w (a0)
.main
    IFD VERIFY
    move.l verify_c5(pc),d0
    btst #3,d0              ; retain native lane arithmetic in the zero oracle
    beq.b .ready
    clr.w (a0)
.ready
    ENDC
    movem.l (sp)+,d0/a0
    move.w #39,d6
    rts
render_row:
    move.w render_lane_pending(pc),d0
    beq.b .metadata
    cmp.w #125,-29848(a4)
    bge.b .metadata
    bsr render_lane_seed
.metadata
    move.w render_traffic_active(pc),d0
    beq.b .original
    movem.l d2/a0,-(sp)
    move.w -29832(a4),d2
    lea render_last_row(pc),a0
    move.w d2,(a0)
    lsl.w #3,d2
    lea render_rows(pc),a0
    adda.w d2,a0
    move.w -29844(a4),(a0)+
    move.w -29848(a4),(a0)+
    move.w -29852(a4),(a0)+
    move.w -29834(a4),(a0)
    movem.l (sp)+,d2/a0
.original
    move.w -29844(a4),d0
    move.w -29848(a4),d1
    rts

; Native main-view lane accumulation starts after the y=125 near-plane
; cutoff. The first admitted row changes as the camera fraction advances.
; Its old fixed unit anchor therefore produced a sawtooth proportional to
; the player's lane offset, even on a straight road. Seed that first row
; from its scale instead. Subsequent native increments are 3/16 * lane * S,
; while S decays by 59637/65536, so the matching remaining lane projection
; is lane * S * 12288/5899. Keep the suppressed near rows and curve term.
; Once per forward view; no simulation state or raster shift is changed.
render_lane_seed:
    movem.l d0-d2/a0,-(sp)
    lea render_lane_pending(pc),a0
    clr.w (a0)
    bsr render_lateral_main
    add.l d0,-29844(a4)       ; remove the original unit-scale lane anchor
    bsr render_lateral_product
    lea render_lane_carry(pc),a0
    clr.w (a0)
    move.w #12288,d1
    move.w #5899,d2
    bsr sim_ratio
    sub.l d0,-29844(a4)
    movem.l (sp)+,d0-d2/a0
    rts
render_lane_pending: dc.w 0
render_lane_carry: dc.w 0

; Displaced scale-store plus metadata for traffic only. The original queue
; already bounds d3 to 0..396. Type 25..29 is forward slots 1..5; 16..20 is
; oncoming slots 0..4. Both arrays were latched atomically with the camera.
render_queue:
    lea -27596(a4),a0
    move.w -29852(a4),(a0,d3.w)
    move.w render_traffic_active(pc),d1
    beq.b .done
    ; d1/a0 are already saved by the original queue's enclosing MOVEM.
    lea render_car_fraction(pc),a0
    clr.w (a0,d3.w)
    move.w d2,d1
    sub.w #16,d1
    cmp.w #4,d1
    bhi.b .forward
    lsl.w #2,d1
    lea -29348(a4),a0
    bra.b .fraction
.forward
    move.w d2,d1
    sub.w #24,d1
    cmp.w #1,d1
    bcs.b .done
    cmp.w #5,d1
    bhi.b .done
    lsl.w #2,d1
    lea -29372(a4),a0
.fraction
    move.w (a0,d1.w),d1
    lsr.w #1,d1
    lea render_car_fraction(pc),a0
    move.w d1,(a0,d3.w)
    lea render_car_row(pc),a0
    move.w -29832(a4),(a0,d3.w)
.done
    rts

; Finish the streamed view before objects are drawn. Interpolate toward the
; next forward row / previous rear row. Camera fraction is ALREADY in road
; projection: applying it here again would move traffic twice. Leave the
; original near-plane fixed-scale rows and the final horizon row alone.
render_finish:
    move.w render_traffic_active(pc),d0
    beq .restore
    moveq #0,d7
    move.w -28798(a4),d6
    beq .restore
    subq.w #1,d6
    lea render_car_fraction(pc),a0
    lea render_car_row(pc),a1
    lea render_rows(pc),a2
.loop
    move.w (a0,d7.w),d5
    beq .next
    move.w (a1,d7.w),d0
    cmp.w #6,d0
    ble .next
    tst.w -28800(a4)
    bne.b .rear
    cmp.w render_last_row(pc),d0
    bge .next
    lsl.w #3,d0
    lea (a2,d0.w),a3
    lea 8(a3),a5
    bra.b .project
.rear
    lsl.w #3,d0
    lea (a2,d0.w),a3
    lea -8(a3),a5
.project
    move.w 4(a5),d0
    sub.w 4(a3),d0
    bsr render_car_delta
    move.w d0,d4             ; signed scale delta
    lea -27596(a4),a6
    add.w d4,(a6,d7.w)
    ; Perspective change of the original lane offset (including police AI).
    lea -28796(a4),a6
    move.w (a6,d7.w),d1
    sub.w (a3),d1
    muls.w d4,d1
    bpl.b .positive
    neg.l d1
    divu.w 4(a3),d1
    neg.w d1
    bra.b .lane
.positive
    divu.w 4(a3),d1
.lane
    add.w d1,(a6,d7.w)
    move.w (a5),d0
    sub.w (a3),d0
    bsr render_car_delta
    add.w d0,(a6,d7.w)
    ; Interpolate the already crest-clipped row heights, so a car does not
    ; emerge through a nearer hill. Keep the original y at zero fraction.
    move.w 2(a3),d1
    cmp.w 6(a3),d1
    ble.b .y0
    move.w 6(a3),d1
.y0
    move.w 2(a5),d0
    cmp.w 6(a5),d0
    ble.b .y1
    move.w 6(a5),d0
.y1
    sub.w d1,d0
    bsr render_car_delta
    lea -28396(a4),a6
    add.w d0,(a6,d7.w)
.next
    addq.w #2,d7
    dbf d6,.loop
.restore
    ; PL_P replaces the original MOVEM/RTS; the walker's entry owns this save.
    movem.l (sp)+,d0-a6
    rts
; Signed word difference * unsigned Q15 weight; d0 long -> integer word.
render_car_delta:
    muls.w d5,d0
    add.l d0,d0
    swap d0
    rts
; Retain fractional slope between segments. Interpolate the game's signed
; row-limit table with the camera so crest clipping follows the moving grid.
render_slope_begin:
    ; A flat descriptor and zero accumulator cannot change the slope. Skip
    ; the original weighting/multiply/clamp path in this frequent case.
    tst.b 2(a2)
    bne.b .original
    move.l render_slope(pc),d1
    bne.b .original
    rts
.original
    moveq #0,d1
    move.w -29852(a4),d1
    move.l sim_h4(pc),a3     ; scratch until the original clamp assigns it
    jmp $149c(a3)

render_slope_add:
    ; PL_P at h4:$14C8: the original MULS has already produced d0. Replace
    ; its SWAP/ADD and the remaining clamp/RTS tail. d0/d1/a3 are scratch in
    ; the original slope function; the next walker call rewrites d0/d1.
    IFD VERIFY
    move.l verify_c5(pc),d1
    btst #3,d1
    bne .original
    ENDC
    add.l render_slope(pc),d0
    move.w -29832(a4),d1
    cmp.w #16,d1
    bcs.b .near_limit
    move.l #40*65536,d1      ; every remaining native table entry is 40
    bra.b .clamp
.near_limit
    move.l d2,-(sp)
    lea -29894(a4),a3
    lea (a3,d1.w),a3
    moveq #0,d1
    move.b (a3),d1
    moveq #0,d2
    tst.w -28800(a4)
    bne.b .rear_limit
    tst.w -29832(a4)
    beq.b .integer_limit
    move.b -1(a3),d2
    bra.b .gradient
.rear_limit
    move.b 1(a3),d2
.gradient
    sub.w d1,d2
    beq.b .integer_limit
    bpl.b .positive_gradient
    neg.w d2
    mulu.w -22338(a4),d2
    neg.l d2
    bra.b .fractional_limit
.positive_gradient
    mulu.w -22338(a4),d2
.fractional_limit
    swap d1
    clr.w d1
    add.l d2,d1              ; each view's crest limit follows its row grid
    bra.b .restore
.integer_limit
    swap d1
    clr.w d1
.restore
    move.l (sp)+,d2
.clamp
    cmp.l d1,d0
    ble.b .low
    move.l d1,d0
    bra.b .store
.low
    neg.l d1
    cmp.l d1,d0
    bge.b .store
    move.l d1,d0
.store
    lea render_slope(pc),a3
    move.l d0,(a3)
    swap d0
    move.w d0,-29836(a4)
    lea -29836(a4),a3
    rts
    IFD VERIFY
.original
    swap d0
    add.w d0,-29836(a4)
    lea -29894(a4),a3
    move.w -29832(a4),d1
    move.b (a3,d1.w),d1
    ext.w d1
    move.w d1,d0
    neg.w d0
    lea -29836(a4),a3
    cmp.w (a3),d1
    bge.b .original_low
    move.w d1,(a3)
    bra.b .original_store
.original_low
    cmp.w (a3),d0
    ble.b .original_store
    move.w d0,(a3)
.original_store
    move.l a0,-(sp)
    lea render_slope(pc),a0
    move.w (a3),(a0)
    clr.w 2(a0)
    move.l (sp)+,a0
    rts
    ENDC

; Keep the original integer slope projection. Add only the fractional part
; at its terminal height update; its rounding error is <=1 fixed-point LSB.
render_height_fraction:
    sub.l d0,-29848(a4)
    move.w render_slope+2(pc),d0
    beq.b .done
    mulu.w -29852(a4),d0
    swap d0
    and.l #$ffff,d0
    lsr.l #2,d0
    tst.w -28800(a4)
    bne.b .rear
    sub.l d0,-29848(a4)
.done
    rts
.rear
    add.l d0,-29848(a4)
    rts

; Course heading is accumulated on segment crossings. Delay only that draw
; sample by one segment and interpolate; physics and wind phases are untouched.
; Rebase on the first frame or backward/wrapped course position.
render_heading_latch:
    lea render_heading_state(pc),a0
    move.l -22328(a4),d0
    move.w -22340(a4),d1
    move.w (a0),d2
    move.w d1,(a0)
    sub.w d2,d1
    beq.b .same
    cmp.w #-1,d2
    beq.b .reset
    tst.w d1
    ble.b .reset
    move.l 6(a0),2(a0)
    bra.b .current
.same
    move.l d0,d1
    sub.l 6(a0),d1
    add.l d1,2(a0)
    bra.b .current
.reset
    move.l d0,2(a0)
.current
    move.l d0,6(a0)
    sub.l 2(a0),d0
    bsr render_heading_wrap
    ; Course changes are <=16 degrees per segment. Bound unexpected jumps;
    ; reset rather than overflow the signed 16-bit interpolation multiply.
    asr.l #8,d0
    cmp.l #32767,d0
    bgt.b .raw
    cmp.l #-32768,d0
    blt.b .raw
    move.w -22338(a4),d1
    lsr.w #1,d1
    muls.w d1,d0
    asr.l #7,d0
    add.l 2(a0),d0
    bra.b .delta
.raw
    move.l 6(a0),d0
.delta
    move.w -29280(a4),d1
    swap d1
    clr.w d1
    sub.l d1,d0
    bsr render_heading_wrap
    move.l d0,10(a0)
    lea -29278(a4),a1
    move.l (a1)+,14(a0)
    move.l (a1)+,18(a0)
    move.l (a1)+,22(a0)
    move.l (a1),26(a0)
    rts
render_heading_wrap:
    cmp.l #180*65536,d0
    ble.b .low
    sub.l #360*65536,d0
.low
    cmp.l #-180*65536,d0
    bge.b .done
    add.l #360*65536,d0
.done
    rts
render_backdrop:
    IFD VERIFY
    move.l verify_c5(pc),d0
    btst #3,d0
    bne.b .original
    ENDC
    move.l d1,-(sp)
    lea render_heading_state(pc),a2
    move.l 10(a2),d0
    move.l d0,d1
    lsl.l #2,d0
    add.l d1,d0              ; first two layers: five pixels per degree
    cmp.w #8,d2
    bcs.b .layer
    add.l d1,d0              ; distant pair: six pixels per degree
.layer
    neg.l d0
    add.l 14(a2,d2.w),d0
    swap d0
.wraplow
    cmp.w #-400,d0
    bge.b .wraphigh
    add.w #800,d0
    bra.b .wraplow
.wraphigh
    cmp.w #400,d0
    ble.b .done
    sub.w #800,d0
    bra.b .wraphigh
.done
    move.l (sp)+,d1
    lea -23194(a4),a2        ; original image-array LEA
    rts
    IFD VERIFY
.original
    move.w (a2,d2.w),d0
    lea -23194(a4),a2
    rts
    ENDC
render_subunit_end:
render_traffic_active: dc.w 0
render_slope: dc.l 0
render_heading_state: dc.w -1
    dc.l 0,0,0,0,0,0,0

render_last_row: dc.w 0
render_rows: dcb.w 40*4,0
render_car_fraction: dcb.w 200,0
render_car_row: dcb.w 200,0

render_sine_last_key: dc.l -1
render_sine_last_value: dc.l 0
render_sine_source: dc.l 0
