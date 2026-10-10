; Format domain, physical-row lookup, sentinel/branch and X preservation tests.
 even
 dc.b "4DSCFMT!"
 dc.w 1,39
sim_score_display_passed: dc.l 0
sim_score_display_buffer_guard: dc.l $11223344
sim_score_display_test_buffer: dcb.b 16,$a5
sim_score_display_buffer_end: dc.l $55667788
sim_score_display_test_indices: dc.w 5,0,6,2,1,4,3
sim_score_display_test_records:
 dc.l $00000000,$00000000
 dc.l $00000000,$00000dae
 dc.l $00000000,$00002233
 dc.l $00000000,$000249f2
 dc.l $00000000,$17700000
 dc.l $00000009,$fffffff6
 dc.l $ffffffff,$ffffffff
sim_score_display_format_cases:
 dc.l $00000000,$00000000
 dc.w 1
 dc.b " 0:00.00",0
 even
 dc.l $00000000,$00000001
 dc.w 1
 dc.b " 0:00.01",0
 even
 dc.l $00000000,$00000002
 dc.w 1
 dc.b " 0:00.02",0
 even
 dc.l $00000000,$00000005
 dc.w 1
 dc.b " 0:00.05",0
 even
 dc.l $00000000,$00000063
 dc.w 1
 dc.b " 0:00.99",0
 even
 dc.l $00000000,$00000064
 dc.w 1
 dc.b " 0:01.00",0
 even
 dc.l $00000000,$0000176f
 dc.w 1
 dc.b " 0:59.99",0
 even
 dc.l $00000000,$00001770
 dc.w 1
 dc.b " 1:00.00",0
 even
 dc.l $00000000,$00002233
 dc.w 1
 dc.b " 1:27.55",0
 even
 dc.l $00000000,$00000dae
 dc.w 1
 dc.b " 0:35.02",0
 even
 dc.l $00000000,$000249f2
 dc.w 1
 dc.b "25:00.02",0
 even
 dc.l $00000000,$0004fff6
 dc.w 1
 dc.b "54:36.70",0
 even
 dc.l $00000000,$0004fffb
 dc.w 1
 dc.b "54:36.75",0
 even
 dc.l $00000000,$17700000
 dc.w 1
 dc.b "65536:00.00",0
 even
 dc.l $00000000,$ffffffff
 dc.w 1
 dc.b "715827:52.95",0
 even
 dc.l $00000001,$00000000
 dc.w 1
 dc.b "715827:52.96",0
 even
 dc.l $00000001,$fffffffe
 dc.w 1
 dc.b "1431655:45.90",0
 even
 dc.l $00000009,$fffffff6
 dc.w 1
 dc.b "7158278:49.50",0
 even
 dc.l $ffffffff,$ffffffff
 dc.w 1
 dc.b " 0:00.00",0
 even
 dc.l $00000000,$00000000
 dc.w 0
 dc.b " 0:00",0
 even
 dc.l $00000000,$000249f2
 dc.w 0
 dc.b "25:00",0
 even
 dc.l $00000009,$fffffff6
 dc.w 0
 dc.b "7158278:49",0
 even
sim_score_display_lookup_cases:
 dc.l 0,$00000009,$fffffff6
 dc.l 1,$00000000,$00000000
 dc.l 2,$ffffffff,$ffffffff
 dc.l 3,$00000000,$00002233
 dc.l 4,$00000000,$00000dae
 dc.l 5,$00000000,$17700000
 dc.l 6,$00000000,$000249f2
 dc.l 7,$ffffffff,$ffffffff
 dc.l 65535,$ffffffff,$ffffffff
sim_score_display_top_cases:
 dc.w 6,$ff,5,0,0,0,4,0
sim_score_display_selftest:
 movem.l d0-a6,-(sp)
 lea sim_score_display_passed(pc),a6
 clr.l (a6)
 lea sim_score_display_format_cases(pc),a2
 moveq #21,d7
.format:
 lea sim_score_display_test_buffer(pc),a0
 moveq #3,d0
.fill:
 move.l #$a5a5a5a5,(a0)+
 dbra d0,.fill
 lea sim_score_display_test_buffer(pc),a0
 move.l (a2),d2
 move.l 4(a2),d0
 move.w 8(a2),d1
 move.l #$11223344,d4
 move.l #$55667788,d5
 move.l #$12345678,d6
 bsr sim_score_format100
 cmp.l #$11223344,d4
 bne sim_score_display_failed
 cmp.l #$55667788,d5
 bne sim_score_display_failed
 cmp.l #$12345678,d6
 bne sim_score_display_failed
 lea sim_score_display_test_buffer(pc),a0
 lea 10(a2),a1
.compare:
 move.b (a0)+,d0
 cmp.b (a1)+,d0
 bne sim_score_display_failed
 tst.b d0
 bne .compare
 lea sim_score_display_buffer_end(pc),a3
.tail:
 cmpa.l a3,a0
 beq .next
 cmp.b #$a5,(a0)+
 bne sim_score_display_failed
 bra .tail
.next:
 move.l a1,d0
 addq.l #1,d0
 and.l #-2,d0
 movea.l d0,a2
 addq.l #1,(a6)
 dbra d7,.format
 lea sim_score_records(pc),a0
 lea sim_score_display_test_records(pc),a1
 moveq #13,d0
.copy:
 move.l (a1)+,(a0)+
 dbra d0,.copy
 ; The helper accesses only A4-$160A; a virtual anchor needs no large arena.
 lea sim_score_display_test_indices(pc),a4
 adda.l #$160a,a4
 lea sim_score_display_lookup_cases(pc),a2
 moveq #8,d7
.lookup:
 move.l (a2),d0
 bsr sim_score_row_time
 cmp.l 4(a2),d2
 bne sim_score_display_failed
 cmp.l 8(a2),d0
 bne sim_score_display_failed
 addq.l #1,(a6)
 lea 12(a2),a2
 dbra d7,.lookup
 moveq #0,d6
.top_pass:
 lea sim_score_display_top_cases(pc),a2
 moveq #3,d7
.top:
 move.w (a2),-$160a(a4)
 moveq #0,d5
 tst.w d6
 beq .clear_x
 moveq #-1,d5
 add.l d5,d5
 bra .invoke
.clear_x:
 add.l d5,d5
.invoke:
 bsr sim_score_top_guard
 seq d4
 moveq #0,d5
 addx.w d5,d5
 cmp.w d6,d5
 bne sim_score_display_failed
 cmp.b 3(a2),d4
 bne sim_score_display_failed
 addq.l #1,(a6)
 addq.l #4,a2
 dbra d7,.top
 addq.w #1,d6
 cmp.w #2,d6
 blo .top_pass
 move.w #5,-$160a(a4)
 lea sim_score_records(pc),a0
 moveq #13,d0
.clear:
 move.l #-1,(a0)+
 dbra d0,.clear
 lea sim_score_display_buffer_guard(pc),a0
 cmp.l #$11223344,(a0)
 bne sim_score_display_failed
 lea sim_score_display_buffer_end(pc),a0
 cmp.l #$55667788,(a0)
 bne sim_score_display_failed
 movem.l (sp)+,d0-a6
 rts
sim_score_display_failed:
 lea sim_score_display_failed(pc),a0
 adda.l #perf_failure-sim_score_display_failed,a0
 move.l #28,(a0)
 illegal
 bra sim_score_display_failed

 IFD SIM_SCORE_DISPLAY_TEST
; Execute all seven original row formatters, retaining the entire native
; NUL-separated row and its column offsets for independent host comparison.
sim_score_display_fixture:
 movem.l d0-a6,-(sp)
 lea sim_score_display_rows(pc),a2
 moveq #0,d7
.row:
 move.w -$15fa(a4),(a2)+
 move.l a2,-(sp)
 move.w d7,-(sp)
 lea sim_score_display_fixture(pc),a0
 adda.l #tape_game-sim_score_display_fixture,a0
 move.l (a0),a0
 adda.l #$3c52,a0
 movem.l d2-d7/a2-a6,-(sp)
 ; Arguments must remain directly below the native return address.
 move.l 46(sp),-(sp)
 move.w d7,-(sp)
 jsr (a0)
 addq.l #6,sp
 movem.l (sp)+,d2-d7/a2-a6
 addq.l #6,sp
 addq.l #4,a2
 move.w -$15fa(a4),(a2)+
 lea -$165e(a4),a0
 moveq #20,d0
.copy:
 move.l (a0)+,(a2)+
 dbra d0,.copy
 addq.w #1,d7
 cmp.w #7,d7
 blo .row
 lea sim_score_display_native_count(pc),a0
 addq.l #1,(a0)
 movem.l (sp)+,d0-a6
 rts
 even
 dc.b "4DSCFROW"
 dc.w 1,92
sim_score_display_native_count: dc.l 0
sim_score_display_rows: dcb.b 644,$a5
 dc.l $524f5753
 ENDC
