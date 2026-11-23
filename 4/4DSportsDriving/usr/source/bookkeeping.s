; W6: bounded bookkeeping changes; leave primitive selection and depth insertion native.
perf_bookkeeping_init:
 movem.l d0/a0-a1,-(sp)
 move.l perf_game(pc),d0
 add.l #$217c,d0
 lea perf_epilogue_exit+2(pc),a0
 move.l d0,(a0)
 movem.l (sp)+,d0/a0-a1
 rts

; The state array starts at odd a5-$19f. d1.w is the DBRA counter and d2.b
; is $ff. Preserve all registers except the original a0/d1 postconditions.
perf_clear_body:
 movem.l d0/d3,-(sp)
 moveq #0,d0
 addx.b d0,d0 ; save incoming X without privileged SR access
 move.w d0,-(sp)
 move.b d2,(a0)+
 moveq #0,d3
 move.w d1,d3
 lsr.w #2,d3
 subq.w #1,d3
 bmi.s .tail
 moveq #-1,d0
.longs:
 move.l d0,(a0)+
 dbra d3,.longs
.tail:
 and.w #3,d1
 subq.w #1,d1
 bmi.s .done
.bytes:
 move.b d2,(a0)+
 dbra d1,.bytes
.done:
 move.w (sp)+,d0
 lsr.b #1,d0 ; restore X
 movem.l (sp)+,d0/d3
 tst.b d2 ; same NZVC as the original last byte store
 rts

perf_epilogue:
 bsr perf_epilogue_body
perf_epilogue_exit:
 jmp $0.l

perf_epilogue_body:
 addq.w #1,-$94(a5)
 move.l -$1994(a4),a0
 move.b -$19b4(a4),3(a0)
 move.b -$95(a5),4(a0)
 move.b -$21(a5),2(a0)
 moveq #0,d0
 move.b -$19b4(a4),d0
 cmp.w #1,d0
 beq.s .one
 cmp.w #2,d0
 beq.s .two
 cmp.w #4,d0
 beq.s .four
 cmp.w #8,d0
 beq.s .eight
 move.b d0,d1
 ext.w d1
 ext.l d1
 move.l -$1a4(a5),d0
 tst.w d1
 beq.s .wide
 ; DIVS leaves its dividend unchanged on quotient overflow. The low-word
 ; result is exact; extend it so the original d0 high word is preserved too.
 divs.w d1,d0
 bvs.s .wide
 ext.l d0
 bra.s .store
.wide:
 jsr -$78f6(a4)
 bra.s .store
.one:
 move.w -$1a2(a5),-$2(a5)
 moveq #0,d0
 bra.s .translate
.two:
 move.l -$1a4(a5),d0
 asr.l #1,d0
 bra.s .store
.four:
 move.l -$1a4(a5),d0
 asr.l #2,d0
 bra.s .store
.eight:
 move.l -$1a4(a5),d0
 asr.l #3,d0
.store:
 move.w d0,-$2(a5)
.translate:
 move.w -$1c8(a5),d0
 add.w d0,-$2(a5)
 move.l -$1994(a4),a0
 move.w -$2(a5),(a0)
 move.b #$7f,5(a0)
 rts

bookkeeping_code_end:
