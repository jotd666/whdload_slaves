 even
 dc.b "4DSCRANK"
 dc.w 1,12
sim_score_rank_passed: dc.l 0
sim_score_rank_table:
 dc.l 0,1000,0,2000,0,3000,0,4000,0,5000,0,6000,0,7000
sim_score_rank_cases:
 dc.l 0,0,0,0,999,0,0,1000,1,0,3502,3,0,6000,6
 dc.l 0,6999,6,0,7000,-1,0,7001,-1,-1,-1,-1
sim_score_rank_selftest:
 movem.l d0-a6,-(sp)
 lea sim_score_rank_passed(pc),a3
 clr.l (a3)
 lea sim_score_rank_table(pc),a0
 lea sim_score_rank_cases(pc),a1
 moveq #8,d7
.case:
 bsr sim_score_rank
 cmp.l 8(a1),d0
 bne sim_score_insert_test_failed
 addq.l #1,(a3)
 lea 12(a1),a1
 dbra d7,.case
 move.l #-1,48(a0)
 move.l #-1,52(a0)
 lea sim_score_rank_wide(pc),a1
 bsr sim_score_rank
 cmp.l #6,d0
 bne sim_score_insert_test_failed
 addq.l #1,(a3)
 lea sim_score_rank_cases+8*12(pc),a1
 bsr sim_score_rank
 cmp.l #-1,d0
 bne sim_score_insert_test_failed
 addq.l #1,(a3)
 clr.l 48(a0)
 move.l #3502,52(a0)
 lea sim_score_rank_cases+3*12(pc),a1
 bsr sim_score_rank
 cmp.l #-1,d0
 bne sim_score_insert_test_failed
 addq.l #1,(a3)
 move.l #7000,52(a0)
 movem.l (sp)+,d0-a6
 rts
sim_score_rank_wide: dc.l 1,$fffffffe
sim_score_insert_test_failed:
 lea sim_score_insert_test_failed(pc),a0
 adda.l #perf_failure-sim_score_insert_test_failed,a0
 move.l #27,(a0)
 illegal
 bra sim_score_insert_test_failed

 IFD SIM_SCORE_INSERT_TEST
; Controlled completed-result fixture. Use actual native insertion, mapping,
; row copy and sorted saver. The records display and name-entry UI are bypassed.
; The caller already loaded the table and closed queue capture for disk I/O.
 IFGE SIM_SCORE_INSERT_TEST-4
 FAIL "SIM_SCORE_INSERT_TEST must be 1..3"
 ENDC
 IFLE SIM_SCORE_INSERT_TEST
 FAIL "SIM_SCORE_INSERT_TEST must be 1..3"
 ENDC
sim_score_insert_fixture:
 movem.l d0-a6,-(sp)
 link a5,#-64
 lea sim_score_insert_test_mode(pc),a0
 moveq #0,d0
 move.w -$15fa(a4),d0
 move.l d0,(a0)
 move.b -$16b8(a4),-1(a5)
 and.b #$f9,-$16b8(a4)
 clr.b -19(a5)
 IFEQ SIM_SCORE_INSERT_TEST-1
 move.l #1751,d0
 ENDC
 IFEQ SIM_SCORE_INSERT_TEST-2
 move.l #65536,d0
 ENDC
 IFEQ SIM_SCORE_INSERT_TEST-3
 move.l #196608000,d0
 ENDC
 move.w d0,-$2f0(a4)
 lea sim_results_summary(pc),a0
 move.l d0,4(a0)
 bsr sim_score_eligibility
 lea sim_score_insert_test_eligible(pc),a0
 moveq #0,d0
 move.b -19(a5),d0
 move.l d0,(a0)
 cmp.w #1,d0
 bne sim_score_insert_test_failed
 clr.w -(sp)
 pea sim_score_insert_test_prompt(pc)
 move.w -40(a5),-(sp)
 lea sim_score_insert_fixture(pc),a0
 adda.l #tape_game-sim_score_insert_fixture,a0
 move.l (a0),a0
 adda.l #$3e02,a0
 jsr (a0)
 addq.l #8,sp
 clr.w -(sp)
 pea sim_score_insert_test_prompt(pc)
 move.w -40(a5),-(sp)
 lea sim_score_insert_fixture(pc),a0
 adda.l #tape_game-sim_score_insert_fixture,a0
 move.l (a0),a0
 adda.l #$3e02,a0
 jsr (a0)
 addq.l #8,sp
 lea sim_score_insert_test_count(pc),a0
 addq.l #1,(a0)
 move.b -1(a5),-$16b8(a4)
 unlk a5
 movem.l (sp)+,d0-a6
 rts

; Test-only $3F16 interception, after the ORIGINAL native row6 copy. Discard
; the PSS return and execute the actual native sorted saver, then unwind the
; native insertion frame. No replacement for insertion or sorting is used.
sim_score_insert_test_finish:
 addq.l #4,sp
 lea sim_score_insert_test_finish(pc),a0
 adda.l #tape_game-sim_score_insert_test_finish,a0
 move.l (a0),a0
 adda.l #$3fba,a0
 jsr (a0)
 lea sim_score_insert_test_save(pc),a0
 move.l d0,(a0)
 unlk a5
 rts
; Test-only rejected insertion: bypass just the original records display.
sim_score_insert_test_reject:
 addq.l #4,sp
 lea sim_score_insert_test_rejected(pc),a0
 addq.l #1,(a0)
 unlk a5
 rts
 even
 dc.b "4DSCINS!"
 dc.w 1,SIM_SCORE_INSERT_TEST
sim_score_insert_test_count: dc.l 0
sim_score_insert_test_eligible: dc.l 0
sim_score_insert_test_save: dc.l -1
sim_score_insert_test_rejected: dc.l 0
sim_score_insert_test_mode: dc.l 0
sim_score_insert_test_prompt: dc.b "Record",0
 even
 ENDC
