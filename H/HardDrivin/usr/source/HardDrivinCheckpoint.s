; Development phase solver: evaluate nearby checkpoint/finish sections after
; the completed physics pose, avoiding an extra scene-pass delay. Native award
; routines retain their latches, bonus amounts, sounds and lap side effects.
; Zero/eight-field and forced-native updates retain the original scene checks.
; Native scene checks also remain the fallback outside this local query.
_checkpoint_post:
 IFD VERIFY_DISPATCH_NATIVE
 rts
 ELSE
 movem.l d0-d7/a0-a6,-(a7)
 move.w _time_scalar_fields(pc),d0
 beq .done
 cmpi.w #8,d0
 beq .done
 tst.b -$522c(a4)
 beq .done
 movea.l -$671c(a4),a0
 movea.l -$50da(a4),a1
 tst.b -$66b0(a4)
 beq.s .bounds
 movea.l -$50d6(a4),a1
.bounds:
 lea 40(a0),a2
 cmpa.l a1,a2
 bhi .done
 move.w 18(a0),d0
 or.w 38(a0),d0
 andi.w #$3000,d0
 beq .done
 move.w _terrain_selected(pc),-(a7)
 move.l a0,-(a7)
 lea -116(a7),a7
 lea -$6bba(a4),a0
 movea.l a7,a1
 moveq #28,d7
.save:
 move.l (a0)+,(a1)+
 dbf d7,.save
 addi.l #20,-$671c(a4)
 lea _terrain_selected(pc),a0
 clr.w (a0)
 move.b #1,-$6bb9(a4)
 movea.l _phase_steering_body(pc),a0
 adda.l #$c022-$b398,a0
 jsr (a0)
 moveq #0,d6
 ; Use current physics orientation, not last frame's wrong-way flag.
 move.w -$6b9c(a4),d1
 cmp.w -$6b90(a4),d1
 bgt .restore
 move.w _terrain_selected(pc),d0
 cmpi.w #1,d0
 blo.s .restore
 cmpi.w #2,d0
 bhi.s .restore
 subq.w #1,d0
 muls.w #20,d0
 movea.l 116(a7),a0
 adda.l d0,a0
 move.w 18(a0),d6
.restore:
 movea.l a7,a0
 lea -$6bba(a4),a1
 moveq #28,d7
.copy:
 move.l (a0)+,(a1)+
 dbf d7,.copy
 lea 116(a7),a7
 move.l (a7)+,-$671c(a4)
 lea _terrain_selected(pc),a0
 move.w (a7)+,(a0)
 movea.l _phase_steering_body(pc),a0
 btst #12,d6
 beq.s .finish
 adda.l #$92c0-$b398,a0
 bra.s .call
.finish:
 btst #13,d6
 beq.s .done
 adda.l #$936a-$b398,a0
.call:
 move.b -$16d0(a4),-(a7)
 clr.b -$16d0(a4)
 jsr (a0)
 move.b (a7)+,-$16d0(a4)
.done:
 movem.l (a7)+,d0-d7/a0-a6
 rts
 ENDC
