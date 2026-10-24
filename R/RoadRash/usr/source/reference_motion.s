; Unit-step displacement = max(0, new + floor(3*new/2) - floor(3*old/2)).
; With constant acceleration, four steps sum to the native delta-4 endpoint
; convention. Floor differences retain half units without per-actor carries.
; This calibrates distance; it does not backdate input or change acceleration.
; Same reference-step displacement, with the old speed carried on the stack.
; Between the two hooks, the native update has no calls or exits: all paths
; join at $8b4d2. Pop the saved word before resuming at $8b4e2.
 IFNE STEP_FIELDS-1
 FAIL "Reference motion requires one-field simulation"
 ENDC
reference_motion_begin:
 move.w $12(a1),-(a7)
 move.w $14(a1),d1
 beq reference_motion_displacement
 jmp step_physics_fast_code+$8b4aa-$8b486(pc)
reference_motion_displacement:
 move.w $12(a1),d0
 move.w $a6f00,d2
public_ref_43 equ *-4
 mulu.w d2,d0
 movem.l d1/d3,-(a7)
 move.l d0,d3
 add.l d0,d0
 moveq #0,d1
 move.w 8(a7),d1
 sub.l d1,d0
 lsr.l #1,d3
 lsr.l #1,d1
 add.l d3,d0
 sub.l d1,d0
 bpl .store
 moveq #0,d0
.store:
 movem.l (a7)+,d1/d3
 addq.l #2,a7
 move.l d0,$26(a1)
 jmp step_physics_fast_code+$8b4e2-$8b486(pc)
