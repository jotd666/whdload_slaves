perf_math_init:
 IFD PERF_TWIN
 movem.l d0/a0-a1,-(sp)
 move.l perf_game(pc),a0
 adda.l #$aad4,a0
 lea math_original_backface(pc),a1
 move.w #($ab82-$aad4)/2-1,d0
 bsr.s .copy
 move.l perf_game(pc),a0
 adda.l #$a756,a0
 lea math_original_parent(pc),a1
 move.w #($a968-$a756)/2-1,d0
 bsr.s .copy
 movem.l (sp)+,d0/a0-a1
 bsr math_selftest
 ENDC
 rts
 IFD PERF_TWIN
.copy:
 move.w (a0)+,(a1)+
 dbra d0,.copy
 rts
 ENDC

; W4: retain the original's full-width X differences and wrapped Y differences.
; Stack argument: pointer to three projected (x.w,y.w) pairs.
perf_backface_body:
 move.l 4(sp),a0
 movem.l d2-d5,-(sp)
 move.w (a0),d2
 ext.l d2
 move.w 4(a0),d0
 ext.l d0
 sub.l d0,d2
 move.w 8(a0),d3
 ext.l d3
 sub.l d0,d3
 move.l d2,d0
 or.l d3,d0
 beq.s .zero
 move.w 2(a0),d4
 sub.w 6(a0),d4
 ext.l d4
 move.w 10(a0),d5
 sub.w 6(a0),d5
 ext.l d5
 move.l d4,d0
 or.l d5,d0
 beq.s .zero
 move.w d2,d0
 ext.l d0
 cmp.l d2,d0
 bne.s .wide
 move.w d3,d0
 ext.l d0
 cmp.l d3,d0
 bne.s .wide
 move.w d3,d1
 muls.w d4,d1
 move.w d2,d0
 muls.w d5,d0
 bra.s .compare
.wide:
 move.l d3,d0
 move.l d4,d1
 jsr -$78fc(a4)
 move.l d0,-(sp)
 move.l d2,d0
 move.l d5,d1
 jsr -$78fc(a4)
 move.l (sp)+,d1
.compare:
 ; SUB/BLE in the original is a signed comparison including overflow, not
 ; merely a test of the sign bit of the wrapped cross-product difference.
 sub.l d0,d1
 sgt d0
 and.l #1,d0
 bra.s .done
.zero:
 moveq #0,d0
.done:
 movem.l (sp)+,d2-d5
 rts

; W5: same eight-way mode switch and Q14 multiply as game:$a756/$3052c.
; Preserve the observable postincrements of the source and destination args.
perf_parent_body:
 link a5,#0
 movem.l d2-d4/a2-a3,-(sp)
 move.l 8(a5),a0
 move.l 12(a5),a1
 move.l 16(a5),a2
 move.l 20(a5),a3
 moveq #0,d0
 move.b 24(a5),d0
 beq .copy
 cmp.w #7,d0
 beq .negate
 bhi .copy
 moveq #0,d3
 cmp.w #3,d0
 beq.s .minus_z
 cmp.w #5,d0
 beq.s .minus_y
 cmp.w #6,d0
 beq.s .minus_x
 ; Positive cases 1/2/4: x/y/z matrix row.
 cmp.w #1,d0
 beq.s .x
 cmp.w #2,d0
 beq.s .y
 bra.s .z
.minus_z:
 moveq #1,d3
 bra.s .z
.minus_y:
 moveq #1,d3
 bra.s .y
.minus_x:
 moveq #1,d3
.x:
 move.w (a1),d2
 bra.s .row
.y:
 move.w 2(a1),d2
 addq.l #6,a2
 bra.s .row
.z:
 move.w 4(a1),d2
 lea 12(a2),a2
.row:
 add.w d2,d2
 moveq #2,d4
.loop:
 move.w d2,d0
 muls.w (a2)+,d0
 swap d0
 rol.l #2,d0
 move.w (a0)+,d1
 tst.w d3
 beq.s .add
 neg.w d1
.add:
 add.w d1,d0
 move.w d0,(a3)+
 dbra d4,.loop
 bra.s .pointers
.copy:
 move.w (a0)+,(a3)+
 move.w (a0)+,(a3)+
 move.w (a0)+,(a3)+
 bra.s .pointers
.negate:
 move.w (a0)+,d0
 neg.w d0
 move.w d0,(a3)+
 move.w (a0)+,d0
 neg.w d0
 move.w d0,(a3)+
 move.w (a0)+,d0
 neg.w d0
 move.w d0,(a3)+
.pointers:
 subq.l #2,a0
 subq.l #2,a3
 move.l a0,8(a5)
 move.l a3,20(a5)
 movem.l (sp)+,d2-d4/a2-a3
 unlk a5
 rts
