; Derive authoritative lean before this actor's simulation pose side effects.
; Render-only traversal reuses the stored value. Keep the native visibility
; interval and displaced display-record clear / cop comparison unchanged.
step_fused_lean:
 btst #0,step_pose_busy(pc)
 beq .original
 movem.l d0-d2/a4,-(a7)
 move.w 4(a1),d0
 sub.w $a5d1e,d0
public_ref_91 equ *-4
 bmi .restore
 cmpi.w #30,d0
 bgt .restore
 move.l 4(a1),d2
 lea step_lean_busy(pc),a4
 st.b (a4)
 bsr step_compute_lean
 lea step_lean_busy(pc),a4
 clr.b (a4)
.restore:
 movem.l (a7)+,d0-d2/a4
.original:
 clr.w 18(a0)
 cmpa.l #$a5de0,a1
public_ref_92 equ *-4
 rts
