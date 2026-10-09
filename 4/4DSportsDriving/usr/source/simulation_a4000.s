; Development-only first-race integration. Requires SIM_FIXTURE/SIM_SCHEDULE.
; NOT a selectable/replay-capable A4000 release: remaining rate sites and
; lifecycle hooks are deliberately still pending. Native 10/20 paths survive.
SIM_PRIVATE_BYTES = 128
sim_a4000_arm:
 lea sim_a4000_private(pc),a0
 moveq #SIM_PRIVATE_BYTES/4-1,d0
.clear:
 clr.l (a0)+
 dbra d0,.clear
 ; Enter only at the fixture's untouched tick zero after native A2500 setup.
 move.w #50,-$15fa(a4)
 move.w #50,-$bc(a4)
 move.b #50,-$173a(a4)
 move.w #1500,-$ba(a4)
 move.w #30000,$b30(a4)
 move.w #2,-$be(a4)
 lea sim_schedule_rate(pc),a0
 move.w #50,(a0)
 lea sim_schedule_phase(pc),a0
 clr.w (a0)
 rts

; a1 vehicle -> a0 private block; no stored pointer is part of replay state.
; steering +0, acceleration +2, distance +4, gear +6, wheel pairs +8..23.
; Suspension fractions: extension +24..31, return +32..39, bias +40..47.
; Terrain loss uses an unsigned Q16 carry at +48; skid loss uses fifths at +50.
sim_a4000_car:
 lea -$85e(a4),a0
 cmpa.l a0,a1
 lea sim_a4000_private(pc),a0
 bne .done
 lea 64(a0),a0
.done:
 rts

; Replace the whole A2500 displacement block $C326..$C346 (32 bytes).
; Local -6(a5) is its original output. Native helper is long unsigned divide.
sim_a4000_distance:
 cmp.w #50,-$15fa(a4)
 beq .new
 move.l 8(a5),a0
 move.w $2c(a0),d0
 swap d0
 clr.w d0
 swap d0
 mulu #1408,d0
 move.l #15360,d1
 jsr -$78ea(a4)
 move.w d0,-6(a5)
 rts
.new:
 move.l a1,-(sp)
 move.l 8(a5),a1
 bsr sim_a4000_car
 addq.l #4,a0
 move.w $2c(a1),d0
 bsr sim_distance_50
 move.l (sp)+,a1
 move.w d0,-6(a5)
 rts

; $F60C..$F61C: rate conversion before the native velocity clamp/application.
sim_a4000_acceleration:
 cmp.w #50,-$15fa(a4)
 beq .new
 cmp.w #10,-$15fa(a4)
 bne .done
 move.w -4(a5),d0
 add.w d0,-4(a5)
.done:
 rts
.new:
 movem.l d1/a0-a1,-(sp)
 move.l 12(a5),a1
 bsr sim_a4000_car
 addq.l #2,a0
 move.w -4(a5),d0
 bsr sim_rate_20_to_50
 move.w d0,-4(a5)
 movem.l (sp)+,d1/a0-a1
 rts

; JMP hook at $1033A. Native path replays ten displaced bytes, then continues.
sim_a4000_steering:
 link a5,#-6
 move.w -$90e(a4),-4(a5)
 cmp.w #50,-$15fa(a4)
 beq .new
 move.l a0,-(sp)
 move.l tape_game(pc),a0
 adda.l #$10344,a0
 move.l a0,d0
 move.l (sp)+,a0
 move.l d0,-(sp)
 rts
.new:
 movem.l d2-d3,-(sp)
 move.w -$902(a4),d0
 moveq #10,d1
 lsr.w d1,d0
 and.w #$fffc,d0
 ; Native index is truncated to a signed byte before indexing the 64-byte table.
 ext.w d0
 move.l -$b8(a4),a0
 move.b 1(a0,d0.w),d2
 ext.w d2
 add.w d2,d2
 move.b 8(a5),d1
 ext.w d1
 add.w d1,d0
 move.b (a0,d0.w),d1
 ext.w d1
 move.w -$902(a4),d3
 move.w -$90e(a4),d0
 lea sim_a4000_private(pc),a0
 bsr sim_steering_50
 move.w d0,-$90e(a4)
 movem.l (sp)+,d2-d3
 unlk a5
 rts

; These displaced blocks have only internal relative branches and A4-relative
; calls. Copy before patching; the original fallthrough becomes the buffer RTS.
sim_a4000_prepare:
 move.l tape_game(pc),a0
 adda.l #$f29e,a0
 lea sim_native_gear38(pc),a1
 moveq #72/2-1,d0
 bsr .copy
 move.l tape_game(pc),a0
 adda.l #$f310,a0
 lea sim_native_gear34(pc),a1
 moveq #72/2-1,d0
 bsr .copy
 move.l tape_game(pc),a0
 adda.l #$f36e,a0
 lea sim_native_gear_middle(pc),a1
 moveq #72/2-1,d0
 bsr .copy
 move.l tape_game(pc),a0
 adda.l #$cb48,a0
 lea sim_native_wheel(pc),a1
 moveq #148/2-1,d0
 bsr .copy
 move.l tape_game(pc),a0
 adda.l #$10030,a0
 lea sim_native_suspension_bias(pc),a1
 move.w #164/2-1,d0
 bsr .copy
 move.l tape_game(pc),a0
 adda.l #$1011c,a0
 lea sim_native_suspension_return(pc),a1
 move.w #262/2-1,d0
 bsr .copy
 move.l tape_game(pc),a0
 adda.l #$f842,a0
 lea sim_native_terrain(pc),a1
 moveq #48/2-1,d0
 bsr .copy
 move.l _resload(pc),a2
 jsr resload_FlushCache(a2)
 rts
.copy:
 move.w (a0)+,(a1)+
 dbra d0,.copy
 rts

sim_a4000_gear38:
 cmp.w #50,-$15fa(a4)
 bne sim_native_gear38
 movem.l d1-d2/a0-a2,-(sp)
 move.l 12(a5),a1
 bsr sim_a4000_car
 addq.l #6,a0
 lea $38(a1),a2
 move.w $3c(a1),d1
 bra sim_a4000_gear_apply
sim_a4000_gear34:
 cmp.w #50,-$15fa(a4)
 bne sim_native_gear34
 movem.l d1-d2/a0-a2,-(sp)
 move.l 12(a5),a1
 bsr sim_a4000_car
 addq.l #6,a0
 lea $34(a1),a2
 move.w $3a(a1),d1
 bra sim_a4000_gear_apply
sim_a4000_gear_middle:
 cmp.w #50,-$15fa(a4)
 bne sim_native_gear_middle
 movem.l d1-d2/a0-a2,-(sp)
 move.l 12(a5),a1
 bsr sim_a4000_car
 addq.l #6,a0
 lea $38(a1),a2
 move.l 16(a5),a1
 move.w $1e(a1),d1
sim_a4000_gear_apply:
 lea sim_a4000_gear_calls(pc),a1
 addq.l #1,(a1)
 move.w (a2),d0
 moveq #6,d2
 bsr sim_approach_50
 move.w d0,(a2)
 movem.l (sp)+,d1-d2/a0-a2
 rts

; Four wheel pairs per car at private +8 (velocity/position words each).
sim_a4000_wheel:
 cmp.w #50,-$15fa(a4)
 bne sim_native_wheel
 movem.l d0-d4/a0-a2,-(sp)
 lea sim_a4000_wheel_calls(pc),a0
 addq.l #1,(a0)
 moveq #0,d3
 move.b -3(a5),d3
 move.l 8(a5),a1
 bsr sim_a4000_car
 addq.l #8,a0
 move.w d3,d0
 lsl.w #2,d0
 adda.w d0,a0
 add.w d3,d3
 lea $4c(a1),a2
 adda.w d3,a2
 lea -$73fc(a4),a1
 move.w (a1,d3.w),d1
 move.l -$e6(a5),a1
 addq.l #4,a1
 move.w (a2),d0
 bsr sim_airborne_pair_50
 move.w d0,(a2)
 movem.l (sp)+,d0-d4/a0-a2
 rts

; Both native wheel-velocity zeroing sites: $CC9E and $D1B0, eight bytes.
; d0.l is twice the wheel index. Preserve incoming X, then replay MOVEA/CLR.
sim_a4000_wheel_contact:
 cmp.w #50,-$15fa(a4)
 bne .native
 movem.l d0-d2/a0-a1,-(sp)
 moveq #0,d2
 addx.b d2,d2
 move.w d2,-(sp)
 lea sim_a4000_contact_calls(pc),a0
 addq.l #1,(a0)
 move.l 8(a5),a1
 bsr sim_a4000_car
 clr.w 24(a0,d0.w)
 add.w d0,d0
 lea 8(a0),a0
 clr.l (a0,d0.w)
 move.w (sp)+,d2
 lsr.b #1,d2
 movem.l (sp)+,d0-d2/a0-a1
.native:
 move.l 8(a5),a0
 clr.w $4c(a0,d0.l)
 rts

sim_native_terrain: dcb.w 48/2,0
 rts
sim_native_suspension_bias: dcb.w 164/2,0
 rts
sim_native_suspension_return: dcb.w 262/2,0
 rts
sim_native_gear38: dcb.w 72/2,0
 rts
sim_native_gear34: dcb.w 72/2,0
 rts
sim_native_gear_middle: dcb.w 72/2,0
 rts
sim_native_wheel: dcb.w 148/2,0
 rts
 even
 dc.b "4DA4PHYS"
 dc.w 1,SIM_PRIVATE_BYTES
sim_a4000_private: dcb.b SIM_PRIVATE_BYTES,0

 even
 dc.b "4DA4STAT"
 dc.w 5,15
sim_a4000_gear_calls: dc.l 0
sim_a4000_wheel_calls: dc.l 0
sim_a4000_contact_calls: dc.l 0
sim_a4000_return_above_calls: dc.l 0
sim_a4000_return_below_calls: dc.l 0
sim_a4000_bias_calls: dc.l 0
sim_a4000_engine_calls: dc.l 0
sim_a4000_delay5_calls: dc.l 0
sim_a4000_delay10_calls: dc.l 0
sim_a4000_delay30_calls: dc.l 0
sim_a4000_terrain_calls: dc.l 0,0,0,0
sim_a4000_skid_calls: dc.l 0

; $10234..$10248 and $1024A..$10260, within native suspension $10012.
; Preserve its geometry/penetration branches and cap at extension 384. Both
; native paths form a0 = car + 2*wheel + $54; the variable path also sets d0.
sim_a4000_extension_capped:
 move.w d0,-(sp)
 move.w #192,d0
 bsr sim_a4000_extension_apply
 move.w (sp)+,d0
 rts
sim_a4000_extension_variable:
 move.w 12(a5),d0
 bsr sim_a4000_extension_apply
 rts
sim_a4000_extension_apply:
 move.w 14(a5),a0
 adda.l a0,a0
 adda.l 8(a5),a0
 adda.l #$54,a0
 cmp.w #50,-$15fa(a4)
 beq .new
 add.w d0,(a0)
 rts
.new:
 movem.l d0-d2/a1-a2,-(sp)
 move.l a0,a2
 move.w d0,d2
 move.l 8(a5),a1
 bsr sim_a4000_car
 move.w 14(a5),d0
 add.w d0,d0
 lea 24(a0,d0.w),a0
 move.w d2,d1
 move.w (a2),d0
 bsr sim_extension_50
 move.w d0,(a2)
 move.l a2,a0
 movem.l (sp)+,d0-d2/a1-a2
 rts

; $10030..$100D4: native bias moves toward zero by four units per call.
; Private fractional state is per wheel and independent of extension/return.
sim_a4000_suspension_bias:
 cmp.w #50,-$15fa(a4)
 bne sim_native_suspension_bias
 movem.l d0-d2/a0-a2,-(sp)
 move.l 8(a5),a1
 bsr sim_a4000_car
 move.w 14(a5),d0
 add.w d0,d0
 lea $6c(a1,d0.w),a2
 lea 40(a0,d0.w),a0
 move.w (a2),d0
 beq .apply
 lea sim_a4000_bias_calls(pc),a1
 addq.l #1,(a1)
.apply:
 moveq #0,d1
 moveq #4,d2
 bsr sim_approach_50
 move.w d0,(a2)
 movem.l (sp)+,d0-d2/a0-a2
 rts

; $1011C..$10222: zero-clearance extension approaches bias by 128 per call.
; Preserve the native asymmetric return value: only approach FROM ABOVE adds
; old_extension-new_extension to local -2. The caller's geometry uses that
; residual, so scaling its result a second time would be incorrect.
sim_a4000_suspension_return:
 cmp.w #50,-$15fa(a4)
 bne sim_native_suspension_return
 movem.l d0-d3/a0-a2,-(sp)
 move.l 8(a5),a1
 bsr sim_a4000_car
 move.w 14(a5),d0
 add.w d0,d0
 lea $54(a1,d0.w),a2
 move.w $6c(a1,d0.w),d1
 lea 32(a0,d0.w),a0
 move.w (a2),d0
 move.w d0,d3
 cmp.w d1,d3
 beq .apply
 blt .below
 lea sim_a4000_return_above_calls(pc),a1
 addq.l #1,(a1)
 bra .apply
.below:
 lea sim_a4000_return_below_calls(pc),a1
 addq.l #1,(a1)
.apply:
 move.w #128,d2
 ; sim_approach_50 uses d1 as scratch: retain original target comparison.
 move.w d1,-(sp)
 bsr sim_approach_50
 move.w (sp)+,d1
 move.w d0,(a2)
 cmp.w d1,d3
 ble .done
 sub.w d0,d3
 move.w d3,-2(a5)
.done:
 movem.l (sp)+,d0-d3/a0-a2
 rts

; $F4BC..$F4CA: Normal has already taken its separate 80-unit branch.
; Preserve A2500's 40; at 50 Hz change only this engine-state decrement to 16.
sim_a4000_engine_decay:
 move.l 12(a5),a0
 adda.l #$22,a0
 cmp.w #50,-$15fa(a4)
 beq .new
 sub.w #40,(a0)
 rts
.new:
 movem.l d0/a1,-(sp)
 lea sim_a4000_engine_calls(pc),a1
 addq.l #1,(a1)
 move.w (a0),d0
 bsr sim_engine_decay_50
 move.w d0,(a0)
 movem.l (sp)+,d0/a1
 rts

; All nonzero C6 assignments. Other native users only test/decrement the byte;
; zeroing sites remain valid. Preserve registers and incoming X like MOVE.B.
sim_a4000_delay5:
 movem.l d0-d2/a1,-(sp)
 moveq #5,d0
 lea sim_a4000_delay5_calls(pc),a1
 bra sim_a4000_delay_store
sim_a4000_delay10:
 movem.l d0-d2/a1,-(sp)
 moveq #10,d0
 lea sim_a4000_delay10_calls(pc),a1
 bra sim_a4000_delay_store
sim_a4000_delay30:
 movem.l d0-d2/a1,-(sp)
 moveq #30,d0
 lea sim_a4000_delay30_calls(pc),a1
sim_a4000_delay_store:
 moveq #0,d2
 addx.b d2,d2
 cmp.w #50,-$15fa(a4)
 bne .store
 addq.l #1,(a1)
 bsr sim_duration_20_to_50
.store:
 lsr.b #1,d2
 move.b d0,$c6(a0)
 movem.l (sp)+,d0-d2/a1
 rts

; $F842..$F872: one through four wheels on surface type four. The native
; caller copies the resulting +$2C speed to +$2A immediately after this block.
sim_a4000_terrain:
 cmp.w #50,-$15fa(a4)
 bne sim_native_terrain
 movem.l d0-d3/a0-a2,-(sp)
 move.l 8(a5),a1
 bsr sim_a4000_car
 lea 48(a0),a0
 move.w -2(a5),d3
 subq.w #1,d3
 add.w d3,d3
 lea sim_terrain_coefficients(pc),a2
 move.w (a2,d3.w),d2
 lea -$7374(a4),a2
 move.w (a2,d3.w),d1
 lea $2c(a1),a2
 move.w (a2),d0
 bsr sim_terrain_drag_50
 move.w d0,(a2)
 add.w d3,d3
 lea sim_a4000_terrain_calls(pc),a0
 addq.l #1,(a0,d3.w)
 movem.l (sp)+,d0-d3/a0-a2
 rts
; round(65536*k*(1-(1-1/k)^(2/5))), k = 256,192,128,64.
sim_terrain_coefficients: dc.w 26245,26255,26276,26338

; $FD64..$FD6A: original doubled absolute slip angle becomes local -2.
; Both subsequent unsigned speed clamps must see the converted loss.
sim_a4000_skid_loss:
 add.w d0,d0
 cmp.w #50,-$15fa(a4)
 bne .native
 movem.l d1-d2/a0-a1,-(sp)
 lea sim_a4000_skid_calls(pc),a1
 addq.l #1,(a1)
 move.l 8(a5),a1
 bsr sim_a4000_car
 lea 50(a0),a0
 move.w $2a(a1),d1
 move.w $2c(a1),d2
 bsr sim_skid_loss_50
 movem.l (sp)+,d1-d2/a0-a1
.native:
 move.w d0,-2(a5)
 rts
