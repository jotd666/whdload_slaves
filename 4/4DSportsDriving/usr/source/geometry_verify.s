TWIN_SAVE:MACRO
 movem.l d0-a6,-(sp)
 lea \1(pc),a0
 move.l sp,a1
 moveq #14,d0
.copy\@:
 move.l (a1)+,(a0)+
 dbra d0,.copy\@
 movem.l (sp)+,d0-a6
 ENDM

; VERIFY-only twins: compare the original machine-code loop with its replacement
; on the same live inputs. Original code is copied at load time, never embedded.
; Each twin leaves the native result in place and traps at the first mismatch.
TWIN_FRAME = $bd6

twin_vertices:
 TWIN_SAVE twin_input_regs
 bsr twin_save_frame
 movem.l twin_input_regs(pc),d0-a6
 bsr perf_vertices_body
 TWIN_SAVE twin_result_regs
 bsr twin_save_result
 bsr twin_restore_frame
 movem.l twin_input_regs(pc),d0-a6
 bsr twin_original_vertices
 TWIN_SAVE twin_native_regs
 bsr twin_compare_frame
 ; d4-d7 and a2-a6 are live/preserved at the native exit.
 lea twin_result_regs+16(pc),a0
 lea twin_native_regs+16(pc),a1
 moveq #3,d0
 bsr twin_compare_longs
 lea twin_result_regs+40(pc),a0
 lea twin_native_regs+40(pc),a1
 moveq #4,d0
 bsr twin_compare_longs
 lea twin_vertices_count(pc),a0
 addq.l #1,(a0)
 movem.l twin_native_regs(pc),d0-a6
 rts

twin_emit:
 TWIN_SAVE twin_input_regs
 bsr twin_save_frame
 move.l -$bc6(a5),a0
 lea twin_output_before(pc),a1
 bsr twin_copy_output
 movem.l twin_input_regs(pc),d0-a6
 bsr perf_emit_body
 TWIN_SAVE twin_result_regs
 bsr twin_save_result
 move.l twin_input_frame+TWIN_FRAME-$bc6(pc),a0
 lea twin_output_after(pc),a1
 bsr twin_copy_output
 bsr twin_restore_frame
 lea twin_output_before(pc),a0
 move.l -$bc6(a5),a1
 bsr twin_copy_output
 movem.l twin_input_regs(pc),d0-a6
 bsr twin_original_emit
 TWIN_SAVE twin_native_regs
 bsr twin_compare_frame
 lea twin_result_regs+16(pc),a0
 lea twin_native_regs+16(pc),a1
 moveq #3,d0
 bsr twin_compare_longs
 lea twin_result_regs+40(pc),a0
 lea twin_native_regs+40(pc),a1
 moveq #4,d0
 bsr twin_compare_longs
 lea twin_output_after(pc),a0
 move.l twin_input_frame+TWIN_FRAME-$bc6(pc),a1
 moveq #0,d0
 move.b -$19b4(a4),d0
 subq.w #1,d0
 bmi.s .no_output
 bsr twin_compare_longs
.no_output:
 lea twin_emit_count(pc),a0
 addq.l #1,(a0)
 movem.l twin_native_regs(pc),d0-a6
 rts

twin_copy_output:
 moveq #0,d0
 move.b -$19b4(a4),d0
 subq.w #1,d0
 bmi.s .done
.loop:
 move.l (a0)+,(a1)+
 dbra d0,.loop
.done:
 rts

twin_save_frame:
 lea -TWIN_FRAME(a5),a0
 lea twin_input_frame(pc),a1
 bra.s twin_copy_frame
twin_save_result:
 lea -TWIN_FRAME(a5),a0
 lea twin_result_frame(pc),a1
 bra.s twin_copy_frame
twin_restore_frame:
 lea twin_input_frame(pc),a0
 lea -TWIN_FRAME(a5),a1
twin_copy_frame:
 move.w #TWIN_FRAME/2-1,d0
.loop:
 move.w (a0)+,(a1)+
 dbra d0,.loop
 rts

twin_compare_frame:
 lea -TWIN_FRAME(a5),a0
 lea twin_result_frame(pc),a1
 move.w #TWIN_FRAME/2-1,d0
.loop:
 cmpm.w (a0)+,(a1)+
 bne.s twin_failed
 dbra d0,.loop
 rts

twin_compare_longs:
.loop:
 cmpm.l (a0)+,(a1)+
 bne.s twin_failed
 dbra d0,.loop
 rts

twin_failed:
 lea twin_mismatch(pc),a2
 move.l a0,(a2)+
 move.l a1,(a2)
 lea perf_failure(pc),a2
 move.l #2,(a2)
 illegal
 bra.s twin_failed

; Synthetic frame cases exercise empty, cached, clipped, near-plane and new
; vertices before the game starts. All fixture memory belongs to the slave.
geometry_selftest:
 movem.l d0-a6,-(sp)
 lea geometry_globals_before(pc),a0
 move.w -$19b4(a4),(a0)+
 move.w -$199a(a4),(a0)+
 move.l -$2b38(a4),(a0)+
 move.l -$2b34(a4),(a0)+
 clr.w -$199a(a4)
 move.w #-160,-$2b38(a4)
 move.w #160,-$2b36(a4)
 move.w #-100,-$2b34(a4)
 move.w #100,-$2b32(a4)
 lea geometry_case_index(pc),a0
 clr.w (a0)
.case:
 lea geometry_test_frame(pc),a0
 move.w #TWIN_FRAME/2-1,d0
.clear:
 clr.w (a0)+
 dbra d0,.clear
 move.l a0,a5
 lea geometry_indices(pc),a0
 move.l a0,-$e(a5)
 lea geometry_model_vertex(pc),a0
 move.l a0,-$16(a5)
 move.w #$4000,-$70(a5)
 move.w #$4000,-$68(a5)
 move.w #$4000,-$60(a5)
 moveq #0,d0
 move.w geometry_case_index(pc),d0
 lsl.w #3,d0
 lea geometry_cases(pc),a0
 adda.w d0,a0
 move.b (a0),-$19b4(a4)
 move.b 1(a0),-$19f(a5)
 move.l 2(a0),-$bc2(a5)
 move.w #123,-$7c2(a5)
 moveq #0,d4
 moveq #0,d5
 moveq #0,d6
 moveq #0,d7
 bsr twin_vertices
 ; W3 uses the now-projected points; include the empty primitive too.
 lea geometry_emit_output(pc),a0
 move.l a0,-$bc6(a5)
 lea geometry_indices(pc),a0
 move.l a0,-$12(a5)
 clr.l -$1a4(a5)
 moveq #0,d4
 bsr twin_emit
 lea geometry_case_index(pc),a0
 addq.w #1,(a0)
 cmp.w #7,(a0)
 bne .case
 lea geometry_globals_before(pc),a0
 move.w (a0)+,-$19b4(a4)
 move.w (a0)+,-$199a(a4)
 move.l (a0)+,-$2b38(a4)
 move.l (a0)+,-$2b34(a4)
 movem.l (sp)+,d0-a6
 rts
geometry_case_index: dc.w 0
geometry_globals_before: ds.b 12
geometry_indices: dc.b 0,0
geometry_model_vertex: dc.w 200,100,400,0
; count.b, state.b, x.w, y.w, pad.w
geometry_cases:
 dc.b 0,0
 dc.w 0,0,0
 dc.b 1,0
 dc.w 0,0,0
 dc.b 1,0
 dc.w 160,100,0
 dc.b 1,0
 dc.w -161,-101,0
 dc.b 1,1
 dc.w 0,0,0
 dc.b 2,0
 dc.w 161,101,0
 dc.b 1,$ff
 dc.w 0,0,0
geometry_emit_output: ds.l 2
geometry_test_frame: ds.b TWIN_FRAME
 even
 CNOP 0,4
 dc.b "4DTWIN!!"
twin_vertices_count: dc.l 0
twin_emit_count: dc.l 0
twin_mismatch: dc.l 0,0
twin_input_regs: ds.l 15
twin_result_regs: ds.l 15
twin_native_regs: ds.l 15
twin_input_frame: ds.b TWIN_FRAME
twin_result_frame: ds.b TWIN_FRAME
twin_output_before: ds.l 255
twin_output_after: ds.l 255
 even
twin_original_vertices: ds.b $161c-$1440
 rts
twin_original_emit: ds.b $16ca-$1662
 rts
