; Run the actual patched7D56 and a pristine relocatable copy in a live race.
; No physics/input substitution survives the fixture; all borrowed state is
; restored. Native pause+replay flags stop CIA production/channel consumption.
 IFD SIM_CAMERA_NATIVE_TEST
sim_camera_native_fixture:
 cmp.w #50,-$15fa(a4)
 bne .return
 cmp.w #155,-$940(a4)
 bne .return
 tst.b $45(a4)
 bne .return
 movem.l d0-a6,-(sp)
 lea sim_camera_native_marker(pc),a6
 tst.l 12(a6)
 bne .out
 move.w -$15fa(a4),-(sp)
 move.w $44(a4),-(sp)
 move.b -$174a(a4),d0
 move.w d0,-(sp)
 lea sim_camera_native_fixture(pc),a0
 adda.l #sim_schedule_modal-sim_camera_native_fixture,a0
 move.w (a0),-(sp)
 move.w #1,(a0)
 move.w #$0102,$44(a4)
 move.b #1,-$174a(a4)
 lea -$a80(a4),a0
 lea sim_camera_saved_native(pc),a1
 bsr .copy
 lea sim_camera_state(pc),a0
 lea sim_camera_saved_state(pc),a1
 move.l (a0)+,(a1)+
 move.l (a0),(a1)
 lea sim_camera_cases(pc),a3
 move.w #SIM_CAMERA_CASES-1,d7
.case:
 move.w d7,16(a6)
 bsr .initialize
 lea -$a80(a4),a0
 lea sim_camera_case_native(pc),a1
 bsr .copy
 moveq #10,d6
.legacy:
 move.w d6,18(a6)
 bsr .reset_case
 move.w d6,-$15fa(a4)
 bsr .original
 lea -$a80(a4),a0
 lea sim_camera_expected_native(pc),a1
 bsr .copy
 bsr .reset_case
 move.w d6,-$15fa(a4)
 lea sim_camera_state(pc),a0
 move.l #$01020304,(a0)+
 move.l #$04030201,(a0)
 bsr .patched
 lea sim_camera_expected_native(pc),a0
 lea -$a80(a4),a1
 move.w #$460/4-1,d0
.compare_legacy:
 move.l (a0)+,d1
 cmp.l (a1)+,d1
 bne .failed
 dbra d0,.compare_legacy
 lea sim_camera_state(pc),a0
 cmp.l #$01020304,(a0)+
 bne .failed
 cmp.l #$04030201,(a0)
 bne .failed
 addq.l #1,12(a6)
 add.w #10,d6
 cmp.w #30,d6
 bne .legacy
 move.w #50,18(a6)
 bsr .reset_case
 move.w #20,-$15fa(a4)
 bsr .original
 bsr .original
 lea -$960(a4),a0
 lea sim_camera_expected_position(pc),a1
 bsr .copy_position
 bsr .reset_case
 move.w #50,-$15fa(a4)
 lea sim_camera_state(pc),a0
 clr.l (a0)+
 clr.l (a0)
 moveq #4,d6
.fifty:
 lea -$960(a4),a0
 lea sim_camera_previous_position(pc),a1
 bsr .copy_position
 bsr .patched
 lea sim_camera_previous_position(pc),a0
 lea -$954(a4),a1
 bsr .compare_position
 lea sim_camera_state(pc),a0
 tst.w 2(a0)
 bne .failed
 tst.w 6(a0)
 bne .failed
 moveq #7,d0
.fractions:
 cmp.b #4,(a0)
 bhi .failed
 tst.b (a0)+
 beq .next_fraction
 addq.l #1,20(a6)
.next_fraction:
 dbra d0,.fractions
 dbra d6,.fifty
 lea sim_camera_expected_position(pc),a0
 lea -$960(a4),a1
 bsr .compare_position
 addq.l #1,12(a6)
 addq.l #8,a3
 dbra d7,.case
 tst.l 20(a6)             ; diagonal cases must exercise real remainders
 beq .failed
 lea sim_camera_saved_native(pc),a0
 lea -$a80(a4),a1
 bsr .copy
 lea sim_camera_saved_state(pc),a0
 lea sim_camera_state(pc),a1
 move.l (a0)+,(a1)+
 move.l (a0),(a1)
 lea sim_camera_native_fixture(pc),a0
 adda.l #sim_schedule_modal-sim_camera_native_fixture,a0
 move.w (sp)+,(a0)
 move.w (sp)+,d0
 move.b d0,-$174a(a4)
 move.w (sp)+,$44(a4)
 move.w (sp)+,-$15fa(a4)
.out:
 movem.l (sp)+,d0-a6
.return:
 rts
.initialize:
 lea -$a80(a4),a0
 move.w #$460/4-1,d0
.clear:
 clr.l (a0)+
 dbra d0,.clear
 move.w #1,-$940(a4)      ; skip fixed-view selection in all test rates
 ; Case: baseX,vertical error,deltaX,deltaZ. Car1 mirrors car0.
 move.w (a3),d0
 move.w d0,-$960(a4)
 neg.w d0
 move.w d0,-$95a(a4)
 move.w 2(a3),d0
 add.w #270,d0
 move.w d0,-$95e(a4)
 move.w #270,d0
 sub.w 2(a3),d0
 move.w d0,-$958(a4)
 move.w (a3),d0
 add.w 4(a3),d0
 move.w d0,-$92e+$a4(a4)
 muls #64,d0
 move.l d0,-$92e(a4)
 neg.l d0
 move.l d0,-$85e(a4)
 move.w (a3),d0
 add.w 4(a3),d0
 neg.w d0
 move.w d0,-$85e+$a4(a4)
 move.w 6(a3),d0
 move.w d0,-$92e+$a8(a4)
 muls #64,d0
 move.l d0,-$92e+8(a4)
 neg.l d0
 move.l d0,-$85e+8(a4)
 move.w 6(a3),d0
 neg.w d0
 move.w d0,-$85e+$a8(a4)
 rts
.reset_case:
 lea sim_camera_case_native(pc),a0
 lea -$a80(a4),a1
.copy:
 move.w #$460/4-1,d0
.loop:
 move.l (a0)+,(a1)+
 dbra d0,.loop
 rts
.copy_position:
 move.l (a0)+,(a1)+
 move.l (a0)+,(a1)+
 move.l (a0),(a1)
 rts
.compare_position:
 moveq #2,d0
.position:
 move.l (a0)+,d1
 cmp.l (a1)+,d1
 bne .failed
 dbra d0,.position
 rts
.original:
 movem.l d2-d7/a2-a6,-(sp)
 lea sim_camera_original(pc),a0
 jsr (a0)
 movem.l (sp)+,d2-d7/a2-a6
 rts
.patched:
 movem.l d2-d7/a2-a6,-(sp)
 jsr -$7f92(a4)
 movem.l (sp)+,d2-d7/a2-a6
 rts
.failed:
 lea sim_camera_native_fixture(pc),a0
 adda.l #perf_failure-sim_camera_native_fixture,a0
 move.l #38,(a0)
 illegal
 bra.s .failed
 even
sim_camera_native_marker:
 dc.b "4DCAMNAT"
 dc.w 1,SIM_CAMERA_CASES*3
 dc.l 0
 dc.w 0,0                 ; reverse case index,phase10/20/50
 dc.l 0                   ; observed nonzero fractional bytes
 dc.b "CMN1"
sim_camera_saved_native: dcb.b $460,0
sim_camera_case_native: dcb.b $460,0
sim_camera_expected_native: dcb.b $460,0
sim_camera_saved_state: dcb.b SIM_CAMERA_BYTES,0
sim_camera_expected_position: dcb.b 12,0
sim_camera_previous_position: dcb.b 12,0
sim_camera_original: dcb.b $80ee-$7d56,0
 dc.b "CMN2"
 include "simulation_camera_cases.i"
 ENDC

; Test-only displacement before checkpoint1500. Real camera updates create
; nonzero fractions, which must survive disk restoration at that checkpoint.
; Not an input-recorded event: this fixture only proves replay from slot1.
 IFD SIM_CAMERA_SEED_TEST
sim_camera_seed_fixture:
 cmp.w #50,-$15fa(a4)
 bne .return
 cmp.w #1498,-$940(a4)
 bne .return
 tst.b $45(a4)
 bne .return
 movem.l d0/a0,-(sp)
 lea sim_camera_seed_marker(pc),a0
 tst.l 12(a0)
 bne .out
 move.l -$92e(a4),d0
 asr.l #6,d0
 sub.w #10000,d0
 move.w d0,-$960(a4)
 move.l -$926(a4),d0
 asr.l #6,d0
 sub.w #10000,d0
 move.w d0,-$95c(a4)
 addq.l #1,12(a0)
.out:
 movem.l (sp)+,d0/a0
.return:
 rts
 even
sim_camera_seed_marker:
 dc.b "4DCAMSPN"
 dc.w 1,1498
 dc.l 0
 ENDC
