; Native twins share the geometry frame buffers; no nested geometry call occurs
; in either slice. Compare every register and all 3030 bytes of frame locals.
book_twin_clear:
 TWIN_SAVE book_input_regs
 bsr twin_save_frame
 movem.l book_input_regs(pc),d0-a6
 bsr perf_clear_body
 TWIN_SAVE book_result_regs
 bsr twin_save_result
 bsr twin_restore_frame
 movem.l book_input_regs(pc),d0-a6
 bsr book_original_clear
 TWIN_SAVE book_native_regs
 bsr twin_compare_frame
 bsr book_compare_regs
 lea book_clear_count(pc),a0
 addq.l #1,(a0)
 movem.l book_native_regs(pc),d0-a6
 rts

book_twin_epilogue:
 TWIN_SAVE book_input_regs
 bsr twin_save_frame
 move.l -$1994(a4),a0
 lea book_output_before(pc),a1
 move.l (a0)+,(a1)+
 move.w (a0),(a1)
 movem.l book_input_regs(pc),d0-a6
 bsr perf_epilogue_body
 TWIN_SAVE book_result_regs
 bsr twin_save_result
 move.l -$1994(a4),a0
 lea book_output_after(pc),a1
 move.l (a0)+,(a1)+
 move.w (a0),(a1)
 bsr twin_restore_frame
 lea book_output_before(pc),a0
 move.l -$1994(a4),a1
 move.l (a0)+,(a1)+
 move.w (a0),(a1)
 movem.l book_input_regs(pc),d0-a6
 bsr book_original_epilogue
 TWIN_SAVE book_native_regs
 bsr twin_compare_frame
 bsr book_compare_regs
 move.l -$1994(a4),a0
 lea book_output_after(pc),a1
 cmpm.l (a0)+,(a1)+
 bne book_failed
 cmpm.w (a0)+,(a1)+
 bne book_failed
 lea book_epilogue_count(pc),a0
 addq.l #1,(a0)
 movem.l book_native_regs(pc),d0-a6
 rts
book_compare_regs:
 lea book_result_regs(pc),a0
 lea book_native_regs(pc),a1
 moveq #14,d0
 bra twin_compare_longs

book_selftest:
 movem.l d0-a6,-(sp)
 lea book_globals_before(pc),a0
 move.w -$19b4(a4),(a0)+
 move.l -$1994(a4),(a0)
 lea geometry_test_frame(pc),a0
 move.w #TWIN_FRAME/2-1,d0
.clear:
 clr.w (a0)+
 dbra d0,.clear
 move.l a0,a5
 lea book_clear_cases(pc),a2
 moveq #8,d7
.clear_case:
 lea -$19f(a5),a0
 move.w (a2)+,d1
 moveq #-1,d2
 bsr book_twin_clear
 dbra d7,.clear_case
 lea geometry_emit_output(pc),a0
 move.l a0,-$1994(a4)
 lea book_depth_cases(pc),a2
 move.w #(book_depth_cases_end-book_depth_cases)/10-1,d7
.depth_case:
 clr.w -$94(a5)
 move.b #5,-$95(a5)
 move.b #$73,-$21(a5)
 move.b 1(a2),-$19b4(a4)
 move.l 2(a2),-$1a4(a5)
 move.w 6(a2),-$1c8(a5)
 bsr book_twin_epilogue
 move.l -$1994(a4),a0
 move.w (a0),d0
 cmp.w 8(a2),d0
 bne.s book_failed
 cmp.w #1,-$94(a5)
 bne.s book_failed
 lea 10(a2),a2
 dbra d7,.depth_case
 lea book_globals_before(pc),a0
 move.w (a0)+,-$19b4(a4)
 move.l (a0),-$1994(a4)
 lea book_cases_passed(pc),a0
 move.l #(book_depth_cases_end-book_depth_cases)/10+9,(a0)
 movem.l (sp)+,d0-a6
 rts
book_failed:
 lea perf_failure(pc),a0
 move.l #6,(a0)
 illegal
 bra.s book_failed

 CNOP 0,4
 dc.b "4DBOOK!!"
book_clear_count: dc.l 0
book_epilogue_count: dc.l 0
book_cases_passed: dc.l 0
book_input_regs: ds.l 15
book_result_regs: ds.l 15
book_native_regs: ds.l 15
book_output_before: ds.b 6
book_output_after: ds.b 6
book_globals_before: ds.b 6
book_clear_cases: dc.w 0,1,2,3,4,7,15,31,255
book_original_clear: ds.b 6
 rts
book_original_epilogue: ds.b $217c-$20c8
 rts
 include "bookkeeping_cases.i"
