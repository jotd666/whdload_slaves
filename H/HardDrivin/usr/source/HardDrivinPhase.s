; Experimental incremental native-endpoint integration for driving, including
; flight and manual gears. Full step-4 acceptance remains separate.
_phase_install:
 movem.l d0/a0-a2,-(a7)
 lea _phase_power_status(pc),a0
 clr.w (a0)
 lea _phase_tail_ptr(pc),a0
 move.l _code_start(pc),d0
 addi.l #$ba8a,d0
 move.l d0,(a0)+
 move.l _code_start(pc),d0
 addi.l #$b9ba,d0
 move.l d0,(a0)
 lea _phase_steering_body(pc),a0
 move.l _code_start(pc),d0
 addi.l #$b398,d0
 move.l d0,(a0)
 lea _phase_patches(pc),a0
 movea.l _code_start(pc),a1
 movea.l _resload(pc),a2
 jsr resload_Patch(a2)
 movem.l (a7)+,d0/a0-a2
 rts
_phase_patches:
 PL_START
 ; PERF_RANGE VERIFY_DRIVETRAIN_PHASE $0b390 $0008: steering follows scalar phase eligibility
 PL_P $b390,_phase_steering_defer
 PL_NOP $b396,2
 ; PERF_RANGE VERIFY_DRIVETRAIN_PHASE $122be $0006: exact shortened unsigned long division
 PL_P $122be,_phase_divide
 ; PERF_RANGE VERIFY_DRIVETRAIN_PHASE $0b904 $0008: incremental RPM before automatic gear decision
 PL_PSS $b904,_phase_gear,2
 ; PERF_RANGE VERIFY_DRIVETRAIN_PHASE $09564 $0068: exact native Newton root with guarded hardware division
 ; Keep the native recurrence, initial guess and two-cycle termination.
 ; DIVU is exact when its unsigned quotient fits a word; overflow or a
 ; wider divisor retains the original full-long divider. D1 is preserved
 ; by both division paths, and D2/D3 plus final NZVC/X match native code.
 ; The 96-byte body plus eight NOP bytes replaces the full 104-byte routine.
 PL_DATA $9564,_phase_root_patch_end-_phase_root_patch
_phase_root_patch:
 link a5,#0
 movem.l d2-d3,-(a7)
 move.l 8(a5),d2
 bne.s .positive
 moveq #0,d0
 bra.s .return
.positive:
 move.l d2,d0
 move.l #5000,d1
 bsr.s .divide
 addq.l #8,d0
 move.l d0,d1
 move.l d0,d3
.loop:
 move.l d2,d0
 bsr.s .divide
 add.l d1,d0
 lsr.l #1,d0
 cmp.l d1,d0
 beq.s .return
 cmp.l d3,d0
 beq.s .return
 move.l d1,d3
 move.l d0,d1
 bra.s .loop
.return:
 movem.l (a7)+,d2-d3
 tst.l d0
 unlk a5
 rts
.divide:
 cmpi.l #65535,d1
 bhi.s .native
 move.l d0,-(a7)
 divu.w d1,d0
 bvs.s .overflow
 andi.l #$ffff,d0
 addq.w #4,a7
 rts
.overflow:
 move.l (a7)+,d0
.native:
 jmp -$7de8(a4)
 dcb.w 4,$4e71
_phase_root_patch_end:
 PL_END
; Preserve the compiler divider ABI, including remainder and materialized CCR.
; For a wide divisor the native restoring loop always executes sixteen bits.
; Align to the dividend instead; the loop then visits only quotient bits.
; No engine inputs, phase endpoints or update cadence are changed.
_phase_divide:
 ; A word quotient needs one DIVU. Otherwise retain native two-word division.
 movem.l d2-d3,-(a7)
 swap d1
 tst.w d1
 bne.s .wide
 swap d1
 move.l d0,d2
 swap d2
 cmp.w d1,d2
 bcc.s .twoword
 divu.w d1,d0
 move.l d0,d1
 andi.l #$ffff,d0
 clr.w d1
 swap d1
 movem.l (a7)+,d2-d3
 rts
.twoword:
 move.w d1,d3
 move.w d0,d2
 clr.w d0
 swap d0
 divu.w d3,d0
 move.l d0,d1
 swap d0
 move.w d2,d1
 divu.w d3,d1
 move.w d1,d0
 clr.w d1
 swap d1
 movem.l (a7)+,d2-d3
 rts
.wide:
 swap d1
 movem.l d4,-(a7)
 move.l d1,d4
 move.l d1,d3
 moveq #0,d2
 cmp.l d3,d0
 bcs.s .zero
.align:
 tst.l d3
 bmi.s .ready
 add.l d3,d3
 cmp.l d3,d0
 bcs.s .overshot
 addq.w #1,d2
 bra.s .align
.overshot:
 lsr.l #1,d3
.ready:
 move.l d0,d1
 moveq #0,d0
.loop:
 add.w d0,d0
 cmp.l d3,d1
 bcs.s .keep
 sub.l d3,d1
 addq.w #1,d0
.keep:
 lsr.l #1,d3
 dbra d2,.loop
 bra.s .flags
.zero:
 move.l d0,d1
 moveq #0,d0
; Native final wide iteration leaves X=0. An odd quotient finishes on
; ADDQ.W; an even quotient finishes on CMP.L remainder,divisor. Recreate
; these flags after alignment/loop bookkeeping, including quotient $8000.
.flags:
 btst #0,d0
 bne.s .odd
 moveq #0,d2
 add.l d2,d2
 cmp.l d1,d4
 bra.s .done
.odd:
 move.w d0,d2
 subq.w #1,d2
 addq.w #1,d2
.done:
 movem.l (a7)+,d4
 movem.l (a7)+,d2-d3
 rts

; The native outer orientation call still integrates roll, pitch and spin once.
; Defer its steering/trig tail to the existing engine chunks, whose anchor
; velocity makes the zero-speed eligibility test independent of render cadence.
_phase_steering_defer:
 IFD VERIFY_DISPATCH_NATIVE
 bra.s _phase_steering_continue
 ELSE
 lea _phase_steering_pending(pc),a0
 st (a0)
 unlk a5
 rts
 ENDC
_phase_steering_call:
 link a5,#-6
_phase_steering_continue:
 clr.b -$870(a4)
 move.b -$66f0(a4),d0
 move.l _phase_steering_body(pc),-(a7)
 rts
_phase_steering_body: dc.l 0
; Pending byte: 0 absent, -1 steering required, +1 neutral tail already done.
; The outer orientation entry resets it every frame.
_phase_steering_pending: dc.w 0
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
PH_SKID equ 76
 dc.b 'HDPHASE1'
_phase_state: dcb.b 78,0
; Pure RPM/gear conversion: key words, derived speed word, valid word.
_phase_speed_cache: dcb.w 4,0
_phase_reset:
 move.l a0,-(a7)
 lea _phase_state(pc),a0
 clr.w PH_VALID(a0)
 clr.w PH_ACTIVE(a0)
 movea.l (a7)+,a0
 rts
_phase_frame:
 ; CDB6 replaces two native calls: D0/D1/A0/A1 are caller scratch.
 ; B500 and the following contact routines define these before use.
 ; Keep D2-D7/A2/A6, including registers the phase helpers introduce.
 movem.l d2-d7/a2/a6,-(a7)
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
 ; Native turning-force input is evaluated by every engine segment.
 ; Contact and gravity are handled by the native position/contact pass.
 ; Keep the scalar phase across flight and terrain landing corrections.
 ; Road/grass drag is native; throttle decay consumes PH_DT fields.
 ; Ground slope is consumed by native force and projection arithmetic.
 tst.w -$66ca(a4)
 blt .fallback
 cmpi.w #4,-$66ca(a4)
 bgt .fallback
 move.w d0,PH_INTERVAL(a6)
 move.w d0,PH_LEFT(a6)
 moveq #0,d0
 move.b -$66ef(a4),d0
 move.w d0,PH_BRAKE(a6)
 moveq #0,d0
 move.b -$50cf(a4),d0
 move.w d0,PH_SKID(a6)
 tst.w PH_VALID(a6)
 beq.s .initialize
 ; Native velocity/RPM and LAST velocity/RPM are adjacent word pairs.
 move.l -$66d8(a4),d0
 cmp.l PH_LAST_V(a6),d0
 bne.s .initialize
 move.w -$66ca(a4),d0
 cmp.w PH_LAST_G(a6),d0
 bne.s .initialize
 ; Terrain translations do not reset the scalar phase. Absolute resets
 ; invalidate it through the existing motion-reset hooks.
 bra.s .ready
.initialize:
 bsr _phase_initialize
 tst.l d0
 beq .fallback
.ready:
 ; A fully stopped engine has no evolution to carry across idle frames.
 ; Start its first nonzero response at a native phase boundary rather than
 ; letting the number/length of idle render frames choose that phase.
 ; Check full Q16 state: zero published words alone can hide live fractions.
 tst.l -$66d8(a4)
 bne.s .running
 move.l PH_CURRENT_V(a6),d0
 or.l PH_CURRENT_R(a6),d0
 bne.s .running
 clr.w PH_PHASE(a6)
 clr.l PH_ANCHOR_V(a6)
 clr.l PH_ANCHOR_R(a6)
.running:
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
 move.b _phase_steering_pending(pc),d0
 beq.s .orientation_ready
 ; Recreate the native MPH companion for this phase anchor before its
 ; speed-sensitive steering decisions. Preserve native word narrowing.
 move.w PH_GEAR(a6),d0
 lsl.w #2,d0
 lea -$733c(a4),a0
 adda.w d0,a0
 move.w -$66d6(a4),d0
 muls.w (a0),d0
 divs.w 2(a0),d0
 move.w d0,-$66d4(a4)
 ; Keep publishing anchor MPH, but a completed neutral tail is idempotent.
 move.b _phase_steering_pending(pc),d0
 bpl.s .orientation_ready
 lea _time_scalar_fields(pc),a0
 move.w PH_DT(a6),(a0)
 bsr _phase_steering_call
 move.w _dispatch_state+28(pc),d0
 subi.w #301,d0
 cmpi.w #38,d0
 bhi.s .keep_steering
 ; Native normalization advances only one turn per call. Keep repeats
 ; when an exceptional input still leaves any angle outside its range.
 move.w -$66b6(a4),d0
 addi.w #720,d0
 cmpi.w #1440,d0
 bhi.s .keep_steering
 move.w -$66b4(a4),d0
 addi.w #720,d0
 cmpi.w #1440,d0
 bhi.s .keep_steering
 move.w -$66b2(a4),d0
 addi.w #720,d0
 cmpi.w #1440,d0
 bhi.s .keep_steering
 lea _phase_steering_pending(pc),a0
 move.b #1,(a0)
.keep_steering:
 moveq #0,d0
 move.b -$50cf(a4),d0
 move.w d0,PH_SKID(a6)
 lea _time_scalar_fields(pc),a0
 move.w #8,(a0)
.orientation_ready:
 move.w #1,PH_ACTIVE(a6)
 bsr _phase_engine_call
 clr.w PH_ACTIVE(a6)
 bsr _phase_movement_vector
 bsr _phase_add_position
 move.w -$66ca(a4),d0
 cmp.w PH_GEAR(a6),d0
 beq.s .same_gear
 move.w d0,PH_GEAR(a6)
 moveq #0,d0
 move.w -$66d6(a4),d0
 swap d0
 move.l d0,PH_CURRENT_R(a6)
 ; A manual shift can end a partial phase. Preserve integrated velocity
 ; and restart both anchors with the native converted RPM.
 move.w #8,PH_PHASE(a6)
.same_gear:
 cmpi.w #8,PH_PHASE(a6)
 bne.s .continued
 move.l PH_CURRENT_V(a6),PH_ANCHOR_V(a6)
 move.l PH_CURRENT_R(a6),PH_ANCHOR_R(a6)
 ; The native tail just converted this new anchor RPM/gear. Retain its
 ; result for the first segment of a later frame that resumes this phase.
 lea _phase_speed_cache(pc),a0
 move.w PH_CURRENT_R(a6),(a0)+
 move.w PH_GEAR(a6),(a0)+
 move.w -$66da(a4),(a0)+
 move.w #1,(a0)
 clr.w PH_PHASE(a6)
.continued:
 move.w PH_DT(a6),d0
 sub.w d0,PH_LEFT(a6)
 bne .loop
 lea _phase_steering_pending(pc),a0
 clr.b (a0)
 lea _time_scalar_fields(pc),a0
 move.w PH_INTERVAL(a6),(a0)
 lea _drivetrain_state(pc),a0
 move.w #2,6(a0)
 movem.l (a7)+,d2-d7/a2/a6
 pea _phase_published(pc)
 move.l _drivetrain_position(pc),-(a7)
 rts
.fallback:
 move.b _phase_steering_pending(pc),d0
 beq.s .orientation_done
 lea _phase_steering_pending(pc),a0
 clr.b (a0)
 bsr _phase_steering_call
.orientation_done:
 clr.w PH_VALID(a6)
 clr.w PH_ACTIVE(a6)
 movem.l (a7)+,d2-d7/a2/a6
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
 ; A later segment in this frame starts immediately after a completed
 ; phase and the native tail. V/R/gear and derived speed already match the
 ; new anchor. Scalar V/R companions are not read inside an active phase;
 ; _phase_published writes their exact outgoing values once per outer frame.
 tst.w PH_PHASE(a6)
 bne.s .first
 move.w PH_LEFT(a6),d1
 cmp.w PH_INTERVAL(a6),d1
 beq.s .first
 bra .converted
.first:
 lea _time_scalar_fields(pc),a0
 move.w #8,(a0)
 move.l PH_ANCHOR_V(a6),d0
 swap d0
 move.w d0,-$66d8(a4)
 move.l PH_ANCHOR_R(a6),d0
 swap d0
 move.w d0,-$66d6(a4)
 move.w PH_GEAR(a6),d0
 move.w d0,-$66ca(a4)
 lea _phase_speed_cache(pc),a1
 tst.w 6(a1)
 beq.s .convert
 cmp.w 2(a1),d0
 bne.s .convert
 move.w -$66d6(a4),d1
 cmp.w (a1),d1
 bne.s .convert
 move.w 4(a1),-$66da(a4)
 bra.s .converted
.convert:
 lsl.w #2,d0
 lea -$733c(a4),a0
 adda.w d0,a0
 ; Exactly the two native $2950 MULS.W/DIVS.W conversions. Each call
 ; consumes signed words; preserve that narrowing even if DIVS overflows.
 ; Normal anchors are RPM0..6500, ratio7..10 /450..800, then500/140.
 move.w -$66d6(a4),d0
 muls.w (a0),d0
 divs.w 2(a0),d0
 muls.w #500,d0
 divs.w #140,d0
 move.w d0,-$66da(a4)
 move.w -$66d6(a4),(a1)
 move.w -$66ca(a4),2(a1)
 move.w d0,4(a1)
 move.w #1,6(a1)
.converted:
 move.w PH_BRAKE(a6),d0
 move.b d0,-$66ef(a4)
 rts
_phase_gear:
 ; Inactive calls reproduce only B904's TST/branch, preserving all registers.
 btst #0,_phase_state+PH_ACTIVE+1(pc)
 beq .native
 ; Active calls are inside the native automatic engine and _phase_frame.
 ; B90C..BA8A reads globals, overwrites D0/D4/A0/A2 before using them,
 ; and the native epilogue restores D4/A2. D1 is native caller scratch;
 ; _phase_frame preserves D2-D3 across the whole engine call. Preserve X.
 moveq #0,d0
 roxl.b #1,d0
 move.w d0,-(a7)
 lea _phase_state(pc),a2
 ; Integrate velocity and RPM together. Both consume the same DT, but
 ; only velocity needs the remaining-phase forecast. Pairing the bounded
 ; additions removes the second call and repeated count setup without
 ; changing any intermediate signed-long rounding.
 cmpi.w #8,PH_DT(a2)
 beq .whole_phase
 moveq #0,d3
 move.w -$66d8(a4),d3
 swap d3
 sub.l PH_ANCHOR_V(a2),d3
 asr.l #3,d3
 ; With no wheel contact the native engine leaves velocity untouched.
 ; Preserve its fractional state too instead of drifting toward the word
 ; anchor while the free-rev RPM path runs.
 tst.b -$66f0(a4)
 beq.s .free_velocity
 tst.w PH_GEAR(a2)
 bne.s .velocity_slope
.free_velocity:
 moveq #0,d3
.velocity_slope:
 moveq #0,d4
 move.w -$66d6(a4),d4
 swap d4
 sub.l PH_ANCHOR_R(a2),d4
 asr.l #3,d4
 move.l PH_CURRENT_V(a2),d0
 move.l PH_CURRENT_R(a2),d1
 move.w PH_DT(a2),d2
 neg.w d2
 lsl.w #2,d2
 jmp .consumed(pc,d2.w)
 add.l d3,d0
 add.l d4,d1
 add.l d3,d0
 add.l d4,d1
 add.l d3,d0
 add.l d4,d1
 add.l d3,d0
 add.l d4,d1
 add.l d3,d0
 add.l d4,d1
 add.l d3,d0
 add.l d4,d1
 add.l d3,d0
 add.l d4,d1
.consumed:
 move.l d0,PH_CURRENT_V(a2)
 move.l d1,PH_CURRENT_R(a2)
 move.w PH_DT(a2),d2
 sub.w PH_REMAIN(a2),d2
 beq.s .forecast
 add.w d2,d2
 jmp .forecast(pc,d2.w)
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
.forecast:
 move.l d0,PH_FORECAST(a2)
 move.l PH_CURRENT_V(a2),d0
 swap d0
 move.w d0,-$66d8(a4)
 swap d1
 move.w d1,-$66d6(a4)
 bra.s .advanced
.whole_phase:
 ; DT8 implies phase0 and current=anchor in a valid phase. Consuming the
 ; complete phase publishes the native endpoints exactly, already in game
 ; globals. No second publication or fractional kernel is needed.
 tst.b -$66f0(a4)
 beq.s .air_velocity
 tst.w PH_GEAR(a2)
 beq.s .air_velocity
 move.w -$66d8(a4),PH_CURRENT_V(a2)
 clr.w PH_CURRENT_V+2(a2)
.air_velocity:
 move.l PH_CURRENT_V(a2),PH_FORECAST(a2)
 move.w -$66d6(a4),PH_CURRENT_R(a2)
 clr.w PH_CURRENT_R+2(a2)
.advanced:
 move.w PH_DT(a2),d0
 add.w d0,PH_PHASE(a2)
 cmpi.w #8,PH_PHASE(a2)
 beq.s .restore
 move.l _phase_tail_ptr(pc),2(a7)
.restore:
 move.w (a7)+,d0
 lsr.b #1,d0
.native:
 tst.b -$66c2(a4)
 bne.s .done
 move.l _phase_manual_ptr(pc),(a7)
.done:
 rts
 ; Skids retain the native held movement vector even while scalar speed changes.
_phase_movement_vector:
 tst.w PH_SKID(a6)
 bne.s .held
 move.l PH_FORECAST(a6),d0
 lea PH_VECTOR(a6),a0
 bra _phase_project_core
.held:
 lea -$66e2(a4),a0
 lea _projection_state(pc),a1
 lea PH_VECTOR(a6),a2
 moveq #2,d1
.axis:
 moveq #0,d0
 move.w (a0)+,d0
 swap d0
 add.l (a1)+,d0
 move.l d0,(a2)+
 dbf d1,.axis
 rts

_phase_add_position:
 ; Three fixed axes need no cursor updates or loop counter. Inline the
 ; signed Q16 split at each store, retaining modular additions and the
 ; truncation-toward-zero carry rule, including negative held vectors.
 lea _projection_state+24(pc),a1
 move.w PH_DT(a6),d5
 cmpi.w #8,d5
 beq .whole
 subq.w #1,d5
 neg.w d5
 add.w d5,d5
 move.l PH_VECTOR+0(a6),d3
 beq.s .next_s0
 asr.l #3,d3
 move.l d3,d0
 jmp .scaled_s0(pc,d5.w)
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
.scaled_s0:
 add.l 0(a1),d0
 moveq #0,d2
 move.w d0,d2
 swap d0
 ext.l d0
 bpl.s .store_s0
 tst.l d2
 beq.s .store_s0
 addq.l #1,d0
 subi.l #$10000,d2
.store_s0:
 add.l d0,-$6704(a4)
 move.l d2,0(a1)
.next_s0:
 move.l PH_VECTOR+4(a6),d3
 beq.s .next_s1
 asr.l #3,d3
 move.l d3,d0
 jmp .scaled_s1(pc,d5.w)
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
.scaled_s1:
 add.l 4(a1),d0
 moveq #0,d2
 move.w d0,d2
 swap d0
 ext.l d0
 bpl.s .store_s1
 tst.l d2
 beq.s .store_s1
 addq.l #1,d0
 subi.l #$10000,d2
.store_s1:
 add.l d0,-$6700(a4)
 move.l d2,4(a1)
.next_s1:
 move.l PH_VECTOR+8(a6),d3
 beq.s .next_s2
 asr.l #3,d3
 move.l d3,d0
 jmp .scaled_s2(pc,d5.w)
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
.scaled_s2:
 add.l 8(a1),d0
 moveq #0,d2
 move.w d0,d2
 swap d0
 ext.l d0
 bpl.s .store_s2
 tst.l d2
 beq.s .store_s2
 addq.l #1,d0
 subi.l #$10000,d2
.store_s2:
 add.l d0,-$66fc(a4)
 move.l d2,8(a1)
.next_s2:
 rts
.whole:
 move.l PH_VECTOR+0(a6),d0
 beq.s .next_w0
 andi.l #$fffffff8,d0
 add.l 0(a1),d0
 moveq #0,d2
 move.w d0,d2
 swap d0
 ext.l d0
 bpl.s .store_w0
 tst.l d2
 beq.s .store_w0
 addq.l #1,d0
 subi.l #$10000,d2
.store_w0:
 add.l d0,-$6704(a4)
 move.l d2,0(a1)
.next_w0:
 move.l PH_VECTOR+4(a6),d0
 beq.s .next_w1
 andi.l #$fffffff8,d0
 add.l 4(a1),d0
 moveq #0,d2
 move.w d0,d2
 swap d0
 ext.l d0
 bpl.s .store_w1
 tst.l d2
 beq.s .store_w1
 addq.l #1,d0
 subi.l #$10000,d2
.store_w1:
 add.l d0,-$6700(a4)
 move.l d2,4(a1)
.next_w1:
 move.l PH_VECTOR+8(a6),d0
 beq.s .next_w2
 andi.l #$fffffff8,d0
 add.l 8(a1),d0
 moveq #0,d2
 move.w d0,d2
 swap d0
 ext.l d0
 bpl.s .store_w2
 tst.l d2
 beq.s .store_w2
 addq.l #1,d0
 subi.l #$10000,d2
.store_w2:
 add.l d0,-$66fc(a4)
 move.l d2,8(a1)
.next_w2:
 rts
_phase_published:
 ; Return to CDBE after native B500: D0/D1/A0/A1 are dead caller scratch.
 movem.l d2-d4/d7/a2/a6,-(a7)
 moveq #0,d0
 roxl.b #1,d0
 move.w d0,-(a7)
 lea _phase_state(pc),a6
 lea _time_scalar_state(pc),a0
 ; Native V/R and their LAST words are adjacent pairs.
 move.l -$66d8(a4),d0
 move.l d0,PH_LAST_V(a6)
 move.w d0,SS_RPM_LAST(a0)
 swap d0
 move.w d0,SS_VELOCITY_LAST(a0)
 move.w PH_CURRENT_V+2(a6),d0
 rol.w #3,d0
 andi.w #7,d0
 move.w d0,SS_VELOCITY_CARRY(a0)
 move.w PH_CURRENT_R+2(a6),d0
 rol.w #3,d0
 andi.w #7,d0
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
 ; Preserve the entry skid vector through native spin/exit housekeeping.
 tst.w PH_SKID(a6)
 bne.s .vector_done
 ; Native B500 has already projected the current integer velocity.
 ; Reuse that base vector and calculate only its neighboring integer when
 ; a Q6 fractional part exists. Finer flight/shift fractions are quantized
 ; only for projection; the scalar state retains its Q16 precision.
 move.l PH_CURRENT_V(a6),d0
 move.w d0,d7
 rol.w #6,d7
 andi.w #63,d7
 lea PH_VECTOR(a6),a0
 lea -$66e2(a4),a1
 lea _projection_state(pc),a2
 tst.w d7
 beq.s .whole_vector
 swap d0
 addq.w #1,d0
 bsr _projection_integer_components
 ; Each difference is narrowed to a word exactly as in _phase_project.
 sub.w (a1),d0
 muls.w d7,d0
 lsl.l #8,d0
 lsl.l #2,d0
 move.l d0,(a2)+
 moveq #0,d3
 move.w (a1)+,d3
 swap d3
 add.l d3,d0
 move.l d0,(a0)+
 sub.w (a1),d1
 muls.w d7,d1
 lsl.l #8,d1
 lsl.l #2,d1
 move.l d1,(a2)+
 moveq #0,d3
 move.w (a1)+,d3
 swap d3
 add.l d3,d1
 move.l d1,(a0)+
 sub.w (a1),d2
 muls.w d7,d2
 lsl.l #8,d2
 lsl.l #2,d2
 move.l d2,(a2)
 moveq #0,d3
 move.w (a1),d3
 swap d3
 add.l d3,d2
 move.l d2,(a0)
 bra.s .vector_done
.whole_vector:
 moveq #2,d4
.whole_axis:
 clr.l (a2)+
 move.w (a1)+,(a0)+
 clr.w (a0)+
 dbf d4,.whole_axis
.vector_done:
 lea _drivetrain_state(pc),a0
 clr.w 6(a0)
 move.w (a7)+,d0
 lsr.b #1,d0
 movem.l (a7)+,d2-d4/d7/a2/a6
 rts

; A0: native-phase anchor Q16, current Q16. D0: unsigned endpoint word.
; D1: newly consumed fields, D2: fields remaining before this update.
; 1 <= D1 <= D2 <= 8. Anchor is a nonnegative Q3 value in Q16 storage.
; Return D0: forecast Q16 at the phase end using only future input.
; Update current at A0+4. D3-D4 scratch; all other registers preserved.
_phase_scalar_step:
 ; At a complete new phase current=anchor, so consuming all eight fields
 ; returns the native endpoint exactly. Retain the general kernel when the
 ; caller supplies a different current value (including verification inputs).
 cmpi.w #8,d1
 bne.s .incremental
 move.l (a0),d3
 cmp.l 4(a0),d3
 bne.s .incremental
 swap d0
 clr.w d0
 move.l d0,4(a0)
 rts
.incremental:
 moveq #0,d3
 move.w d0,d3
 swap d3
 sub.l (a0),d3
 asr.l #3,d3
 move.l 4(a0),d0
 ; Counts are1..8. Enter a fixed chain at -2*count to avoid a DBF per
 ; field while retaining the exact sequence of modular long additions.
 move.w d1,d4
 neg.w d4
 add.w d4,d4
 jmp .consumed(pc,d4.w)
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
.consumed:
 move.l d0,4(a0)
 move.w d1,d4
 sub.w d2,d4
 beq.s .done
 add.w d4,d4
 jmp .done(pc,d4.w)
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
 add.l d3,d0
.done:
 rts

; D0.L signed Q16 forecast. Interpolation quantizes its fraction to Q6.
; A0 -> three Q16 projected components. All registers preserved.
_phase_project:
 movem.l d0-d7/a0-a1,-(a7)
 bsr _phase_project_core
 movem.l (a7)+,d0-d7/a0-a1
 rts
; The runtime movement caller already preserves the outer frame's registers. The core
; clobbers D0-D7/A0; A1-A6 are untouched.
_phase_project_core:
 ; Flat cardinal orientations need no multiply. For signed velocity,
 ; native p(v)=v+floor(v/2), and p(v+1)-p(v)=1+(v&1). Interpolate that
 ; exact staircase at the existing Q6 precision, including negative axes.
 tst.w -$6bb4(a4)
 bne .general
 cmpi.w #16384,-$6bb2(a4)
 bne .general
 tst.w -$6bb6(a4)
 beq.s .east_west
 tst.w -$6bb8(a4)
 bne .general
 move.w -$6bb6(a4),d2
 cmpi.w #16384,d2
 beq.s .north_south
 cmpi.w #-16384,d2
 bne .general
.north_south:
 bsr.s .cardinal_value
 clr.l (a0)
 clr.l 4(a0)
 move.l d0,8(a0)
 rts
.east_west:
 move.w -$6bb8(a4),d2
 cmpi.w #16384,d2
 beq.s .east_west_ready
 cmpi.w #-16384,d2
 bne .general
.east_west_ready:
 bsr.s .cardinal_value
 move.l d0,(a0)
 clr.l 4(a0)
 clr.l 8(a0)
 rts
.cardinal_value:
 move.l d0,d1
 swap d1
 move.w d1,d4
 asr.w #1,d4
 add.w d1,d4
 swap d4
 clr.w d4
 andi.l #$fc00,d0
 btst #0,d1
 beq.s .unit
 add.l d0,d0
.unit:
 add.l d4,d0
 tst.w d2
 bpl.s .positive
 neg.l d0
.positive:
 rts
.general:
 ; Keep the first rounded XYZ in preserved projection scratch registers,
 ; eliminating the temporary stack array and its second pass.
 move.l d0,d7
 rol.w #6,d7
 andi.l #63,d7
 swap d0
 move.w d0,d5
 bsr _projection_integer_components
 tst.w d7
 beq.s .integer
 move.w d0,d3
 move.w d1,d4
 move.w d2,d6
 move.w d5,d0
 addq.w #1,d0
 bsr _projection_integer_components
 sub.w d3,d0
 muls.w d7,d0
 lsl.l #8,d0
 lsl.l #2,d0
 swap d3
 clr.w d3
 add.l d3,d0
 move.l d0,(a0)+
 sub.w d4,d1
 muls.w d7,d1
 lsl.l #8,d1
 lsl.l #2,d1
 swap d4
 clr.w d4
 add.l d4,d1
 move.l d1,(a0)+
 sub.w d6,d2
 muls.w d7,d2
 lsl.l #8,d2
 lsl.l #2,d2
 swap d6
 clr.w d6
 add.l d6,d2
 move.l d2,(a0)+
 rts
.integer:
 move.w d0,(a0)
 clr.w 2(a0)
 move.w d1,4(a0)
 clr.w 6(a0)
 move.w d2,8(a0)
 clr.w 10(a0)
 rts

; Exact native power conversions for the immutable four-gear ratio table.
; Validate all ratio words once per installation before using the lookup.
; Native B696 is reached only for gear1..4; neutral skips this conversion.
; Other paths and unexpected ratio tables retain the general implementation.
_phase_power:
 btst #0,_phase_state+PH_ACTIVE+1(pc)
 beq _drivetrain_power
 move.w _phase_power_status(pc),d1
 bgt.s .lookup
 bmi _drivetrain_power
 move.w -$66ca(a4),d1
 lsl.w #2,d1
 movea.l a2,a0
 suba.w d1,a0
 cmpi.l #$00070320,4(a0)
 bne.s .unsupported
 cmpi.l #$000902ee,8(a0)
 bne.s .unsupported
 cmpi.l #$000a0258,12(a0)
 bne.s .unsupported
 cmpi.l #$000a01c2,16(a0)
 bne.s .unsupported
 lea _phase_power_status(pc),a0
 move.w #1,(a0)
.lookup:
 move.w -$66ca(a4),d1
 subq.w #1,d1
 lsl.w #8,d1
 move.b -$66e4(a4),d1
 lsl.w #3,d1
 lea _phase_power_table(pc),a0
 move.l (a0,d1.w),d0
 move.w 4(a0,d1.w),d4
 move.w d0,-14(a5)
 rts
.unsupported:
 lea _phase_power_status(pc),a0
 move.w #-1,(a0)
 bra _drivetrain_power
_phase_power_status: dc.w 0

; D0 retains DIVS's remainder/quotient pair, or its unchanged full product
; on signed-word quotient overflow. D4 receives the first conversion word.
; Entries include every signed throttle byte, not only the normal0..100.
; Eight-byte stride keeps lookup arithmetic short on a68000.
_phase_power_table:
HD_POWER_ROW MACRO
HD_POWER_T SET 0
 REPT 256
HD_POWER_S SET HD_POWER_T
 IFGE HD_POWER_T-128
HD_POWER_S SET HD_POWER_T-256
 ENDC
HD_POWER_FIRST SET (HD_POWER_S*450)/100
HD_POWER_PRODUCT SET HD_POWER_FIRST*\2
HD_POWER_QUOT SET HD_POWER_PRODUCT/\1
HD_POWER_OVER SET 0
 IFGT HD_POWER_QUOT-32767
HD_POWER_OVER SET 1
 ENDC
 IFLT HD_POWER_QUOT+32768
HD_POWER_OVER SET 1
 ENDC
 IFNE HD_POWER_OVER
 dc.l HD_POWER_PRODUCT
 ELSE
 dc.w HD_POWER_PRODUCT-HD_POWER_QUOT*\1,HD_POWER_QUOT
 ENDC
 dc.w HD_POWER_FIRST,0
HD_POWER_T SET HD_POWER_T+1
 ENDR
 ENDM
 HD_POWER_ROW 7,800
 HD_POWER_ROW 9,750
 HD_POWER_ROW 10,600
 HD_POWER_ROW 10,450
