; P3 fast-stage overlap, opt-in A4000 build. Stable live frames can prepare
; geometry/pixels while the preceding copper-list switch is still pending.
; The original VBL guard remains mandatory before any Chip-RAM write.
raster_present_prepare:
 movem.l d0-d1/a0,-(sp)
 move.w raster_present_pending(pc),d0
 beq .done
 tst.b $45(a4)
 bne .wait
 tst.b $36(a4)
 bne .wait
 tst.b $a9a(a4)
 bne .wait
 move.w -$a88(a4),d0
 cmp.w -$a8a(a4),d0
 bne .wait
 ; Any layout/mode transition can draw the dashboard before the scene.
 move.b $45(a4),d0
 cmp.b $39(a4),d0
 bne .wait
 move.b $37(a4),d0
 cmp.b $38(a4),d0
 bne .wait
 move.b $35(a4),d0
 cmp.b $34(a4),d0
 bne .wait
 move.b $44(a4),d0
 cmp.b $32(a4),d0
 bne .wait
 move.b $31(a4),d0
 cmp.b $30(a4),d0
 bne .wait
 move.w $5e(a4),d0
 cmp.w -$c(a5),d0
 bne .wait
 move.w $5c(a4),d0
 cmp.w $5a(a4),d0
 bne .wait
 move.w $68(a4),d0
 cmp.w -$e(a5),d0
 bne .wait
 moveq #0,d0
 move.b $3b(a4),d0
 cmp.w #1,d0
 bhi .wait
 lea $a96(a4),a0
 move.b $a9e(a4),d1
 cmp.b (a0,d0.w),d1
 bne .wait
 lea $a98(a4),a0
 move.b $33(a4),d1
 cmp.b (a0,d0.w),d1
 bne .wait
 lea raster_present_early(pc),a0
 addq.l #1,(a0)
 bra .done
.wait:
 bsr raster_present_wait
.done:
 movem.l (sp)+,d0-d1/a0
 move.w -$a88(a4),d0
 cmp.w -$a8a(a4),d0
 rts

; Call before copyout, fallback, or any native writer. Preserve all registers.
raster_present_wait:
 move.l a0,-(sp)
 lea raster_present_pending(pc),a0
 tst.w (a0)
 beq .done
.wait:
 tst.w $d28(a4)
 beq .wait
 clr.w (a0)
.done:
 move.l (sp)+,a0
 rts
 even
raster_present_pending: dc.w 0
raster_present_early: dc.l 0
