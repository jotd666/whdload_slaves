; v1 render-only Q8 projection. Canonical tables are copied from the loaded game,
; never reconstructed from constants or cumulatively interpolated. Interpolation
; never writes live physics; the crossing recorder preserves the native update.
; All callers are gated by CUSTOM2.

; Native $2b5e rebuilds mirror/row tables at outer-session setup ($9ee),
; not between qualifying and its race. Restore the
; canonical inputs first, then invalidate the last projected fraction. Keeping
; the saved originals avoids deriving a new mirror from shifted main Y values.
render_reset_tables:
    movem.l d0/a0-a1,-(sp)
    move.w render_tables_ready(pc),d0
    beq.b .done
    lea render_main_y(pc),a0
    lea -31280(a4),a1
    moveq #40,d0
.main
    move.w (a0)+,(a1)+
    dbf d0,.main
    lea -1104(a4),a1
    moveq #20,d0
.mirror
    move.w (a0)+,(a1)+
    dbf d0,.mirror
    lea -710(a4),a1
    moveq #39,d0
.length
    move.w (a0)+,(a1)+
    dbf d0,.length
    lea render_fraction(pc),a0
    move.w #-1,(a0)
.done
    movem.l (sp)+,d0/a0-a1
    move.l sim_code(pc),a0
    adda.l #$2b5e,a0
    jsr (a0)               ; original $9ee: native table initialization
    clr.w 4118(a4)          ; original $9f2
    rts

; Called inside the existing balanced latch, with its MOVEM frame still live.
render_pose_latch:
    lea render_pose(pc),a0
    move.w -29976(a4),(a0)+
    move.w -29522(a4),(a0)+
    move.w -20714(a4),(a0)+
    move.l render_crossing(pc),(a0) ; actual steering/lateral crossing deltas
    rts

; Called after Enable: all table work is outside the interrupt exclusion.
render_subunit:
    lea render_fraction(pc),a3
    moveq #0,d7
    move.b -30005(a4),d7
    bsr render_camera_fraction
    cmp.w (a3),d7
    bne.b .changed
    tst.w render_tables_ready-render_fraction(a3)
    bne.w .done             ; exact cache: canonical tables depend only on F
.changed
    move.w d7,(a3)
    tst.w render_tables_ready-render_fraction(a3)
    bne.b .ready
    lea -31280(a4),a0
    lea render_main_y(pc),a1
    moveq #40,d0
.copy_main
    move.w (a0)+,(a1)+
    dbf d0,.copy_main
    lea -1104(a4),a0
    moveq #20,d0
.copy_mirror
    move.w (a0)+,(a1)+
    dbf d0,.copy_mirror
    lea -710(a4),a0
    moveq #39,d0
.copy_length
    move.w (a0)+,(a1)+
    dbf d0,.copy_length
    bsr render_angle_setup
    move.w #1,render_tables_ready-render_fraction(a3)
.ready
    ; Main: each boundary approaches the preceding boundary as the camera
    ; advances. Keep the clipped bottom and horizon endpoints fixed.
    lea render_main_y+4(pc),a0
    lea -31276(a4),a1
    moveq #6,d6              ; only indices 2..8 have a gap greater than one
.main
    move.w -2(a0),d0
    sub.w (a0),d0
    mulu.w d7,d0
    lsr.l #8,d0
    add.w (a0)+,d0
    move.w d0,(a1)+
    dbf d6,.main
    ; Mirror: boundaries recede, hence interpolate toward the next entry.
    lea render_mirror_y+4(pc),a0
    lea -1100(a4),a1
    moveq #1,d6              ; only indices 2..3 have a gap greater than one
.mirror
    move.w (a0),d0
    sub.w 2(a0),d0
    mulu.w d7,d0
    lsr.l #8,d0
    neg.w d0
    add.w (a0)+,d0
    move.w d0,(a1)+
    dbf d6,.mirror
    ; The v1 far Y gaps are zero or one, hence floor(F*gap/256) is zero for
    ; every F<256. Their maps and the native projection-selection list remain
    ; exact. Only main rows 86..111 and mirror rows 21..22 can change. The local
    ; exhaustive model checks all 256 fractions against the full reconstruction.
    lea -31280(a4),a0
    lea 3876(a4),a1
    lea 3960(a4),a2
    moveq #86,d0
    moveq #25,d1
    moveq #16,d2
    bsr render_row_map
    lea -1104(a4),a0
    lea 3776(a4),a1
    lea 3820(a4),a2
    moveq #21,d0
    moveq #1,d1
    moveq #6,d2
    bsr render_row_map
    ; Partial first integration interval, followed by the shifted lengths.
    lea render_lengths(pc),a0
    lea -710(a4),a1
    moveq #39,d6
    moveq #0,d1
.length
    move.w (a0)+,d2
    move.w d1,d0
    sub.w d2,d0
    muls.w d7,d0
    asr.l #8,d0
    add.w d2,d0
    move.w d0,(a1)+
    move.w d2,d1
    dbf d6,.length
.done
    rts

; a0=Y, a1=flags, a2=indices; d0=first row, d1=row count-1,
; d2=last Y byte index. All indices stay at or above the clipped bottom.
render_row_map:
.row
    cmp.w (a0,d2.w),d0
    ble.b .found
    subq.w #2,d2
    bra.b .row
.found
    seq d3
    ext.w d3
    move.w d3,(a1)+
    move.w d2,d3
    lsr.w #1,d3
    move.w d3,(a2)+
    addq.w #1,d0
    dbf d1,.row
    rts

render_main_pose:
    move.w render_pose(pc),d4
    add.w render_lateral(pc),d4
    move.w d4,-25018(a4)
    move.w render_pose+2(pc),d4
    add.w render_heading(pc),d4
    move.w d4,-25020(a4)
    rts
render_mirror_pose:
    bra render_main_pose

; Mirror's first interval grows as the camera moves away from the rear road.
; Remaining native half-segment intervals and the signed shift are unchanged.
render_mirror_step:
    asr.w #1,d4
    cmp.w #2,d3
    bne.b .done
    movem.l d0-d1,-(sp)
    move.w render_fraction(pc),d0
    move.w d4,d1
    muls.w d0,d1
    asr.l #8,d1
    add.w d1,d4
    movem.l (sp)+,d0-d1
.done
    lea -25020(a4),a0
    rts

render_horizon_pose:
    add.w render_pose+4(pc),d0
    sub.w render_pose+2(pc),d0
    sub.w render_heading(pc),d0
    rts
render_scenery_pose:
    move.w render_pose+4(pc),d4
    sub.w render_pose+2(pc),d4
    sub.w render_heading(pc),d4
    rts

; Record the exact native crossing displacement, after its steering clamp.
; Replays h0:$7a70..$7aaa, including the native signed angle lookup, lateral
; limit and attract-mode inhibit. The next CMP ($7aac) sets NZVC anew; X is kept.
; Only private draw history is added; game data and registers remain native.
render_camera_crossing:
    movem.l d0/a1,-(sp)
    lea render_crossing(pc),a1
    move.w -29976(a4),d0
    move.w d1,d4
    asr.w #1,d6
    move.w d6,(a1)
    add.w d6,d4
    add.w -29516(a4),d4
    move.w d4,-29522(a4)
    move.b -29522(a4),d4
    ext.w d4
    jsr -32460(a4)
    add.w -29976(a4),d4
    clr.w 2(a1)
    cmp.w #0,3598(a4)
    bne.b .done
    cmp.w #4480,d4
    blt.b .lower
    move.w #4480,d4
.lower
    cmp.w #-4480,d4
    bgt.b .write
    move.w #-4480,d4
.write
    move.w d4,-29976(a4)
    movea.w d4,a1
    suba.w d0,a1           ; address arithmetic preserves native X
    move.l a1,d0
    lea render_crossing(pc),a1
    move.w d0,2(a1)
.done
    movem.l (sp)+,d0/a1
    rts

; Race/qualifying setup must not inherit the last crossing of the previous run.
; Pause and pit return keep the existing crossing, just as they keep position.
render_camera_start:
    move.l a0,-(sp)
    lea render_crossing(pc),a0
    clr.l (a0)
    move.l (sp)+,a0
    move.w #0,-31736(a4)   ; native $707a: release the race-setup gate
    rts

; Interpolate the last completed crossing, rather than predict the next one.
; At F=0 subtract that crossing's exact displacement; at F=256 use the raw
; pose. Therefore changing steering, grip and lateral clamps cannot create a
; correction at the boundary. Delay only steering yaw: the road walker already
; accounts for curvature through its shortened first interval, and cumulative
; course heading cancels that same curve in the panorama. Both views use this
; one atomically latched pose. Non-crossing moves (e.g. recovery) remain immediate.
; d7=F, preserved. Run even on a projection-table cache hit.
render_camera_fraction:
    move.w d7,d0
    sub.w #256,d0
    move.w render_pose+6(pc),d1
    muls.w d0,d1
    asr.l #8,d1
    lea render_heading(pc),a0
    move.w d1,(a0)
    move.w render_pose+8(pc),d1
    muls.w d0,d1
    asr.l #8,d1
    move.w d1,render_lateral-render_heading(a0)
    rts

; Horizontal projection previously discarded the fractional screen Y before
; selecting perspective, road width and shoulder width. A one-row step can move
; a nearby shoulder by ten pixels. Interpolate all three canonical lookup
; values at segment depth instead, shared by road edges and roadside sprites.
; The existing distinct-row selector, clipping and sprite sizes stay native.
render_main_projection:
    movem.l d1-d2/d4/d7/a1-a2,-(sp)
    lea render_main_y(pc),a1
    move.w (a1,d3.w),d1
    move.w d1,d2
    cmp.w #2,d3
    beq.b .endpoint
    cmp.w #80,d3
    beq.b .endpoint
    move.w -2(a1,d3.w),d2
.endpoint
    lea -612(a4),a0
    lea -772(a4),a1
    lea -692(a4),a2
    bra.b render_projection
render_mirror_projection:
    movem.l d1-d2/d4/d7/a1-a2,-(sp)
    ; The native shared selection list also visits unused indices beyond
    ; the 21-entry mirror table. Preserve those lookups without reading past
    ; our canonical copy; only mirror indices 2..19 are interpolated.
    move.w d5,d1
    lsr.w #1,d1
    move.w d1,d2
    cmp.w #40,d3
    bcc.b .endpoint
    lea render_mirror_y(pc),a1
    move.w (a1,d3.w),d1
    move.w d1,d2
    cmp.w #2,d3
    beq.b .endpoint
    move.w 2(a1,d3.w),d2
.endpoint
    lea -972(a4),a0
    lea -1198(a4),a1
    lea -1044(a4),a2
render_projection:
    add.w d1,d1
    add.w d2,d2
    move.w render_fraction(pc),d7
    bsr render_project_value
    move.w d0,-(sp)
    move.l a0,-(sp)
    move.l a1,a0
    bsr render_project_value
    lea render_project_width(pc),a1
    move.w d0,(a1)+
    move.l a2,a0
    bsr render_project_value
    move.w d0,(a1)
    move.l (sp)+,a0
    move.w (sp)+,d0
    movem.l (sp)+,d1-d2/d4/d7/a1-a2
    rts

; a0=canonical row lookup, d1/d2=neighbour row byte indices, d7=F.
; Signed floor division handles decreasing mirror coefficients as well.
render_project_value:
    move.w (a0,d1.w),d0
    move.w (a0,d2.w),d4
    sub.w d0,d4
    beq.b .done
    muls.w d7,d4
    asr.l #8,d4
    add.w d4,d0
.done
    rts
render_projection_width:
    move.w render_project_width(pc),d6
    rts
render_projection_left:
    sub.w render_project_margin(pc),d4
    rts
render_projection_right:
    add.w render_project_margin(pc),d0
    rts

; Preserve the full relative Q8 depth before the native sprite/bucket selector
; reduces it to eighth segments. That selector remains unchanged.
render_car_depth:
    move.l a0,-(sp)
    lea render_depth(pc),a0
    move.w d4,(a0)
    move.l (sp)+,a0
    lsr.w #5,d4
    move.w d4,d6
    lsl.w #1,d6
    rts

; Cars project their own relative Q8 depth through canonical tables. The road
; tables already include camera fraction; using those here would count it twice.
render_car_y:
    movem.l d0-d1,-(sp)
    lea render_main_y(pc),a0
    move.w (a0,d5.w),d0
    cmp.w #78,d5
    bcc.b .done
    move.w 2(a0,d5.w),d1
    sub.w d0,d1
    move.w render_depth(pc),d5
    and.w #255,d5
    muls.w d5,d1
    asr.l #8,d1
    add.w d1,d0
.done
    move.w d0,d5
    movem.l (sp)+,d0-d1
    rts

render_car_near_y:
    movem.l d0-d1,-(sp)
    lea -1516(a4),a0
    move.w (a0,d6.w),d5
    move.w 2(a0,d6.w),d0
    sub.w d5,d0
    move.w render_depth(pc),d1
    and.w #31,d1
    muls.w d1,d0
    asr.l #5,d0
    add.w d0,d5
    movem.l (sp)+,d0-d1
    rts

render_mirror_car_y:
    movem.l d0-d1/d4,-(sp)
    move.w d2,d0
    add.w d0,d0
    lea -94(a4),a0
    move.l -30010(a4),d1
    sub.l (a0,d0.w),d1
    lsl.w #8,d1
    add.w -30006(a4),d1
    lea -54(a4),a0
    sub.w (a0,d2.w),d1
    move.w d1,d0
    lsr.w #8,d0
    add.w d0,d0
    cmp.w #2,d0
    bcc.b .far
    moveq #2,d0
    moveq #0,d1
.far
    cmp.w #38,d0
    bcs.b .lookup
    moveq #38,d0
    moveq #0,d1
.lookup
    lea render_mirror_y(pc),a0
    move.w (a0,d0.w),d5
    move.w 2(a0,d0.w),d4
    sub.w d5,d4
    and.w #255,d1
    muls.w d1,d4
    asr.l #8,d4
    add.w d4,d5
    movem.l (sp)+,d0-d1/d4
    rts

; Expand the native odd byte table once into signed word neighbours. This
; keeps interpolation bounded-cost on long curves, with no cache misses.
render_angle_setup:
    lea -22184(a4),a0
    lea render_angle_values+176(pc),a1
    move.l a1,a2
    moveq #88,d0
.copy
    moveq #0,d1
    move.b (a0)+,d1
    move.w d1,(a1)+
    neg.w d1
    move.w d1,(a2)
    subq.l #2,a2
    dbf d0,.copy
    rts

; Signed Q8 floor-index neighbours, including -1..0. The native $9e2e
; clamp and the integer fast path keep the upper neighbour at or below 88.
render_angle:
    tst.b d4
    beq.b render_angle_integer
    IFD VERIFY
    btst #3,sim_verify_options+3(pc)
    beq.b .live
    move.l a0,-(sp)
    lea sim_verify_options(pc),a0
    tst.b 2(a0)
    move.l (sp)+,a0
    beq.b render_angle_integer
.live
    ENDC
    movem.l d0-d1,-(sp)
    move.w d4,d0
    asr.w #8,d0
    add.w d0,d0
    lea render_angle_values+176(pc),a0
    move.w (a0,d0.w),d1
    move.w 2(a0,d0.w),d0
    sub.w d1,d0
    and.w #255,d4
    mulu.w d4,d0
    lsr.l #8,d0
    add.w d1,d0
    move.w d0,d4
    lea -22184(a4),a0
    movem.l (sp)+,d0-d1
    rts
render_angle_integer:
    asr.w #8,d4
    move.l sim_code(pc),a0
    adda.l #$9e92,a0
    jmp (a0)               ; unchanged native signed integer lookup

render_depth: dc.w 0

render_fraction: dc.w 0
render_tables_ready: dc.w 0
render_pose: ds.w 5
render_heading: dc.w 0
render_lateral: dc.w 0
render_crossing: dc.w 0,0
render_project_width: dc.w 0
render_project_margin: dc.w 0
render_main_y: ds.w 41
render_mirror_y: ds.w 21
render_lengths: ds.w 40

; Signed integer angles -88..88, decoded from the loaded game at setup.
render_angle_values: ds.w 177
