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
 dc.w 1,3
sim_a4000_gear_calls: dc.l 0
sim_a4000_wheel_calls: dc.l 0
sim_a4000_contact_calls: dc.l 0
