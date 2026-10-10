; Execute all five real clamp hooks, both cars, all modes and both X flags.
; A private synthetic A4 window isolates native positions and mode selection.
sim_centroid_clamp_selftest:
 movem.l d1-a6,-(sp)
 lea sim_centroid_clamp_selftest(pc),a0
 adda.l #sim_a4000_private-sim_centroid_clamp_selftest,a0
 lea sim_centroid_clamp_backup(pc),a1
 moveq #SIM_PRIVATE_BYTES/4-1,d0
.save:
 move.l (a0)+,(a1)+
 dbra d0,.save
 moveq #0,d7
.x:
 lea sim_centroid_clamp_cases(pc),a3
 move.w #(sim_centroid_clamp_cases_end-sim_centroid_clamp_cases)/28-1,d6
.case:
 lea sim_centroid_clamp_native(pc),a4
 adda.l #$15fa,a4
 move.w (a3),-$15fa(a4)
 lea sim_centroid_clamp_args(pc),a5
 lea -$92e(a4),a0
 tst.w 2(a3)
 beq .car
 lea -$85e(a4),a0
.car:
 move.l a0,8(a5)
 move.l #12345,$b9c(a4)
 move.l 12(a3),$ba0(a4)
 move.l #54321,$ba4(a4)
 lea sim_centroid_clamp_selftest(pc),a0
 adda.l #sim_a4000_private+132-sim_centroid_clamp_selftest,a0
 moveq #5,d1
 move.w #111,d2
.seed:
 move.w d2,(a0)+
 add.w #111,d2
 dbra d1,.seed
 lea sim_centroid_clamp_selftest(pc),a1
 adda.l 8(a3),a1
 move.w d7,d0
 lsr.w #1,d0
 move.l #$87654321,d0
 movea.l #$1234,a0
 jsr (a1)
 moveq #0,d1
 addx.w d1,d1
 cmp.w d7,d1
 bne .failed
 cmp.l #$87654321,d0
 bne .failed
 cmpa.l #$1234,a0
 bne .failed
 move.l $b9c(a4),d0
 cmp.l 16(a3),d0
 bne .failed
 move.l $ba0(a4),d0
 cmp.l 20(a3),d0
 bne .failed
 move.l $ba4(a4),d0
 cmp.l 24(a3),d0
 bne .failed
 moveq #-1,d4
 cmp.w #50,(a3)
 bne .index_ready
 move.w 4(a3),d4
 bmi .index_ready
 lsr.w #1,d4
 tst.w 2(a3)
 beq .index_ready
 addq.w #3,d4
.index_ready:
 lea sim_centroid_clamp_selftest(pc),a0
 adda.l #sim_a4000_private+132-sim_centroid_clamp_selftest,a0
 moveq #0,d3
 move.w #111,d2
.check:
 move.w (a0)+,d0
 cmp.w d3,d4
 bne .retained
 tst.w d0
 bne .failed
 bra .next
.retained:
 cmp.w d2,d0
 bne .failed
.next:
 add.w #111,d2
 addq.w #1,d3
 cmp.w #6,d3
 blo .check
 lea sim_centroid_clamp_selftest(pc),a0
 adda.l #sim_physics_passed-sim_centroid_clamp_selftest,a0
 addq.l #1,(a0)
 lea 28(a3),a3
 dbra d6,.case
 addq.w #1,d7
 cmp.w #2,d7
 blo .x
 moveq #0,d0
 bra .restore
.failed:
 moveq #1,d0
.restore:
 lea sim_centroid_clamp_backup(pc),a0
 lea sim_centroid_clamp_selftest(pc),a1
 adda.l #sim_a4000_private-sim_centroid_clamp_selftest,a1
 moveq #SIM_PRIVATE_BYTES/4-1,d1
.copy:
 move.l (a0)+,(a1)+
 dbra d1,.copy
 movem.l (sp)+,d1-a6
 rts
 even
sim_centroid_clamp_cases:
 dc.w 10,0,2,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,-1,12345,0,54321
 dc.w 10,0,-1,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,0,12345,0,54321
 dc.w 10,0,-1,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,1,12345,1,54321
 dc.w 10,0,0,0
 dc.l sim_centroid_xmax-sim_centroid_clamp_selftest,12,1962239,12,54321
 dc.w 10,0,0,0
 dc.l sim_centroid_xmin-sim_centroid_clamp_selftest,12,3840,12,54321
 dc.w 10,0,4,0
 dc.l sim_centroid_zmax-sim_centroid_clamp_selftest,12,12345,12,1962239
 dc.w 10,0,4,0
 dc.l sim_centroid_zmin-sim_centroid_clamp_selftest,12,12345,12,3840
 dc.w 10,1,2,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,-1,12345,0,54321
 dc.w 10,1,-1,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,0,12345,0,54321
 dc.w 10,1,-1,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,1,12345,1,54321
 dc.w 10,1,0,0
 dc.l sim_centroid_xmax-sim_centroid_clamp_selftest,12,1962239,12,54321
 dc.w 10,1,0,0
 dc.l sim_centroid_xmin-sim_centroid_clamp_selftest,12,3840,12,54321
 dc.w 10,1,4,0
 dc.l sim_centroid_zmax-sim_centroid_clamp_selftest,12,12345,12,1962239
 dc.w 10,1,4,0
 dc.l sim_centroid_zmin-sim_centroid_clamp_selftest,12,12345,12,3840
 dc.w 20,0,2,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,-1,12345,0,54321
 dc.w 20,0,-1,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,0,12345,0,54321
 dc.w 20,0,-1,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,1,12345,1,54321
 dc.w 20,0,0,0
 dc.l sim_centroid_xmax-sim_centroid_clamp_selftest,12,1962239,12,54321
 dc.w 20,0,0,0
 dc.l sim_centroid_xmin-sim_centroid_clamp_selftest,12,3840,12,54321
 dc.w 20,0,4,0
 dc.l sim_centroid_zmax-sim_centroid_clamp_selftest,12,12345,12,1962239
 dc.w 20,0,4,0
 dc.l sim_centroid_zmin-sim_centroid_clamp_selftest,12,12345,12,3840
 dc.w 20,1,2,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,-1,12345,0,54321
 dc.w 20,1,-1,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,0,12345,0,54321
 dc.w 20,1,-1,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,1,12345,1,54321
 dc.w 20,1,0,0
 dc.l sim_centroid_xmax-sim_centroid_clamp_selftest,12,1962239,12,54321
 dc.w 20,1,0,0
 dc.l sim_centroid_xmin-sim_centroid_clamp_selftest,12,3840,12,54321
 dc.w 20,1,4,0
 dc.l sim_centroid_zmax-sim_centroid_clamp_selftest,12,12345,12,1962239
 dc.w 20,1,4,0
 dc.l sim_centroid_zmin-sim_centroid_clamp_selftest,12,12345,12,3840
 dc.w 50,0,2,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,-1,12345,0,54321
 dc.w 50,0,-1,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,0,12345,0,54321
 dc.w 50,0,-1,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,1,12345,1,54321
 dc.w 50,0,0,0
 dc.l sim_centroid_xmax-sim_centroid_clamp_selftest,12,1962239,12,54321
 dc.w 50,0,0,0
 dc.l sim_centroid_xmin-sim_centroid_clamp_selftest,12,3840,12,54321
 dc.w 50,0,4,0
 dc.l sim_centroid_zmax-sim_centroid_clamp_selftest,12,12345,12,1962239
 dc.w 50,0,4,0
 dc.l sim_centroid_zmin-sim_centroid_clamp_selftest,12,12345,12,3840
 dc.w 50,1,2,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,-1,12345,0,54321
 dc.w 50,1,-1,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,0,12345,0,54321
 dc.w 50,1,-1,0
 dc.l sim_centroid_floor-sim_centroid_clamp_selftest,1,12345,1,54321
 dc.w 50,1,0,0
 dc.l sim_centroid_xmax-sim_centroid_clamp_selftest,12,1962239,12,54321
 dc.w 50,1,0,0
 dc.l sim_centroid_xmin-sim_centroid_clamp_selftest,12,3840,12,54321
 dc.w 50,1,4,0
 dc.l sim_centroid_zmax-sim_centroid_clamp_selftest,12,12345,12,1962239
 dc.w 50,1,4,0
 dc.l sim_centroid_zmin-sim_centroid_clamp_selftest,12,12345,12,3840
sim_centroid_clamp_cases_end:
sim_centroid_clamp_args: dcb.l 3,0
sim_centroid_clamp_backup: dcb.b SIM_PRIVATE_BYTES,0
sim_centroid_clamp_native: dcb.b $21b0,0
