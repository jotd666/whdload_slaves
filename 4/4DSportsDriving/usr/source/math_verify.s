; Runtime originals are copied before hooks; arithmetic cases are synthetic.
math_selftest:
 movem.l d0-a6,-(sp)
 move.l d7,a0
 move.l (a0),d0
 add.l d0,d0
 add.l d0,d0
 add.l #$8002,d0
 move.l d0,a4
 lea math_backface_cases(pc),a2
 move.w #(math_backface_cases_end-math_backface_cases)/14-1,d6
.face:
 move.l a2,-(sp)
 bsr math_original_backface
 cmp.w 12(a2),d0
 bne math_failed
 move.l d0,d5
 bsr perf_backface_body
 cmp.l d5,d0
 bne math_failed
 addq.l #4,sp
 lea 14(a2),a2
 dbra d6,.face
 lea math_parent_cases(pc),a2
 move.w #(math_parent_cases_end-math_parent_cases)/38-1,d6
.parent:
 move.b 31(a2),-(sp)
 pea math_parent_output(pc)
 pea 12(a2)
 pea 6(a2)
 pea (a2)
 bsr math_original_parent
 lea math_parent_output(pc),a0
 lea 32(a2),a1
 bsr math_compare_parent
 lea 18(sp),sp
 move.b 31(a2),-(sp)
 pea math_parent_output(pc)
 pea 12(a2)
 pea 6(a2)
 pea (a2)
 bsr perf_parent_body
 lea math_parent_output(pc),a0
 lea 32(a2),a1
 bsr math_compare_parent
 ; Both pointer arguments advance by four, not six, in the original.
 move.l (sp),d0
 sub.l a2,d0
 cmp.l #4,d0
 bne math_failed
 move.l 12(sp),a0
 lea math_parent_output+4(pc),a1
 cmpa.l a1,a0
 bne math_failed
 lea 18(sp),sp
 lea 38(a2),a2
 dbra d6,.parent
 lea math_selftest_passed(pc),a0
 move.l #176,(a0)
 movem.l (sp)+,d0-a6
 rts

math_compare_parent:
 cmpm.l (a0)+,(a1)+
 bne.s math_failed
 cmpm.w (a0)+,(a1)+
 bne.s math_failed
 rts
math_failed:
 lea perf_failure(pc),a0
 move.l #4,(a0)
 illegal
 bra.s math_failed

; Live twins use a private copy of the C argument area. Restore destination
; bytes before the native call, including when destination aliases an input.
; Leave the native result and native argument postincrements for the caller.
math_twin_backface:
 TWIN_SAVE math_input_regs
 subq.l #4,sp
 move.l 8(sp),(sp)
 movem.l math_input_regs(pc),d0-a6
 bsr perf_backface_body
 TWIN_SAVE math_result_regs
 movem.l math_input_regs(pc),d0-a6
 bsr math_original_backface
 TWIN_SAVE math_native_regs
 cmp.l math_result_regs(pc),d0
 bne math_failed
 bsr math_compare_live_regs
 lea math_face_count(pc),a0
 addq.l #1,(a0)
 movem.l math_native_regs(pc),d0-a6
 addq.l #4,sp
 rts

math_twin_parent:
 TWIN_SAVE math_input_regs
 lea -18(sp),sp
 lea 22(sp),a0
 move.l sp,a1
 bsr math_copy_args
 move.l 12(sp),a0
 lea math_output_before(pc),a1
 move.l (a0)+,(a1)+
 move.w (a0),(a1)
 movem.l math_input_regs(pc),d0-a6
 bsr perf_parent_body
 TWIN_SAVE math_result_regs
 move.l 34(sp),a0
 lea math_output_after(pc),a1
 move.l (a0)+,(a1)+
 move.w (a0),(a1)
 move.l sp,a0
 lea math_result_args(pc),a1
 bsr math_copy_args
 lea math_output_before(pc),a0
 move.l 34(sp),a1
 move.l (a0)+,(a1)+
 move.w (a0),(a1)
 lea 22(sp),a0
 move.l sp,a1
 bsr math_copy_args
 movem.l math_input_regs(pc),d0-a6
 bsr math_original_parent
 TWIN_SAVE math_native_regs
 move.l 34(sp),a0
 lea math_output_after(pc),a1
 cmpm.l (a0)+,(a1)+
 bne math_failed
 cmpm.w (a0)+,(a1)+
 bne math_failed
 move.l sp,a0
 lea math_result_args(pc),a1
 moveq #8,d0
.args:
 cmpm.w (a0)+,(a1)+
 bne math_failed
 dbra d0,.args
 bsr math_compare_live_regs
 move.l sp,a0
 lea 22(sp),a1
 bsr math_copy_args
 lea math_parent_count(pc),a0
 addq.l #1,(a0)
 movem.l math_native_regs(pc),d0-a6
 lea 18(sp),sp
 rts

math_copy_args:
 moveq #8,d0
.loop:
 move.w (a0)+,(a1)+
 dbra d0,.loop
 rts
math_compare_live_regs:
 ; Aztec C callers reload scratch d0-d1/a0-a1 and do not consume CCR.
 lea math_result_regs+8(pc),a0
 lea math_native_regs+8(pc),a1
 moveq #5,d0
.data:
 cmpm.l (a0)+,(a1)+
 bne math_failed
 dbra d0,.data
 lea math_result_regs+40(pc),a0
 lea math_native_regs+40(pc),a1
 moveq #4,d0
.address:
 cmpm.l (a0)+,(a1)+
 bne math_failed
 dbra d0,.address
 rts

 CNOP 0,4
 dc.b "4DMTWIN!"
math_face_count: dc.l 0
math_parent_count: dc.l 0
math_input_regs: ds.l 15
math_result_regs: ds.l 15
math_native_regs: ds.l 15
math_result_args: ds.b 18
math_output_before: ds.b 6
math_output_after: ds.b 6
 even
 CNOP 0,4
 dc.b "4DMATH!!"
math_selftest_passed: dc.l 0
math_parent_output: dc.l 0,0
math_original_backface: ds.b $ab82-$aad4
math_original_parent: ds.b $a968-$a756
 include "math_cases.i"
