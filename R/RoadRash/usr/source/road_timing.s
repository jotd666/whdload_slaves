; Selected by C_ROAD_TIMING after the Enhanced framerate/CPU/Fast gate.
; Road normalization: evaluate the four-field reference,
; retaining quarter-unit output while running the simulation every field.
step_road_fraction: dc.l 0
step_road_history: dc.w 0,0,0,0
step_road_reference:
 movem.l d0/d2/a0,-(a7)
 move.l $26(a1),d1
 lsl.l #2,d1
 lsr.l #8,d1
 lea step_road_history(pc),a0
 move.w d6,d0
 add.w (a0),d0
 add.w 2(a0),d0
 add.w 4(a0),d0
 move.w 2(a0),4(a0)
 move.w (a0),2(a0)
 move.w d6,(a0)
 muls.w d0,d1
 asr.l #8,d1
; MULS.W #768 followed by ASR.L #8 is exactly three times the
; sign-extended low word. Keep that truncation before the cheaper adds.
 ext.l d1
 move.l d1,d0
 add.l d1,d1
 add.l d0,d1
 lea step_road_fraction(pc),a0
 add.l (a0),d1
 move.l d1,d0
 bpl .divide
 addq.l #3,d0
.divide:
; Round signed quarters toward zero and retain the signed remainder.
 asr.l #2,d0
 move.l d0,d2
 lsl.l #2,d2
 sub.l d2,d1
 move.l d1,(a0)
 move.l d0,d1
 add.w d1,$36(a1)
 movem.l (a7)+,d0/d2/a0
 jmp $8bad2
public_ref_145 equ *-4
; Preserve the measured placement of the later Fast RAM code copies.
 ds.b 12

; Normalize native per-call NPC road-centre accumulation.
step_actor_road:
 movem.l d0/d2/a0,-(a7)
 move.l a1,d0
 subi.l #$a5d60,d0
public_ref_146 equ *-4
 cmpi.l #$1180,d0
 bcc .native
 lsr.l #5,d0
 lea step_actor_road_fraction(pc),a0
 adda.l d0,a0
 move.w d1,d0
 ext.l d0
 add.l (a0),d0
 move.l d0,d2
 asr.l #2,d0
 add.w d0,$36(a1)
 andi.l #3,d2
 move.l d2,(a0)
 bra .done
.native:
 add.w d1,$36(a1)
.done:
 movem.l (a7)+,d0/d2/a0
 move.b (a4)+,d1
 rts
 cnop 0,4
step_actor_road_fraction: ds.l 35

; Keep external fractional road position with native companion record copies.
step_actor_road_copy:
 movem.l d0-d2/a2,-(a7)
 move.l a0,d0
 subi.l #$a5d60,d0
public_ref_147 equ *-4
 cmpi.l #$1180,d0
 bcc .done
 move.l d0,d2
 andi.l #$7f,d2
 bne .done
 lsr.l #5,d0
 lea step_actor_road_fraction(pc),a2
 adda.l d0,a2
 move.l a1,d1
 subi.l #$a5d60,d1
public_ref_148 equ *-4
 cmpi.l #$1180,d1
 bcc .clear
 move.l d1,d2
 andi.l #$7f,d2
 bne .clear
 lsr.l #5,d1
 sub.l d0,d1
 move.l (a2,d1.w),(a2)
 bra .done
.clear:
 clr.l (a2)
.done:
 movem.l (a7)+,d0-d2/a2
 lsr.w $2c(a0)
 move.w #1,$8b484
public_ref_149 equ *-4
 rts

; Native reactivation at $90c64 repositions the rider and clears +$36/+$38.
; Its external road remainder belongs to the discarded trajectory as well.
step_actor_road_reactivate:
 move.w sr,-(a7)
 movem.l d0-d1/a0,-(a7)
 move.l a1,d0
 subi.l #$a5d60,d0
public_ref_150 equ *-4
 cmpi.l #$1180,d0
 bcc .done
 move.l d0,d1
 andi.l #$7f,d1
 bne .done
 lsr.l #5,d0
 lea step_actor_road_fraction(pc),a0
 clr.l (a0,d0.w)
.done:
 movem.l (a7)+,d0-d1/a0
 move.w (a7)+,ccr
 lea $a851a,a4
public_ref_151 equ *-4
 jmp $90c6a
public_ref_152 equ *-4
