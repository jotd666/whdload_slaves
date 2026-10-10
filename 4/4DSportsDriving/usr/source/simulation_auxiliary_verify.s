; Independent expected vectors derive from integer rational formulae.
; Scratch is private; these tests never modify game/replay state.
sim_aux_selftest:
 movem.l d0-a6,-(sp)
 lea sim_aux_passed(pc),a6
 clr.l (a6)
 lea sim_aux_test_state(pc),a0
 lea sim_aux_vertical_cases(pc),a1
 move.w #SIM_AUX_VERTICAL_CASES-1,d7
.vertical:
 move.w 2(a1),(a0)
 move.l #$11223344,2(a0)
 move.w #$5566,6(a0)
 move.w (a1),d0
 bsr sim_aux_vertical_50
 cmp.l 4(a1),d0
 bne .failed
 cmp.w 8(a1),d1
 bne .failed
 move.w (a0),d2
 cmp.w 10(a1),d2
 bne .failed
 cmp.l #$11223344,2(a0)
 bne .failed
 cmp.w #$5566,6(a0)
 bne .failed
 addq.l #1,(a6)
 lea 12(a1),a1
 dbra d7,.vertical
 lea sim_aux_component_cases(pc),a1
 move.w #SIM_AUX_COMPONENT_CASES-1,d7
.component:
 move.b 2(a1),(a0)
 move.w (a1),d0
 bsr sim_aux_component_50
 cmp.l 4(a1),d0
 bne .failed
 move.b (a0),d2
 cmp.b 3(a1),d2
 bne .failed
 addq.l #1,(a6)
 addq.l #8,a1
 dbra d7,.component
 ; Actual chained calls: five50Hz steps reproduce two native20Hz steps.
 lea sim_aux_chain_cases(pc),a1
 move.w #SIM_AUX_CHAIN_CASES-1,d7
.chain:
 clr.l (a0)
 move.w (a1),d5
 moveq #0,d6
 moveq #4,d4
.steps:
 move.w d5,d0
 bsr sim_aux_vertical_50
 move.w d1,d5
 add.l d0,d6
 dbra d4,.steps
 cmp.w 2(a1),d5
 bne .failed
 cmp.l 4(a1),d6
 bne .failed
 tst.w (a0)
 bne .failed
 addq.l #1,(a6)
 addq.l #8,a1
 dbra d7,.chain
 movem.l (sp)+,d0-a6
 rts
.failed:
 lea sim_aux_selftest(pc),a0
 adda.l #perf_failure-sim_aux_selftest,a0
 move.l #36,(a0)
 illegal
 bra .failed
 even
 dc.b "4DAUXTST"
 dc.w 1,SIM_AUX_VERTICAL_CASES+SIM_AUX_COMPONENT_CASES+SIM_AUX_CHAIN_CASES
sim_aux_passed: dc.l 0
 dc.l $41555831
sim_aux_test_state: dcb.b 8,0
 dc.l $41555832
 include "simulation_auxiliary_cases.s"
