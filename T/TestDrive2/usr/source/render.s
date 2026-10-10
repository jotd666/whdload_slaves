; v1 enhanced framerate (render_options bit 1): give the blitter bus priority
; (DMACON BLTPRI) and disable graphics.library's unused blitter-finished
; interrupt while the game runs.
; The CPU only polls BBUSY during shape blits, so its DMACONR reads no longer
; take the blitter's slots. Game code, waits and ownership are unchanged.
; Preserves the game entry's registers; restore puts back the original enables.
render_interrupt_option:
    movem.l d0/a0,-(sp)
    move.l render_options(pc),d0
    btst #1,d0
    beq.b .done
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
    move.l render_options(pc),d0
    btst #1,d0
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

; v1 enhanced framerate (render_options bit 2): project each view at the latched fractional road position.
; The bottom row and mirror horizon retain their original scales.
render_subunit_main:
    move.w #10,-7610(a4)
    movem.l d0-d6/a0-a3,-(sp)
    lea -26778(a4),a0
    lea -26868(a4),a1
    lea -26688(a4),a2
    lea -5632(a4),a3          ; main row 1, field 18
    moveq #42,d5
    moveq #-2,d6
    bra.b render_subunit_rows
render_subunit_mirror:
    move.w #20,-7610(a4)
    movem.l d0-d6/a0-a3,-(sp)
    lea -26966(a4),a0
    lea -27016(a4),a1
    lea -26916(a4),a2
    lea -5630(a4),a3          ; mirror row 1, field 20
    moveq #21,d5
    moveq #2,d6
RENDER_SCALE_ROW:MACRO
    move.w (a0)+,d0
    muls.w d4,d0
    add.l d0,d0
    swap d0
    add.w (a0)+,d0
    move.w d0,\1(a3)
    move.w (a0)+,d0
    muls.w d4,d0
    add.l d0,d0
    swap d0
    add.w (a0)+,d0
    move.w d0,(\1+4)(a3)
    move.w (a0)+,d0
    muls.w d4,d0
    add.l d0,d0
    swap d0
    add.w (a0)+,d0
    move.w d0,(\1+8)(a3)
    add.w d0,d0
    move.w (0,a1,d0.w),d0    ; exact width * 162; v1 table maximum is 300
    move.w d0,(\1+30)(a3)
    ENDM

render_subunit_rows:
    move.w -13392(a4),d4
    IFD VERIFY
    move.l sim_drive_enabled(pc),d0
    btst #3,d0
    beq.b .fraction
    moveq #0,d4
.fraction
    ENDC
    lsr.w #1,d4              ; unsigned Q15, safe for MULS
    move.l a3,-(sp)
    lea render_grade_main(pc),a3
    tst.w d6
    bmi.b .grade_view
    lea render_grade_mirror(pc),a3
.grade_view
    move.l a3,d2
    cmpa.l (a3),a0
    beq.b .grade_ready
    move.l a0,(a3)+
    move.w d5,d3
.grade_row
    move.w (0,a0,d6.w),d0
    sub.w (a0),d0
    move.w d0,(a3)+
    move.w (a0)+,(a3)+
    move.w (0,a1,d6.w),d0
    sub.w (a1),d0
    move.w d0,(a3)+
    move.w (a1)+,(a3)+
    move.w (0,a2,d6.w),d0
    sub.w (a2),d0
    move.w d0,(a3)+
    move.w (a2)+,(a3)+
    dbf d3,.grade_row
    lea render_scale_fraction(pc),a1
    tst.w d6
    bmi.b .grade_reset
    addq.w #2,a1
.grade_reset
    move.w #-1,(a1)
.grade_ready
    move.l d2,a0
    addq.w #4,a0
    lea render_width_products(pc),a1
    lea render_scale_fraction(pc),a3
    tst.w d6
    bmi.b .scale_view
    addq.w #2,a3
.scale_view
    cmp.w (a3),d4
    beq .reuse_scales
    move.w d4,(a3)
    move.l (sp)+,a3
    tst.w d6
    bpl .mirror_scales
render_scale_offset SET 0
    REPT 43
    RENDER_SCALE_ROW render_scale_offset
render_scale_offset SET render_scale_offset+52
    ENDR
    bra .seed
.mirror_scales
render_scale_offset SET 0
    REPT 22
    RENDER_SCALE_ROW render_scale_offset
render_scale_offset SET render_scale_offset+52
    ENDR
    bra.b .seed
.reuse_scales
    move.l (sp)+,a3
.seed
    lea -26166(a4),a1
    bsr render_subunit_tangent_bind
    bsr render_subunit_seed
    movem.l (sp)+,d0-d6/a0-a3
    rts

; Integrate only the visible fraction of the first segment. The original row
; walker still handles every complete segment; these seeds are renderer-only.
render_subunit_seed:
    tst.w d4
    beq.b .done
    move.w -13394(a4),d0
    addq.w #1,d0
    move.l -13148(a4),a0
    move.b (0,a0,d0.w),d0
    and.w #127,d0
    lsl.w #2,d0
    move.l -13152(a4),a0
    adda.w d0,a0
    move.b 1(a0),d2
    ext.w d2
    add.w d2,d2
    move.b 2(a0),d3
    ext.w d3
    lea -26166(a4),a1
    move.w d2,d0
    bsr.b render_subunit_angle
    tst.w d6
    bmi.b .main
    add.w d0,-14936(a4)
    move.w d3,d0
    bsr.b render_subunit_angle
    sub.w d0,-14932(a4)
    move.w -14932(a4),d0
    bsr.b render_subunit_lookup
    add.w d0,-14928(a4)
    move.w -14936(a4),d0
    bsr.b render_subunit_lookup
    add.w d0,-14930(a4)
.done
    rts
.main
    sub.w d0,-14936(a4)
    move.w d3,d0
    bsr.b render_subunit_angle
    add.w d0,-14932(a4)
    move.w -14932(a4),d0
    sub.w d3,d0
    bsr.b render_subunit_lookup
    sub.w d0,-14928(a4)
    move.w -14936(a4),d0
    add.w d2,d0
    bsr.b render_subunit_lookup
    sub.w d0,-14930(a4)
    rts
; Round 8.8 angle fractions so f -> 1 reaches the next lookup exactly.
render_subunit_angle:
    muls.w d4,d0
    add.l d0,d0
    add.l #$8000,d0
    swap d0
    rts
; Interpolated table value at the 8.8 angle d0, weighted by d4.
render_subunit_lookup:
    bsr render_subunit_tangent
    muls.w d4,d0
    add.l d0,d0
    swap d0
    rts

; The road walker reads the table at -26166(a4) at the high byte of the 8.8
; heading and slope angles, so steering swings the far rows ~10 pixels at a
; time and hills step vertically. Read it at the full angle, interpolating by
; the low byte.
; One hook replaces the walker's 073ec..0742a: slope lookup, height and row y,
; curve accumulation and heading lookup (PL_S skips the rest), so a row pays
; one call. d0 = heading table value out, as at 0742a; a1 = the table, as the
; replaced LEA set it. d1 and a2 are free: the walker reloads d1 at 0745a and
; a2 at the next row, and the curve byte is read before a2 is reused.
render_subunit_road_angles:
    move.b 1(a2),d1           ; curve accumulates first (07412)
    ext.w d1
    add.w d1,d1
    add.w d1,-14936(a4)
    lea -26166(a4),a1
    IFD VERIFY
    bsr.b render_subunit_zero_angles
    bne.b .slope_integer
    ENDC
    tst.b -14931(a4)          ; slope fraction
    bne.b .slope_fraction
.slope_integer
    move.b -14932(a4),d0      ; the original lookup
    ext.w d0
    add.w d0,d0
    move.w (0,a1,d0.w),d0
.slope
    add.w -14928(a4),d0
    move.w d0,-14928(a4)
    muls.w (18,a3,d6.w),d0
    swap d0
    add.w -7602(a4),d0
    move.w d0,12(a3)
    IFD VERIFY
    bsr.b render_subunit_zero_angles
    bne.b .heading_integer
    ENDC
    tst.b -14935(a4)          ; heading fraction
    bne.b .heading_fraction
.heading_integer
    move.b -14936(a4),d0
    ext.w d0
    add.w d0,d0
    move.w (0,a1,d0.w),d0
    rts
.heading_fraction
    move.w -14936(a4),d0
    bra.b render_subunit_tangent_cached
.slope_fraction
    move.w -14932(a4),d0      ; render_subunit_tangent_cached, inline
    lea render_tangent_cache(pc),a2
    move.w d0,d1
    and.w #1023,d1
    lsl.w #2,d1
    adda.w d1,a2
    cmp.w (a2),d0
    bne.b .slope_miss
    move.w 2(a2),d0
    bra.b .slope
.slope_miss
    bsr.b render_subunit_tangent_fill
    bra.b .slope
    IFD VERIFY
; Zero oracle: NE selects the original high-byte reads.
render_subunit_zero_angles:
    move.l sim_drive_enabled(pc),d1
    and.w #8,d1
    rts
    ENDC

; Exact memoisation of the immutable angle table. a2 is dead after the
; walker's curve read and after the coefficient loop in both seed callers.
; d0 = 8.8 angle in, table value out; d1/a2 destroyed.
render_subunit_tangent:
    tst.b d0
    bne.b render_subunit_tangent_cached
    asr.w #8,d0              ; integer angle (flat road, straight heading)
    add.w d0,d0
    move.w (0,a1,d0.w),d0
    rts
; d0 has a nonzero fraction.
render_subunit_tangent_cached:
    lea render_tangent_cache(pc),a2
    move.w d0,d1
    and.w #1023,d1
    lsl.w #2,d1
    adda.w d1,a2
    cmp.w (a2),d0
    bne.b render_subunit_tangent_fill
    move.w 2(a2),d0
    rts
; a2 = d0's bucket: interpolate by the low byte and store key and value.
render_subunit_tangent_fill:
    move.w d0,(a2)
    moveq #0,d1
    move.b d0,d1
    asr.w #8,d0
    add.w d0,d0
    cmp.w #254,d0
    beq.b .top
    swap d1
    move.w (0,a1,d0.w),d1
    move.w (2,a1,d0.w),d0
    sub.w d1,d0
    swap d1                  ; low word: fraction, high word: lower entry
    muls.w d1,d0
    asr.l #8,d0
    swap d1
    add.w d1,d0
    move.w d0,2(a2)
    rts
.top
    move.w (0,a1,d0.w),d0
    move.w d0,2(a2)
    rts
; Rebind on the first view or a new data hunk. Invalid keys differ from each
; bucket's index, including bucket 1023; no input can hit an empty entry.
render_subunit_tangent_bind:
    lea render_tangent_table(pc),a2
    cmpa.l (a2),a1
    beq.b .done
    move.l a1,(a2)+
    move.l #$ffff0000,d0
    move.w #1023,d1
.clear
    move.l d0,(a2)+
    dbf d1,.clear
    clr.w -4(a2)
.done
    rts
; Per-view immutable gradients plus their source-table identity.
render_grade_main: dc.l 0
    dcb.w 43*6,0
render_grade_mirror: dc.l 0
    dcb.w 22*6,0
render_width_index SET 0
render_width_products:
    REPT 301
    dc.w render_width_index*162
render_width_index SET render_width_index+1
    ENDR
render_scale_fraction: dc.w -1,-1
render_tangent_table: dc.l 0
render_tangent_cache: dcb.l 1023,$ffff0000
    dc.l 0

; The simulation changes the player's heading and lateral position, and the
; road's curve sum, only as the car enters a segment, so the car, the road's
; angle and the mountains move sideways in steps. Latch each segment's values
; and draw at F between the last observed heading/mountain samples: one
; segment late at low speed. Lateral delays only one crossing displacement;
; other lane changes and recovery still apply at once.
render_subunit_segment:
    movem.l d0-d5/a0-a1,-(sp)
    IFD VERIFY
    move.l sim_drive_enabled(pc),d0
    btst #3,d0
    bne .done                ; zero oracle: keep the original snapshots
    ENDC
    move.w -13390(a4),d3
    ext.l d3
    asl.l #8,d3              ; heading, 16.16
    move.l -13382(a4),d4     ; lateral snapshot, 16.16
    bsr render_subunit_curve_sum
    move.l d0,d5
    sub.l d3,d5              ; mountains: curve sum - heading
    lea render_segment(pc),a0
    move.w -13394(a4),d0
    move.w (a0),d1
    move.w d0,(a0)+
    sub.w d1,d0
    beq.b .same
    cmp.w #-2,d1
    beq.b .reset
    tst.w d0
    bgt.b .next              ; retain history even across several segments
.reset
    movem.l d3-d5,(a0)       ; first frame, backward reset or course wrap
    lea render_scale_fraction(pc),a1
    move.l #-1,(a1)
    bra.b .current
.next
    move.l 12(a0),(a0)
    move.l 20(a0),8(a0)
    bra.b .current
.same
    move.l d3,d0             ; previous += new - latched
    sub.l 12(a0),d0
    add.l d0,(a0)
    move.l d5,d0
    sub.l 20(a0),d0
    add.l d0,8(a0)
.current
    movem.l d3-d5,12(a0)
    move.w -13392(a4),d2
    lsr.w #1,d2              ; unsigned Q15
    move.l 12(a0),d0
    move.l (a0)+,d1
    bsr.b render_subunit_lerp
    asr.l #8,d0
    tst.w d0
    bpl.b .quarter
    addq.w #3,d0
.quarter
    asr.w #2,d0              ; signed /4 towards zero, as duel:06464
    move.w d0,-13388(a4)
    ; Only the sine-driven crossing displacement is delayed. AI lane changes
    ; and recovery move the raw snapshot immediately, even on a crossing.
    move.w -13390(a4),d0
    asr.w #8,d0
    move.w d0,d1
    bpl.b .positive
    neg.w d0
.positive
    cmp.w #90,d0
    bls.b .bounded
    moveq #90,d0
.bounded
    add.w d0,d0
    lea -24628(a4),a1        ; the simulation's sine table at duel:0aff4
    move.w (0,a1,d0.w),d0
    lsr.w #1,d0
    tst.w d1
    bpl.b .motion
    neg.w d0
.motion
    muls.w #144,d0           ; simulation subtracts this once per segment
    add.l d4,d0
    move.l d0,(a0)           ; previous lateral = raw - crossing delta
    move.l 12(a0),d0
    move.l (a0)+,d1
    bsr.b render_subunit_lerp
    move.l d0,-13382(a4)
    move.l 12(a0),d0
    move.l (a0)+,d1
    bsr.b render_subunit_lerp
    move.l d0,render_backdrop-render_segment-14(a0)
.done
    movem.l (sp)+,d0-d5/a0-a1
    rts
; d0 = latched, d1 = previous, d2 = Q15 weight -> d0 = d1 + (d0 - d1) x d2
render_subunit_lerp:
    sub.l d1,d0
    asr.l #8,d0
    cmp.l #32767,d0
    bgt.b .far
    cmp.l #-32768,d0
    blt.b .far
    muls.w d2,d0
    asr.l #7,d0
    add.l d1,d0
    rts
.far
    asl.l #8,d0
    add.l d1,d0
    rts
; d0 = 16.16 curve sum up to the camera segment. The simulation task adds each
; segment's curve x 1024 as it enters it; the frame's camera may differ by one.
render_subunit_curve_sum:
    movem.l d1-d3/a0,-(sp)
.consistent
    move.w -17234(a4),d3     ; last segment added to the sum
    move.l -13398(a4),d2
    cmp.w -17234(a4),d3
    bne.b .consistent
    move.w -13394(a4),d0
    sub.w d0,d3
    beq.b .done
    cmp.w #-1,d3
    beq.b .behind
    cmp.w #1,d3
    bne.b .done
    addq.w #1,d0
    bsr.b render_subunit_curve
    neg.l d0
    bra.b .adjust
.behind
    bsr.b render_subunit_curve
.adjust
    add.l d0,d2
.done
    move.l d2,d0
    movem.l (sp)+,d1-d3/a0
    rts
; d0.w = segment -> d0.l = its curve byte x 1024, as the walker at 08a2e.
render_subunit_curve:
    move.l -13148(a4),a0
    move.b (0,a0,d0.w),d0
    and.w #127,d0
    add.w d0,d0
    add.w d0,d0
    move.l -13152(a4),a0
    move.b (1,a0,d0.w),d0
    ext.w d0
    swap d0
    clr.w d0
    asr.l #6,d0
    rts
; Mountains: 4 pixels per unit of the latched offset, rounded. d2 out, d1 free.
render_subunit_backdrop:
    IFD VERIFY
    move.l sim_drive_enabled(pc),d2
    btst #3,d2
    beq.b .latched
    move.w -13398(a4),d2     ; zero oracle: the original instructions
    move.w -13390(a4),d1
    asr.w #8,d1
    sub.w d1,d2
    lsl.w #2,d2
    rts
.latched
    ENDC
    move.l render_backdrop(pc),d2
    add.l #$2000,d2
    asr.l #8,d2
    asr.l #6,d2
    rts
render_segment: dc.w -2         ; segment, then previous and latched
    dc.l 0,0,0,0,0,0            ; heading, lateral, mountains
render_backdrop: dc.l 0

; Frame snapshots: traffic origins share one fraction per direction.
render_subunit_latch:
    move.l -13318(a4),-13366(a4)
    movem.l d0/a0,-(sp)
    lea render_traffic_fractions(pc),a0
    move.w -13468(a4),(a0)+
    move.w -13464(a4),(a0)
    movem.l (sp)+,d0/a0
    bra render_subunit_segment

render_subunit_forward:
    add.w d2,d0
    move.w 12(a3),d1
    movem.l d2-d4/a1,-(sp)
    move.w render_traffic_fractions(pc),d4
    moveq #0,d3
    bra.b render_subunit_object
render_subunit_oncoming:
    add.w d1,d0
    move.w 12(a3),d1
    movem.l d2-d4/a1,-(sp)
    move.w render_traffic_fractions+2(pc),d4
    moveq #1,d3
render_subunit_object:
    bsr render_subunit_neighbour
    beq.b .done
    move.w (26,a1,d6.w),d2
    lsr.w #1,d2
    tst.w d3
    bne.b .oncoming
    cmp.w #25,2(a0)
    beq.b .centre
    neg.w d2
    add.w 4(a1),d2
    bra.b .x
.oncoming
    cmp.w #17,2(a0)
    beq.b .left_centre
    add.w 2(a1),d2
    bra.b .x
.left_centre
    neg.w d2
.centre
    add.w 10(a1),d2
.x
    bsr render_subunit_xy
.done
    movem.l (sp)+,d2-d4/a1
    rts
render_subunit_opponent:
    add.w d2,d0
    move.w 12(a3),d1
    movem.l d2-d4/a1,-(sp)
    move.w -13372(a4),d4
    move.w -13370(a4),d3
    bra.b render_subunit_car
render_subunit_police:
    add.w d2,d0
    move.w 12(a3),d1
    movem.l d2-d4/a1,-(sp)
    move.w -13364(a4),d4
    move.w -13362(a4),d3
render_subunit_car:
    bsr render_subunit_neighbour
    beq.b .done
    move.w d3,d2
    bpl.b .positive
    neg.w d2
.positive
    mulu.w (48,a1,d6.w),d2
    tst.w d3
    bpl.b .scaled
    neg.l d2
.scaled
    swap d2
    add.w 10(a1),d2
    bsr render_subunit_xy
.done
    movem.l (sp)+,d2-d4/a1
    rts
; Road rows already subtract the camera fraction. Add only the car fraction;
; subtracting the camera twice would create a sawtooth at constant separation.
render_subunit_neighbour:
    IFD VERIFY
    move.l sim_drive_enabled(pc),d2
    btst #3,d2
    bne.b .zero
    ENDC
    tst.w 46(a3)
    beq.b .bottom
    lsr.w #1,d4
    beq.b .done
    lea 52(a3),a1
    tst.w d6
    bne.b .mirror
    cmp.w #43,46(a3)         ; no row beyond the horizon
    beq.b .zero
    bra.b .ready
.mirror
    lea -52(a3),a1
.ready
    tst.w d4
.done
    rts
; The fixed bottom row has no camera displacement. Use the relative fraction
; there, extrapolating from row 1 for a car beyond the viewport's near edge.
.bottom
    moveq #0,d2
    move.w -13392(a4),d2
    and.l #$ffff,d4
    tst.w d6
    beq.b .relative
    exg d2,d4
.relative
    sub.l d2,d4
    asr.l #1,d4
    lea 52(a3),a1
    tst.w d4
    rts
.zero
    moveq #0,d4
    rts
; d0/d1 = matched x/y, d2 = neighbour x, d4 = Q15 weight (signed at row 0).
render_subunit_xy:
    sub.w d0,d2
    muls.w d4,d2
    add.l d2,d2
    swap d2
    add.w d2,d0
    move.w 12(a1),d2
    sub.w d1,d2
    muls.w d4,d2
    add.l d2,d2
    swap d2
    add.w d2,d1
    rts
render_traffic_fractions: dc.w 0,0

    IFD VERIFY
verify_render_units:
    move.l sim_drive_enabled(pc),-(sp)
    lea sim_drive_enabled(pc),a0
    clr.l (a0)
    lea -5702(a4),a3
    lea verify_render_cases(pc),a2
    moveq #8,d7
.case
    move.w (a2)+,d6
    move.w (a2)+,46(a3)
    move.w (a2)+,-13392(a4)
    move.w (a2)+,d4
    bsr render_subunit_neighbour
    move.w d4,d0
    ext.l d0
    move.w (a2)+,d1
    ext.l d1
    bsr verify_equal
    dbf d7,.case
    move.w #1,46(a3)
    moveq #0,d6
    move.w #$ffff,d4
    bsr render_subunit_neighbour
    move.l a1,d0
    sub.l a3,d0
    moveq #52,d1
    bsr verify_equal
    moveq #2,d6
    move.w #$ffff,d4
    bsr render_subunit_neighbour
    move.l a1,d0
    sub.l a3,d0
    moveq #-52,d1
    bsr verify_equal
    lea sim_drive_enabled(pc),a0
    move.l #8,(a0)
    move.w #$ffff,d4
    bsr render_subunit_neighbour
    move.l d4,d0
    moveq #0,d1
    bsr verify_equal
    move.l (sp)+,(a0)
    rts
    dc.b "TD2RENDERCHECK",0
    even
verify_render_cases:
    ; view, row, camera fraction, car fraction, signed Q15 weight
    dc.w 0,43,0,$8000,0
    dc.w 0,0,$4000,$4000,0
    dc.w 2,0,$4000,$4000,0
    dc.w 0,0,$8000,0,-16384
    dc.w 0,0,0,$ffff,32767
    dc.w 2,0,0,$ffff,-32768
    dc.w 2,0,$ffff,0,32767
    dc.w 0,1,0,$ffff,32767
    dc.w 2,1,0,$ffff,32767
    ENDC

    IFD VERIFY
; Give both identity arms the same scanline input, including unused fields
; that the original pass otherwise retains from an earlier view or frame.
render_zero_main:
    bsr render_zero_table
    move.l d0,-(sp)
    move.l render_options(pc),d0
    btst #2,d0
    movem.l (sp)+,d0
    bne render_subunit_main
    move.w #10,-7610(a4)
    rts
render_zero_mirror:
    bsr render_zero_table
    move.l d0,-(sp)
    move.l render_options(pc),d0
    btst #2,d0
    movem.l (sp)+,d0
    bne render_subunit_mirror
    move.w #20,-7610(a4)
    rts
render_zero_table:
    movem.l d0-d1/a0,-(sp)
    lea -7574(a4),a0
    moveq #0,d0
    move.w #467,d1           ; 117 lines; row records begin immediately after
.clear
    move.l d0,(a0)+
    dbf d1,.clear
    movem.l (sp)+,d0-d1/a0
    rts
    ENDC

    IFD VERIFY
; A straight segment still advances laterally when the camera is turned.
verify_render_seed:
    lea -13100(a4),a0
    clr.w (a0)
    move.l a0,-13148(a4)
    lea -13090(a4),a0
    clr.l (a0)
    move.l a0,-13152(a4)
    clr.w -13394(a4)
    clr.w -26166(a4)
    move.w #8,-26164(a4)
    move.w #-8,-26168(a4)
    lea -26166(a4),a1
    bsr render_subunit_tangent_bind
    moveq #1,d7
.view
    move.w #256,-14936(a4)
    moveq #-2,d6
    tst.w d7
    bne.b .main
    neg.w -14936(a4)
    moveq #2,d6
.main
    clr.w -14932(a4)
    move.w #83,-14928(a4)
    clr.w -14930(a4)
    move.w #16384,d4
    bsr render_subunit_seed
    move.w -14930(a4),d0
    ext.l d0
    moveq #-4,d1
    bsr verify_equal
    dbf d7,.view
    rts
    dc.b "TD2SEEDCHECK",0
    even
    ENDC

    IFD VERIFY
; Exercise empty keys, collisions, fractional negatives and table rebinding.
verify_render_tangent:
    lea -26422(a4),a0
    move.w #-540,d0          ; t[index] = 100 + 5 * index
    move.w #255,d7
.fill
    move.w d0,(a0)+
    addq.w #5,d0
    dbf d7,.fill
    lea render_tangent_table(pc),a0
    clr.l (a0)
    lea -26166(a4),a1
    bsr render_subunit_tangent_bind
    moveq #-1,d0
    bsr render_subunit_tangent
    ext.l d0
    moveq #99,d1
    bsr verify_equal
    move.w #1023,d0          ; collides with angle -1
    bsr render_subunit_tangent
    ext.l d0
    moveq #119,d1
    bsr verify_equal
    moveq #-1,d0
    bsr render_subunit_tangent
    ext.l d0
    moveq #99,d1
    bsr verify_equal
    moveq #0,d0
    bsr render_subunit_tangent
    ext.l d0
    moveq #100,d1
    bsr verify_equal
    move.w #32767,d0         ; final index has no neighbour
    bsr render_subunit_tangent
    ext.l d0
    move.w #735,d1
    bsr verify_equal
    lea -25000(a4),a1
    move.w #200,(a1)
    bsr render_subunit_tangent_bind
    moveq #0,d0
    bsr render_subunit_tangent
    ext.l d0
    move.w #200,d1
    bsr verify_equal
    ; Walker hook: slope index 1 + half (105 -> 110) adds 107 to the height
    ; accumulator; the curve byte 1(a2) = 2 moves heading 0 -> 4 (index 0,
    ; fraction 4/256 of 100 -> 105: 100).
    lea -26166(a4),a1
    bsr render_subunit_tangent_bind
    move.w #$0180,-14932(a4)
    clr.w -14928(a4)
    clr.w -14936(a4)
    lea verify_render_curve(pc),a2
    lea -5702(a4),a3
    moveq #0,d6
    bsr render_subunit_road_angles
    ext.l d0
    moveq #100,d1
    bsr verify_equal
    move.w -14928(a4),d0
    ext.l d0
    moveq #107,d1
    bsr verify_equal
    rts
verify_render_curve: dc.b 0,2,0,0
    dc.b "TD2HORIZCHECK",0
    dc.b "TD2SLOPECHECK",0
    even
    ENDC
