; VERIFY-only frozen render poses. C4 bit 3 enables the fixture; bits 5..7
; select the track offset and bits 8..15 supply camera/AI fraction. C2=0 is
; the native pixel oracle. The zero-fraction fixture also selects native
; integer angle reads, as the TD2 zero-angle oracle does.
verify_render_pose:
    movem.l d0-a6,-(sp)
    move.l $4.w,a6
    jsr _LVODisable(a6)
    move.w #1,-31736(a4)
    clr.w -29944(a4)
    clr.w -29976(a4)
    clr.w -29522(a4)
    clr.w -20714(a4)
    clr.w -29516(a4)
    lea render_crossing(pc),a0
    clr.l (a0)             ; frozen pose has no completed crossing
    clr.w -31424(a4)
    clr.w -31416(a4)
    move.l sim_verify_options(pc),d0
    move.w d0,d1
    and.w #$e0,d0
    add.w d0,d0
    add.w #32,d0
    ext.l d0
    add.l -29998(a4),d0
    move.l d0,-30016(a4)
    move.l d0,-30010(a4)
    lsr.w #8,d1
    move.w d1,-30012(a4)
    move.w d1,-30006(a4)
    lea -94(a4),a0
    lea -54(a4),a1
    lea -214(a4),a5
    lea -174(a4),a2
    sub.l #16,d0
    moveq #9,d2
.cars
    clr.w (a5)+            ; native size-family hysteresis
    move.l d0,(a0)+
    move.w d1,(a1)+
    move.w #480,(a2)+
    addq.l #4,d0
    dbf d2,.cars
    bsr render_pose_latch
    move.l $4.w,a6
    jsr _LVOEnable(a6)
    move.l custom2(pc),d0
    beq.b .native
    bsr render_subunit
.native
    movem.l (sp)+,d0-a6
    jsr -32490(a4)          ; original $72a2: car buckets
    jsr -32592(a4)          ; original $72a6: main road geometry
    rts

; Synthetic tables exercise signed interpolation and Q8 carries without any
; embedded game data. Called before the first live frame; canonical data are
; filled from the game afterwards (render_tables_ready is still zero).
verify_render_units:
    movem.l d0-a6,-(sp)
    lea verify_render_values(pc),a0
    lea verify_render_next(pc),a1
    move.l a0,(a1)
    move.l sim_verify_options(pc),-(sp)
    lea sim_verify_options(pc),a0
    clr.l (a0)
    move.l #65536,d0
    move.l #$10001,d1
    move.l $4.w,a6
    jsr _LVOAllocMem(a6)
    tst.l d0
    bne.b .allocated
    moveq #1,d1
    bsr verify_render_equal
    bra .exit
.allocated
    move.l d0,a4
    adda.l #32766,a4
    lea -22184(a4),a0
    moveq #0,d0
    moveq #88,d1
.angles
    move.b d0,(a0)+
    addq.w #2,d0
    dbf d1,.angles
    bsr render_angle_setup
    lea verify_render_angles(pc),a2
    moveq #7,d7
.angle
    move.w (a2)+,d4
    bsr render_angle
    move.w d4,d0
    ext.l d0
    move.w (a2)+,d1
    ext.l d1
    bsr verify_render_equal
    dbf d7,.angle
    lea render_main_y(pc),a0
    move.w #200,d0
    moveq #40,d1
.main
    move.w d0,(a0)+
    subq.w #2,d0
    dbf d1,.main
    lea render_mirror_y(pc),a0
    move.w #100,d0
    moveq #20,d1
.mirror
    move.w d0,(a0)+
    subq.w #2,d0
    dbf d1,.mirror
    lea -1516(a4),a0
    move.w #200,d0
    moveq #79,d1
.near
    move.w d0,(a0)+
    subq.w #2,d0
    dbf d1,.near
    move.w #$1080,d4
    bsr render_car_depth
    moveq #34,d5
    bsr render_car_y
    move.w d5,d0
    ext.l d0
    move.w #165,d1
    bsr verify_render_equal
    move.w #$19f,d4
    bsr render_car_depth
    add.w #16,d6            ; native $8f92, after the hooked reduction
    bsr render_car_near_y
    move.w d5,d0
    ext.l d0
    move.w #158,d1
    bsr verify_render_equal
    move.l #100,-30010(a4)
    move.l #97,-90(a4)
    move.w #64,-30006(a4)
    move.w #128,-52(a4)
    moveq #2,d2
    bsr render_mirror_car_y
    move.w d5,d0
    ext.l d0
    moveq #94,d1
    bsr verify_render_equal
    ; Equivalent representation across the fraction carry: 99 + 256/256.
    move.l #99,-30010(a4)
    move.w #320,-30006(a4)
    bsr render_mirror_car_y
    move.w d5,d0
    ext.l d0
    moveq #94,d1
    bsr verify_render_equal
    ; Last-crossing interpolation, including zero/full fraction and signs.
    lea verify_camera_vectors(pc),a2
    moveq #12,d6
.camera
    lea render_pose+6(pc),a0
    move.l (a2)+,(a0)
    move.w (a2)+,d7
    bsr render_camera_fraction
    move.w render_heading(pc),d0
    ext.l d0
    move.w (a2)+,d1
    ext.l d1
    bsr verify_render_equal
    move.w render_lateral(pc),d0
    ext.l d0
    move.w (a2)+,d1
    ext.l d1
    bsr verify_render_equal
    dbf d6,.camera
    ; Canonical coefficients, not integer row indices: positive, negative,
    ; zero and maximum fractions. Each output lies between its neighbours.
    lea verify_projection_vectors(pc),a2
    moveq #7,d6
.projection
    move.l a2,a0
    moveq #0,d1
    moveq #2,d2
    move.w 4(a2),d7
    bsr render_project_value
    ext.l d0
    move.w 6(a2),d1
    ext.l d1
    bsr verify_render_equal
    addq.l #8,a2
    dbf d6,.projection
    ; Full-depth car X: fractional coefficient and bounded road-centre rows.
    lea verify_car_coefficients(pc),a2
    moveq #7,d6
.car_coefficient
    move.l a2,a0
    lea render_car_row(pc),a1
    move.w 4(a2),(a1)
    moveq #0,d5
    bsr render_car_coefficient
    and.l #$ffff,d0
    moveq #0,d1
    move.w 6(a2),d1
    bsr verify_render_equal
    addq.l #8,a2
    dbf d6,.car_coefficient
    lea -25484(a4),a0
    move.w #400,d0
    moveq #111,d1
.car_road
    move.w d0,(a0)+
    subq.w #3,d0
    dbf d1,.car_road
    lea verify_car_centres(pc),a2
    moveq #5,d6
.car_centre
    lea render_car_row(pc),a0
    move.w (a2)+,(a0)
    move.w (a2)+,d4
    tst.w (a2)+
    bne.b .car_mirror
    bsr render_car_center
    bra.b .car_result
.car_mirror
    bsr render_mirror_car_center
.car_result
    move.w d4,d0
    ext.l d0
    move.w (a2)+,d1
    ext.l d1
    bsr verify_render_equal
    dbf d6,.car_centre
    ; Near/far X join with deliberately different synthetic endpoints.
    move.w #2047,d4
    bsr render_car_depth
    add.w #16,d6
    bsr render_car_near_y
    moveq #0,d0
    move.w render_car_row(pc),d0
    move.l #45600,d1       ; 58*256 + (182-58)*31*8
    bsr verify_render_equal
    move.w d5,d0
    ext.l d0
    moveq #56,d1           ; original near-table vertical placement
    bsr verify_render_equal
    ; Every normal size/facing and the excluded spin path. The caller's native
    ; number-bank addition remains active in both cases.
    move.l attnflags(pc),d0
    btst #AFB_68020,d0
    beq.b .anchors_done
    move.w #32,-27630(a4)
    lea verify_car_anchor_x(pc),a2
    moveq #0,d6
.anchor
    moveq #0,d2
    move.w #-1,-29974(a4)
    move.w #160,d4
    moveq #100,d1
    bsr render_car_anchor
    move.w d4,d0
    ext.l d0
    move.w (a2)+,d1
    ext.l d1
    bsr verify_render_equal
    clr.w -29974(a4)
    move.w #160,d4
    moveq #100,d1
    bsr render_car_anchor
    move.w d4,d0
    ext.l d0
    move.l #160,d1
    bsr verify_render_equal
    addq.w #4,d6
    cmp.w #96,d6
    bne.b .anchor
.anchors_done
    ; Independent sign projection: rows 80/82, signed lane 256, both sides.
    ; The scratch A4 needs the native multiply stub used by the production path.
    move.w #$4ef9,-32550(a4)
    move.l sim_code(pc),d0
    add.l #$9e54,d0
    move.l d0,-32548(a4)
    move.l _resload(pc),a2
    jsr resload_FlushCache(a2) ; the scratch jump stub was just written
    lea render_main_y(pc),a0
    move.w #82,2(a0)
    move.w #80,4(a0)
    move.w #2048,-612+160(a4)
    move.w #3072,-612+162(a4)
    move.w #4096,-612+164(a4)
    lea render_lengths(pc),a0
    move.w #256,2(a0)
    move.w #100,-772+160(a4)
    move.w #110,-772+162(a4)
    move.w #120,-772+164(a4)
    move.w #20,-692+160(a4)
    move.w #25,-692+162(a4)
    move.w #30,-692+164(a4)
    move.w #256,-25020+4(a4)
    move.w #12,-1998(a4)    ; selected sprite height
    move.w #4,-1996(a4)     ; X hotspot
    move.w #6,-1994(a4)     ; Y hotspot, used only by native fallback
    lea verify_sign_vectors(pc),a2
    moveq #4,d7
.sign
    lea render_fraction(pc),a0
    move.w (a2)+,(a0)
    move.w #256,d0
    sub.w (a0),d0
    move.w d0,-708(a4)
    move.w (a2)+,-24348+4(a4)
    move.w (a2)+,-30580(a4)
    lea -2000(a4),a0
    moveq #4,d3
    moveq #95,d5
    move.w #300,d0
    moveq #100,d1
    bsr render_sign_position
    move.w d1,d6
    ext.l d0
    move.w (a2)+,d1
    ext.l d1
    bsr verify_render_equal
    move.w d6,d0
    ext.l d0
    move.w (a2)+,d1
    ext.l d1
    bsr verify_render_equal
    dbf d7,.sign
    ; Restore scratch state before the first real protected snapshot.
    lea render_pose(pc),a0
    moveq #8,d0
.clear_pose
    clr.w (a0)+
    dbf d0,.clear_pose
    move.l a4,a1
    suba.l #32766,a1
    move.l #65536,d0
    move.l $4.w,a6
    jsr _LVOFreeMem(a6)
.exit
    lea sim_verify_options(pc),a0
    move.l (sp)+,(a0)
    movem.l (sp)+,d0-a6
    rts
verify_projection_vectors:
    dc.w 100,300,0,100, 100,300,128,200, 100,300,255,299
    dc.w 300,100,0,300, 300,100,128,200, 300,100,255,100
    dc.w 17,17,255,17, 100,99,1,99
verify_render_angles:
    dc.w 0,0,128,1,255,1,256,2,-128,-1,-256,-2,-257,-3,22528,176

verify_render_equal:
    movem.l a0-a1,-(sp)
    lea verify_render_next(pc),a0
    move.l (a0),a1
    move.l d0,(a1)+
    move.l d1,(a1)+
    move.l a1,(a0)
    movem.l (sp)+,a0-a1
    bra verify_sim_equal
verify_render_next: dc.l 0
verify_render_values: ds.l 240

; actual steering step, actual lateral step, F, heading/lateral corrections
verify_camera_vectors:
    dc.w 128,9,0,-128,-9
    dc.w 128,9,128,-64,-5
    dc.w 128,9,255,-1,-1
    dc.w 128,9,256,0,0
    dc.w -128,-9,0,128,9
    dc.w -128,-9,128,64,4
    dc.w -128,-9,255,0,0
    dc.w -128,-9,256,0,0
    dc.w 0,2,128,0,-1
    dc.w 0,-2,128,0,1
    dc.w 128,0,128,-64,0
    dc.w -128,0,128,64,0
    dc.w 0,0,128,0,0

; coefficient endpoints, Q8 row fraction, interpolated coefficient
verify_car_coefficients:
    dc.w 1000,2000,0,1000, 1000,2000,1,1003
    dc.w 1000,2000,128,1500, 1000,2000,255,1996
    dc.w 2000,1000,0,2000, 2000,1000,1,1996
    dc.w 2000,1000,128,1500, 2000,1000,255,1003
; Q8 row, lateral pixel offset, mirror flag, final X on road 400-3*y
verify_car_centres:
    dc.w 80*256,0,0,160, 80*256+128,-100,0,58
    dc.w 110*256+255,100,0,170, 119*256,-100,0,-30
    dc.w 20*256+128,100,1,438, 28*256,-100,1,219

; Corrected draw X at a fixed projected X=160, independently stated endpoints.
verify_car_anchor_x:
    dc.w 160,160,160,160,159,159,157,157
    dc.w 160,160,160,159,159,159,160,160
    dc.w 160,160,160,160,162,162,164,163

; F, sign flags, view, draw X, draw Y
verify_sign_vectors:
    dc.w 0,8,0,284,84
    dc.w 128,8,0,295,84
    dc.w 255,8,0,320,84
    dc.w 128,12,0,37,84
    dc.w 128,8,1,296,94
