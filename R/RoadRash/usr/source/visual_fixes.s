; Original presentation bug fixes, independent of CUSTOM2 and CPU selection.
; Compare full 16.16 separation before rounding. D0 must still carry the
; difference of segment indices for the native forward geometry lookup.
visual_actor_visibility:
 move.l 4(a1),d0
 move.l d0,d2
 swap d0
 sub.w $a5d1e,d0
visual_ref_0 equ *-4
 move.l d2,-(a7)
 sub.l $a5d1e,d2
visual_ref_1 equ *-4
 bmi .rear
 cmpi.l #$1e0000,d2 ; fixed 30-segment horizon, safe indices 0..30
 bge .hidden
 move.l (a7)+,d2
 jmp $89e70 ; includes the selected native/enhanced lean path
visual_ref_2 equ *-4
.rear:
 cmpi.l #-$100000,d2
 blt .rear_far
 move.w d1,-(a7)
 move.w $a5d72,d1
visual_ref_3 equ *-4
 cmp.w $12(a1),d1
 blt .mirror
 cmpi.l #-$10000,d2 ; stable one-segment close-behind boundary
 ble .mirror
 move.w (a7)+,d1
.hidden:
 move.l (a7)+,d2
 jmp $8a126
visual_ref_4 equ *-4
.mirror:
 move.w (a7)+,d1
 move.l (a7)+,d2
 jsr $88d50
visual_ref_5 equ *-4
 jmp $89f90
visual_ref_6 equ *-4
.rear_far:
 move.l (a7)+,d2
 jmp $89f90
visual_ref_7 equ *-4

; A1 has already advanced to the following segment and wrapped at 255.
; Its height byte describes the interval the camera is moving through.
; Replace EXT.W/BEQ: zero also safely follows the native positive multiply.
; Do not advance A1: forward accumulation must consume that same interval.
pl_visual_height:
 PL_START
 PL_PS $97A6,visual_height_interval
 PL_END
visual_height_interval:
 move.b 1(a1),d3
 ext.w d3
 rts
