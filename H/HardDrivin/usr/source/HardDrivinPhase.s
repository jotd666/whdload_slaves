; Experimental incremental native-endpoint integration for grounded automatic
; driving. Other modes retain the existing reference path. Not acceptance-ready.
_phase_install:
 movem.l d0/a0-a2,-(a7)
 lea _phase_tail_ptr(pc),a0
 move.l _code_start(pc),d0
 addi.l #$ba8a,d0
 move.l d0,(a0)+
 move.l _code_start(pc),d0
 addi.l #$b9ba,d0
 move.l d0,(a0)
 lea _phase_patches(pc),a0
 movea.l _code_start(pc),a1
 movea.l _resload(pc),a2
 jsr resload_Patch(a2)
 movem.l (a7)+,d0/a0-a2
 rts
_phase_patches:
 PL_START
 ; PERF_RANGE VERIFY_DRIVETRAIN_PHASE $0b904 $0008: incremental RPM before automatic gear decision
 PL_PSS $b904,_phase_gear,2
 PL_END
_phase_tail_ptr: dc.l 0
_phase_manual_ptr: dc.l 0
PH_VALID equ 0
PH_ACTIVE equ 2
PH_PHASE equ 4
PH_INTERVAL equ 6
PH_LEFT equ 8
PH_DT equ 10
PH_ANCHOR_V equ 12
PH_CURRENT_V equ 16
PH_ANCHOR_R equ 20
PH_CURRENT_R equ 24
PH_FORECAST equ 28
PH_GEAR equ 32
PH_LAST_V equ 34
PH_LAST_R equ 36
PH_LAST_G equ 38
PH_LAST_POS equ 40
PH_CALLS equ 52
PH_FRAMES equ 56
PH_VECTOR equ 60
PH_BRAKE equ 72
PH_REMAIN equ 74
 dc.b 'HDPHASE1'
_phase_state: dcb.b 76,0
_phase_reset:
 move.l a0,-(a7)
 lea _phase_state(pc),a0
 clr.w PH_VALID(a0)
 clr.w PH_ACTIVE(a0)
 movea.l (a7)+,a0
 rts
_phase_frame:
 movem.l d0-d7/a0-a6,-(a7)
 lea _phase_state(pc),a6
 IFD VERIFY_DISPATCH_NATIVE
 bra .fallback
 ENDC
 move.w _time_scalar_fields(pc),d0
 beq .fallback
 move.b _dispatch_state+DS_ACTIVE(pc),d1
 beq .fallback
 tst.b -$69fa(a4)
 bne .fallback
 tst.b -$50cf(a4)
 bne .fallback
 ; Native turning-force input is evaluated by every engine segment.
 cmpi.b #15,-$66f0(a4)
 bne .fallback
 tst.w -$66f2(a4)
 bne .fallback
 tst.b -$16b6(a4)
 beq .fallback
 tst.w -$66b8(a4)
 bne .fallback
 tst.w -$66ba(a4)
 bne .fallback
 tst.b -$66c2(a4)
 beq .fallback
 cmpi.w #1,-$66ca(a4)
 blt .fallback
 cmpi.w #4,-$66ca(a4)
 bgt .fallback
 tst.w -$66d8(a4)
 bmi .fallback
 cmpi.w #2000,-$66d8(a4)
 bgt .fallback
 move.w d0,PH_INTERVAL(a6)
 move.w d0,PH_LEFT(a6)
 moveq #0,d0
 move.b -$66ef(a4),d0
 move.w d0,PH_BRAKE(a6)
 tst.w PH_VALID(a6)
 beq.s .initialize
 move.w -$66d8(a4),d0
 cmp.w PH_LAST_V(a6),d0
 bne.s .initialize
 move.w -$66d6(a4),d0
 cmp.w PH_LAST_R(a6),d0
 bne.s .initialize
 move.w -$66ca(a4),d0
 cmp.w PH_LAST_G(a6),d0
 bne.s .initialize
 lea -$6704(a4),a0
 lea PH_LAST_POS(a6),a1
 moveq #2,d1
.pose:
 move.l (a0)+,d0
 cmp.l (a1)+,d0
 bne.s .initialize
 dbf d1,.pose
 bra.s .ready
.initialize:
 bsr _phase_initialize
 tst.l d0
 beq .fallback
.ready:
 addq.l #1,PH_FRAMES(a6)
 lea _drivetrain_state(pc),a0
 move.w PH_INTERVAL(a6),(a0)
 move.w #1,6(a0)
 addq.l #1,12(a0)
.loop:
 moveq #8,d0
 sub.w PH_PHASE(a6),d0
 move.w d0,PH_REMAIN(a6)
 cmp.w PH_LEFT(a6),d0
 bls.s .chunk
 move.w PH_LEFT(a6),d0
.chunk:
 move.w d0,PH_DT(a6)
 lea _drivetrain_state(pc),a0
 move.w #2,2(a0)
 cmp.w PH_LEFT(a6),d0
 bne.s .not_last
 move.w #1,2(a0)
.not_last:
 addq.l #1,8(a0)
 addq.l #1,PH_CALLS(a6)
 bsr _phase_prepare_anchor
 move.w #1,PH_ACTIVE(a6)
 bsr _phase_engine_call
 clr.w PH_ACTIVE(a6)
 move.l PH_FORECAST(a6),d0
 lea PH_VECTOR(a6),a0
 bsr _phase_project
 bsr _phase_add_position
 cmpi.w #8,PH_PHASE(a6)
 bne.s .continued
 move.w -$66ca(a4),d0
 cmp.w PH_GEAR(a6),d0
 beq.s .same_gear
 move.w d0,PH_GEAR(a6)
 moveq #0,d0
 move.w -$66d6(a4),d0
 swap d0
 move.l d0,PH_CURRENT_R(a6)
.same_gear:
 move.l PH_CURRENT_V(a6),PH_ANCHOR_V(a6)
 move.l PH_CURRENT_R(a6),PH_ANCHOR_R(a6)
 clr.w PH_PHASE(a6)
.continued:
 move.w PH_DT(a6),d0
 sub.w d0,PH_LEFT(a6)
 bne .loop
 lea _time_scalar_fields(pc),a0
 move.w PH_INTERVAL(a6),(a0)
 lea _drivetrain_state(pc),a0
 move.w #2,6(a0)
 movem.l (a7)+,d0-d7/a0-a6
 pea _phase_published(pc)
 move.l _drivetrain_position(pc),-(a7)
 rts
.fallback:
 clr.w PH_VALID(a6)
 clr.w PH_ACTIVE(a6)
 movem.l (a7)+,d0-d7/a0-a6
 bra _drivetrain_reference_frame
_phase_engine_call:
 move.l _drivetrain_engine(pc),-(a7)
 rts
_phase_initialize:
 lea _time_scalar_state(pc),a0
 moveq #0,d0
 move.w -$66d8(a4),d0
 cmp.w SS_VELOCITY_LAST(a0),d0
 beq.s .velocity_current
 clr.w SS_VELOCITY_CARRY(a0)
.velocity_current:
 swap d0
 move.w SS_VELOCITY_CARRY(a0),d1
 ext.l d1
 lsl.l #8,d1
 lsl.l #5,d1
 add.l d1,d0
 bmi.s .invalid
 move.l d0,PH_ANCHOR_V(a6)
 move.l d0,PH_CURRENT_V(a6)
 moveq #0,d0
 move.w -$66d6(a4),d0
 cmp.w SS_RPM_LAST(a0),d0
 bne.s .rpm_stale
 move.w -$66ca(a4),d1
 cmp.w SS_RPM_GEAR(a0),d1
 beq.s .rpm_current
.rpm_stale:
 clr.w SS_RPM_CARRY(a0)
.rpm_current:
 swap d0
 move.w SS_RPM_CARRY(a0),d1
 ext.l d1
 lsl.l #8,d1
 lsl.l #5,d1
 add.l d1,d0
 bmi.s .invalid
 move.l d0,PH_ANCHOR_R(a6)
 move.l d0,PH_CURRENT_R(a6)
 move.w -$66ca(a4),PH_GEAR(a6)
 clr.w PH_PHASE(a6)
 move.w #1,PH_VALID(a6)
 ; Normalize existing integer/fraction position carries without losing motion.
 lea _motion_position_state+8(pc),a0
 lea _projection_state+24(pc),a1
 lea -$6704(a4),a2
 moveq #2,d4
.merge:
 move.l (a0),d0
 lsl.l #8,d0
 add.l d0,d0
 add.l (a1),d0
 bsr _time_split_q16
 add.l d0,(a2)+
 move.l d2,(a1)+
 clr.l (a0)+
 dbf d4,.merge
 moveq #1,d0
 rts
.invalid:
 moveq #0,d0
 rts
_phase_prepare_anchor:
 lea _time_scalar_fields(pc),a0
 move.w #8,(a0)
 lea _time_scalar_state(pc),a0
 clr.w SS_VELOCITY_CARRY(a0)
 clr.w SS_RPM_CARRY(a0)
 move.l PH_ANCHOR_V(a6),d0
 swap d0
 move.w d0,-$66d8(a4)
 move.w d0,SS_VELOCITY_LAST(a0)
 move.l PH_ANCHOR_R(a6),d0
 swap d0
 move.w d0,-$66d6(a4)
 move.w d0,SS_RPM_LAST(a0)
 move.w PH_GEAR(a6),d0
 move.w d0,-$66ca(a4)
 move.w d0,SS_RPM_GEAR(a0)
 lsl.w #2,d0
 lea -$733c(a4),a0
 adda.w d0,a0
 move.w 2(a0),-(a7)
 move.w (a0),-(a7)
 move.w -$66d6(a4),-(a7)
 jsr -$7f5c(a4)
 addq.l #6,a7
 move.w #140,-(a7)
 move.w #500,-(a7)
 move.w d0,-(a7)
 jsr -$7f5c(a4)
 addq.l #6,a7
 move.w d0,-$66da(a4)
 move.w PH_BRAKE(a6),d0
 move.b d0,-$66ef(a4)
 rts
_phase_gear:
 movem.l d0-d7/a0-a2,-(a7)
 moveq #0,d0
 roxl.b #1,d0
 move.w d0,-(a7)
 lea _phase_state(pc),a2
 tst.w PH_ACTIVE(a2)
 beq.s .restore
 move.w PH_DT(a2),d1
 move.w PH_REMAIN(a2),d2
 lea PH_ANCHOR_V(a2),a0
 move.w -$66d8(a4),d0
 bsr _phase_scalar_step
 move.l d0,PH_FORECAST(a2)
 lea PH_ANCHOR_R(a2),a0
 move.w -$66d6(a4),d0
 bsr _phase_scalar_step
 move.l PH_CURRENT_V(a2),d0
 swap d0
 move.w d0,-$66d8(a4)
 move.l PH_CURRENT_R(a2),d0
 swap d0
 move.w d0,-$66d6(a4)
 move.w PH_DT(a2),d0
 add.w d0,PH_PHASE(a2)
 cmpi.w #8,PH_PHASE(a2)
 beq.s .restore
 move.l _phase_tail_ptr(pc),46(a7)
.restore:
 move.w (a7)+,d0
 lsr.b #1,d0
 movem.l (a7)+,d0-d7/a0-a2
 tst.b -$66c2(a4)
 bne.s .done
 move.l _phase_manual_ptr(pc),(a7)
.done:
 rts
_phase_add_position:
 lea PH_VECTOR(a6),a0
 lea _projection_state+24(pc),a1
 lea -$6704(a4),a2
 moveq #2,d4
.axis:
 move.l (a0)+,d0
 asr.l #3,d0
 move.l d0,d3
 move.w PH_DT(a6),d1
 subq.w #1,d1
 moveq #0,d0
.times:
 add.l d3,d0
 dbf d1,.times
 add.l (a1),d0
 bsr _time_split_q16
 add.l d0,(a2)+
 move.l d2,(a1)+
 dbf d4,.axis
 rts
_phase_published:
 movem.l d0-d7/a0-a6,-(a7)
 moveq #0,d0
 roxl.b #1,d0
 move.w d0,-(a7)
 lea _phase_state(pc),a6
 lea _time_scalar_state(pc),a0
 move.w -$66d8(a4),d0
 move.w d0,PH_LAST_V(a6)
 move.w d0,SS_VELOCITY_LAST(a0)
 move.w PH_CURRENT_V+2(a6),d0
 lsr.w #8,d0
 lsr.w #5,d0
 move.w d0,SS_VELOCITY_CARRY(a0)
 move.w -$66d6(a4),d0
 move.w d0,PH_LAST_R(a6)
 move.w d0,SS_RPM_LAST(a0)
 move.w PH_CURRENT_R+2(a6),d0
 lsr.w #8,d0
 lsr.w #5,d0
 move.w d0,SS_RPM_CARRY(a0)
 move.w -$66ca(a4),d0
 move.w d0,PH_LAST_G(a6)
 move.w d0,SS_RPM_GEAR(a0)
 lea -$6704(a4),a0
 lea PH_LAST_POS(a6),a1
 moveq #2,d0
.save:
 move.l (a0)+,(a1)+
 dbf d0,.save
 move.l PH_CURRENT_V(a6),d0
 lea PH_VECTOR(a6),a0
 bsr _phase_project
 lea PH_VECTOR(a6),a0
 lea -$66e2(a4),a1
 lea _projection_state(pc),a2
 moveq #2,d4
.fractions:
 moveq #0,d0
 move.w (a1)+,d0
 swap d0
 move.l (a0)+,d1
 sub.l d0,d1
 move.l d1,(a2)+
 dbf d4,.fractions
 lea _drivetrain_state(pc),a0
 clr.w 6(a0)
 move.w (a7)+,d0
 lsr.b #1,d0
 movem.l (a7)+,d0-d7/a0-a6
 rts

; A0: native-phase anchor Q16, current Q16. D0: unsigned endpoint word.
; D1: newly consumed fields, D2: fields remaining before this update.
; 1 <= D1 <= D2 <= 8. Anchor is a nonnegative Q3 value in Q16 storage.
; Return D0: forecast Q16 at the phase end using only future input.
; Update current at A0+4. D3-D5 scratch; all other registers preserved.
_phase_scalar_step:
 moveq #0,d3
 move.w d0,d3
 swap d3
 sub.l (a0),d3
 asr.l #3,d3
 move.l 4(a0),d0
 move.w d2,d4
 move.w d2,d5
 sub.w d1,d5
.loop:
 add.l d3,d0
 subq.w #1,d4
 cmp.w d5,d4
 bne.s .next
 move.l d0,4(a0)
.next:
 tst.w d4
 bne.s .loop
 rts

; D0.L nonnegative Q16 forecast, at Q6 precision, velocity <=21842.
; A0 -> three Q16 projected components. All registers preserved.
_phase_project:
 movem.l d0-d7/a0-a1,-(a7)
 suba.w #12,a7
 movea.l a7,a1
 move.l d0,d7
 andi.l #$ffff,d7
 lsr.w #8,d7
 lsr.w #2,d7
 swap d0
 move.w d0,d5
 bsr _projection_integer_components
 move.w d0,(a1)
 move.w d1,2(a1)
 move.w d2,4(a1)
 move.w d5,d0
 addq.w #1,d0
 bsr _projection_integer_components
 move.w d0,6(a1)
 move.w d1,8(a1)
 move.w d2,10(a1)
 moveq #2,d6
.axis:
 move.w 6(a1),d0
 sub.w (a1),d0
 muls.w d7,d0
 lsl.l #8,d0
 lsl.l #2,d0
 moveq #0,d1
 move.w (a1)+,d1
 swap d1
 add.l d1,d0
 move.l d0,(a0)+
 dbf d6,.axis
 adda.w #12,a7
 movem.l (a7)+,d0-d7/a0-a1
 rts
