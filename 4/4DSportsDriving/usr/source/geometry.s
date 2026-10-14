perf_geometry_init:
 movem.l d0-d1/a0-a1,-(sp)
 move.l perf_game(pc),d0
 add.l #$161c,d0
 lea perf_vertices_exit+2(pc),a0
 move.l d0,(a0)
 move.l perf_game(pc),d0
 add.l #$1446,d0
 lea perf_vertices_original+2(pc),a0
 move.l d0,(a0)
 move.l perf_game(pc),d0
 add.l #$194a,d0
 lea perf_emit_exit+2(pc),a0
 move.l d0,(a0)
 IFD PERF_TWIN
 move.l perf_game(pc),a0
 adda.l #$1440,a0
 lea twin_original_vertices(pc),a1
 move.w #($161c-$1440)/2-1,d0
 bsr.s .copy
 move.l perf_game(pc),a0
 adda.l #$1662,a0
 lea twin_original_emit(pc),a1
 move.w #($16ca-$1662)/2-1,d0
 bsr.s .copy
 ENDC
 movem.l (sp)+,d0-d1/a0-a1
 IFD PERF_TWIN
 ; Use the relocated data-hunk base before the game's own a4 is established.
 move.l a4,-(sp)
 move.l d7,a4
 move.l (a4),a4
 adda.l a4,a4
 adda.l a4,a4
 adda.l #$8002,a4
 bsr geometry_selftest
 move.l (sp)+,a4
 ENDC
 rts
 IFD PERF_TWIN
.copy:
 move.w (a0)+,(a1)+
 dbra d0,.copy
 rts
 ENDC

perf_vertices:
 move.b #15,-9(a5)
 tst.w -$199a(a4)
 bne.s perf_vertices_original
 IFD PERF_TWIN
 bsr twin_vertices
 ELSE
 bsr perf_vertices_body
 ENDC
perf_vertices_exit:
 jmp $0.l
perf_vertices_original:
 jmp $0.l

perf_emit:
 IFD PERF_TWIN
 bsr twin_emit
 ELSE
 bsr perf_emit_body
 ENDC
perf_emit_exit:
 jmp $0.l

; W2: cached/new vertex bookkeeping. Called with the original a4/a5.
; Helpers retain their a4 jump-table entries. Rare mode uses the native loop.
perf_vertices_body:
 move.l a2,-(sp)
 move.b #15,-9(a5)
 move.w #1,-$84(a5)
 clr.w -$86(a5)
 move.l -$e(a5),a2
 clr.w -8(a5)
 moveq #0,d0
 move.b -$19b4(a4),d0
 beq .finish
 clr.w d6
 lea -$5a(a5),a3
.loop:
 moveq #0,d0
 move.b (a2)+,d0
 move.w d0,-2(a5)
 move.w d0,d7
 add.w d0,d0
 add.w d0,d0
 move.w d0,d5
 lea -$bc2(a5),a0
 add.l a0,d0
 move.l d0,(a3,d6.w)
 lea -$19f(a5),a0
 move.b (a0,d7.w),d0
 cmp.b #$ff,d0
 beq .new
 tst.b d0
 beq .visible
 cmp.b #1,d0
 beq .near
 bra .next
.new:
 lea -$1e(a5),a0
 add.w d5,d5
 move.l d5,a1
 adda.l -$16(a5),a1
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.b -$18(a5),d7
 beq .transform
 moveq #0,d4
 move.b -$17(a5),d4
 lea -$19f(a5),a0
 cmp.b #$ff,(a0,d4.w)
 beq .transform
 move.b d7,-(sp)
 pea -$1c0(a5)
 pea -$70(a5)
 pea -$1e(a5)
 moveq #0,d0
 move.b d4,d0
 add.w d0,d0
 add.w d4,d0
 add.w d0,d0
 lea -$7c6(a5),a0
 adda.l d0,a0
 move.l a0,-(sp)
 jsr -$7f86(a4)
 lea 18(sp),sp
 bra.s .transformed
.transform:
 move.l -$1e(a5),-$1ba(a5)
 move.w -$1a(a5),-$1b6(a5)
 lea -$1c0(a5),a0
 move.l a0,d0
 lea -$70(a5),a1
 lea -$1ba(a5),a0
 jsr -$7bd8(a4)
.transformed:
 move.w -2(a5),d7
 move.l d7,d0
 add.w d0,d0
 add.w d7,d0
 add.w d0,d0
 move.l d0,a0
 lea -$7c6(a5),a1
 adda.l a1,a0
 move.l -$1c0(a5),(a0)+
 move.w -$1bc(a5),(a0)
 move.w -$1c8(a5),d0
 add.w d0,-$1bc(a5)
 cmp.w #12,-$1bc(a5)
 bge.s .project
 lea -$19f(a5),a0
 move.b #1,(a0,d7.w)
.near:
 move.w #1,-$86(a5)
 bra.s .next
.project:
 move.w -$1cc(a5),d0
 add.w d0,-$1c0(a5)
 move.w -$1ca(a5),d0
 add.w d0,-$1be(a5)
 move.l (a3,d6.w),a1
 lea -$1c0(a5),a0
 jsr -$7be4(a4)
 lea -$19f(a5),a0
 clr.b (a0,d7.w)
.visible:
 clr.w -$84(a5)
 tst.b -9(a5)
 beq.s .next
 move.l (a3,d6.w),a0
 bsr perf_clip
 and.b d0,-9(a5)
.next:
 addq.w #4,d6
 moveq #0,d0
 move.b -$19b4(a4),d0
 lsl.w #2,d0
 cmp.w d6,d0
 bgt .loop
 move.w d6,d0
 lsr.w #2,d0
 move.w d0,-8(a5)
 subq.w #4,d6
.finish:
 move.l a2,-$12(a5)
 move.l (sp)+,a2
 rts

; Same inclusive rectangle and bit ordering as game:$aaa2.
perf_clip:
 lea -$2b38(a4),a1
 moveq #0,d0
 move.l (a0),d1
 cmp.w 4(a1),d1
 bge.s .bottom
 moveq #1,d0
 bra.s .x
.bottom:
 cmp.w 6(a1),d1
 ble.s .x
 moveq #2,d0
.x:
 swap d1
 cmp.w (a1),d1
 bge.s .right
 addq.w #4,d0
 rts
.right:
 cmp.w 2(a1),d1
 ble.s .done
 addq.w #8,d0
.done:
 rts

; W3: emit projected points and accumulate signed view-space depth.
perf_emit_body:
 movem.l d2-d3/a3/a6,-(sp)
 move.l -$12(a5),a3
 move.l -$bc6(a5),a6
 move.l -$1a4(a5),d2
 move.l d4,d7
 moveq #0,d3
 move.b -$19b4(a4),d3
 beq.s .finish
 lea -$5a(a5),a2
.loop:
 move.l d4,d6
 move.b (a3)+,d6
 move.w d6,-$98(a5)
 move.l d6,d0
 add.w d0,d0
 add.w d6,d0
 add.w d0,d0
 lea -$7c6(a5),a0
 move.w 4(a0,d0.w),d0
 ext.l d0
 add.l d0,d2
 move.l (a2)+,a0
 move.l (a0),(a6)+
 tst.b -9(a5)
 beq.s .next
 bsr perf_clip
 and.b d0,-9(a5)
.next:
 addq.w #1,d7
 cmp.w d7,d3
 bgt.s .loop
 lea -$5a(a5),a2 ; the original leaves the slot base here
.finish:
 move.l a3,-$12(a5)
 move.l a6,-$bc6(a5)
 move.l d2,-$1a4(a5)
 movem.l (sp)+,d2-d3/a3/a6
 rts
