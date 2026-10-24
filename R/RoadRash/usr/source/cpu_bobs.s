; reuse the native CPU cookie-cut dispatcher for images up to
; 80 pixels wide, with a bounded 128 KiB public pixel cache on 040/060.
e_cpu_reset:
 movem.l d0/a0,-(a7)
 move.l e_mask_table(pc),d0
 addi.l #$8000,d0
 lea e_cpu_cursor(pc),a0
 move.l d0,(a0)+
 addi.l #$20000,d0
 move.l d0,(a0)
 movem.l (a7)+,d0/a0
 rts

e_cpu_init:
 lea e_cpu_jump(pc),a0
 move.l a5,d0
 addi.l #$3611a,d0
 move.l d0,2(a0)
 rts

e_cpu_cache:
 movem.l d0-d7/a0-a6,-(a7)
 btst #3,cpu_attention+3(pc)
 beq .done
 cmpi.w #10,d2
 bhi .done
 move.l d5,d0
 lsl.l #2,d0
 move.l e_cpu_cursor(pc),a0
 move.l a0,d1
 add.l d0,d1
 cmp.l e_cpu_limit(pc),d1
 bhi .done
 lea e_cpu_cursor(pc),a1
 move.l d1,(a1)
 move.l a0,12(a3)
 move.l d4,a1
 lsr.l #1,d0
 subq.w #1,d0
.copy:
 move.w (a1)+,(a0)+
 dbf d0,.copy
.done:
 movem.l (a7)+,d0-d7/a0-a6
 rts

; Called with all native bob input registers intact and the selected metadata.
e_cpu_try:
 move.l a0,-(a7)
 move.l e_mask_current(pc),a0
 cmpa.l #0,a0
 beq .no
 cmpi.w #80,d3
 bhi .no
 tst.l 12(a0)
 beq .no
 move.l 12(a0),a1
 move.l a0,-(a7)
 lea $dff000,a0
 bsr e_blitter_wait
 move.l (a7)+,a0
 bsr e_cpu_dirty
 move.l (a7)+,a0
 addq.l #8,a7 ; discard this BSR and the patched entry JSR return addresses
 jmp e_cpu_jump(pc)
.no:
 move.l (a7)+,a0
 rts

e_cpu_dirty:
 move.w sr,-(a7)
 movem.l d0/a0,-(a7)
 bsr e_dirty_slot
 bcs .done
 move.w d1,d0
 bpl .positive
 moveq #0,d0
.positive:
 cmp.w (a0),d0
 bcc .done
 move.w d0,(a0)
.done:
 movem.l (a7)+,d0/a0
 move.w (a7)+,ccr
 rts

; A1 metadata, A3 first-plane word, D2 plane stride. Preserve caller state.
e_cpu_recolor:
 movem.l d0-d1/a0-a3,-(a7)
 move.l 12(a1),a0
 cmpa.l #0,a0
 beq .done
 move.l a3,d0
 sub.l (a1),d0
 adda.l d0,a0
 moveq #3,d1
.copy:
 move.w (a3),(a0)
 adda.w d2,a3
 adda.w d2,a0
 dbf d1,.copy
.done:
 movem.l (a7)+,d0-d1/a0-a3
 rts

e_cpu_cursor: dc.l 0
e_cpu_limit: dc.l 0
e_cpu_jump: jmp $0.l
