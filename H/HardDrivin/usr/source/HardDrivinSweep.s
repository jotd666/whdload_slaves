; Experimental long-frame object sweep. Native contacts retain priority.
; Scene-list coverage, rotating contacts and extreme travel remain acceptance work.
_sweep_install:
 movem.l d0/a0-a2,-(a7)
 lea _sweep_loop_ptr(pc),a0
 move.l _code_start(pc),d0
 addi.l #$bb4c,d0
 move.l d0,(a0)+
 move.l _code_start(pc),d0
 addi.l #$bd14,d0
 move.l d0,(a0)+
 move.l _code_start(pc),d0
 addi.l #$bc0c,d0
 move.l d0,(a0)
 lea _sweep_patches(pc),a0
 movea.l _code_start(pc),a1
 movea.l _resload(pc),a2
 jsr resload_Patch(a2)
 movem.l (a7)+,d0/a0-a2
 rts
_sweep_patches:
 PL_START
 ; PERF_RANGE VERIFY_TIME_SWEEP $0bd0e $0006: test missed objects against movement segment
 PL_P $bd0e,_sweep_miss
 ; PERF_RANGE VERIFY_TIME_SWEEP $0bd14 $0006: resolve earliest additional object contact
 PL_PS $bd14,_sweep_finish
 PL_END
_sweep_loop_ptr: dc.l 0
_sweep_finish_ptr: dc.l 0
_sweep_hit_ptr: dc.l 0
SW_START equ 0
SW_DELTA equ 12
SW_BOX equ 18
SW_BEST equ 42
SW_NUM equ 46
SW_DEN equ 48
SW_ACTIVE equ 50
SW_READY equ 52
SW_TESTS equ 54
SW_HITS equ 58
SW_OVERFLOW equ 62
 dc.b 'HDSWEEP1'
_sweep_state: dcb.b 66,0
; Called after recovery and before camera/scene setup for each physics pass.
; MOVE/CLR/CMP do not change X; all caller registers are preserved.
_sweep_begin:
 movem.l d0/a0,-(a7)
 lea _sweep_state(pc),a0
 clr.w SW_ACTIVE(a0)
 clr.w SW_READY(a0)
 clr.l SW_BEST(a0)
 IFND VERIFY_DISPATCH_NATIVE
 move.b _dispatch_state+DS_ACTIVE(pc),d0
 tst.b d0
 beq.s .done
 tst.b -$69fa(a4)
 bne.s .done
 move.w _time_scalar_fields(pc),d0
 cmpi.w #8,d0
 bls.s .done
 move.l -$6704(a4),SW_START(a0)
 move.l -$6700(a4),SW_START+4(a0)
 move.l -$66fc(a4),SW_START+8(a0)
 move.w #1,SW_ACTIVE(a0)
 ENDC
.done:
 movem.l (a7)+,d0/a0
 rts
_sweep_miss:
 ; Native BB48 enters the tail once before loading an object into A3.
 cmp.w -$4e70(a4),d4
 bhi.s .tail
 movem.l d0-d7/a0-a2/a6,-(a7)
 bsr _sweep_consider
 movem.l (a7)+,d0-d7/a0-a2/a6
.tail:
 ; Original loop tail: SUBQ determines X, independent of helper arithmetic.
 subq.w #1,d4
 beq.s .finished
 move.l _sweep_loop_ptr(pc),-(a7)
 rts
.finished:
 move.l _sweep_finish_ptr(pc),-(a7)
 rts
_sweep_consider:
 lea _sweep_state(pc),a6
 tst.w SW_ACTIVE(a6)
 beq .done
 ; Type95 is sound-only, not a solid collision; retain its native path.
 cmpi.b #8,28(a3)
 bne .done
 cmpi.b #95,25(a3)
 beq .done
 tst.w SW_READY(a6)
 bne.s .ready
 lea -$6704(a4),a0
 lea SW_START(a6),a1
 lea SW_DELTA(a6),a2
 moveq #2,d7
.delta:
 move.l (a0)+,d0
 asr.l #3,d0
 move.l (a1)+,d1
 asr.l #3,d1
 sub.l d1,d0
 move.l d0,d1
 ext.l d1
 cmp.l d0,d1
 bne .overflow
 move.w d0,(a2)+
 dbf d7,.delta
 move.w #1,SW_READY(a6)
.ready:
 addq.l #1,SW_TESTS(a6)
 move.w (a3),d0
 move.w 2(a3),d1
 move.w 4(a3),d2
 bsr _sweep_rotate
 lea SW_BOX(a6),a0
 move.w d0,(a0)
 move.w d1,8(a0)
 move.w d2,16(a0)
 ; Transform the endpoint itself, retaining native nested Q14 rounding.
 lea SW_DELTA(a6),a1
 movea.l a3,a2
 moveq #2,d7
.endpoints:
 move.w (a2)+,d0
 ext.l d0
 move.w (a1)+,d1
 ext.l d1
 sub.l d1,d0
 move.l d0,d1
 ext.l d1
 cmp.l d0,d1
 bne .overflow
 move.w d0,2(a0)
 addq.l #8,a0
 dbf d7,.endpoints
 lea SW_BOX(a6),a0
 move.w 2(a0),d0
 move.w 10(a0),d1
 move.w 18(a0),d2
 bsr _sweep_rotate
 move.w d0,2(a0)
 move.w d1,10(a0)
 move.w d2,18(a0)
 move.w -22(a5),d0
 bmi .overflow
 move.w d0,6(a0)
 neg.w d0
 move.w d0,4(a0)
 move.w -24(a5),d0
 bmi .overflow
 move.w d0,14(a0)
 neg.w d0
 move.w d0,12(a0)
 move.w #3,20(a0)
 move.w -26(a5),d0
 cmpi.w #3,d0
 blt .done
 move.w d0,22(a0)
 bsr _sweep_box
 tst.w d0
 beq.s .done
 tst.l SW_BEST(a6)
 beq.s .remember
 move.l d1,d0
 mulu.w SW_DEN(a6),d0
 moveq #0,d3
 move.w SW_NUM(a6),d3
 mulu.w d2,d3
 cmp.l d3,d0
 bhs.s .done
.remember:
 move.l a3,SW_BEST(a6)
 move.w d1,SW_NUM(a6)
 move.w d2,SW_DEN(a6)
.done:
 rts
.overflow:
 ; Unsupported range is counted, never presented as validated sweep coverage.
 addq.l #1,SW_OVERFLOW(a6)
 clr.w SW_ACTIVE(a6)
 clr.l SW_BEST(a6)
 rts
; Same nested signed-word/Q14 rotation as native BB6E..BBD2.
; D0/D1/D2 words XYZ; D3-D6 scratch. A0..A6 unchanged.
_sweep_rotate:
 move.w d0,d3
 muls.w -$16c4(a4),d0
 move.w d2,d4
 muls.w -$16c6(a4),d4
 sub.l d4,d0
 lsl.l #2,d0
 swap d0
 muls.w -$16c6(a4),d3
 muls.w -$16c4(a4),d2
 add.l d3,d2
 lsl.l #2,d2
 swap d2
 move.w d1,d3
 muls.w -$16c0(a4),d1
 move.w d2,d4
 muls.w -$16c2(a4),d4
 sub.l d4,d1
 lsl.l #2,d1
 swap d1
 muls.w -$16c2(a4),d3
 muls.w -$16c0(a4),d2
 add.l d3,d2
 lsl.l #2,d2
 swap d2
 rts
_sweep_finish:
 movem.l d0-d7/a0-a2/a5-a6,-(a7)
 lea _sweep_state(pc),a6
 tst.l SW_BEST(a6)
 beq.s .native
 bsr _sweep_rewind
 movea.l SW_BEST(a6),a3
 clr.w SW_ACTIVE(a6)
 addq.l #1,SW_HITS(a6)
 movem.l (a7)+,d0-d7/a0-a2/a5-a6
 move.l _sweep_hit_ptr(pc),(a7)
 ; Native object-loop completion leaves X clear (1-1).
 move.l d0,-(a7)
 moveq #0,d0
 lsr.b #1,d0
 move.l (a7)+,d0
 rts
.native:
 movem.l (a7)+,d0-d7/a0-a2/a5-a6
 lea -$50c8(a4),a0
 move.l a0,d5
 rts
_sweep_rewind:
 lea SW_START(a6),a0
 lea -$6704(a4),a1
 lea -$670a(a4),a2
 moveq #2,d7
.axis:
 move.l (a1),d0
 sub.l (a0),d0
 moveq #0,d1
 move.w SW_NUM(a6),d1
 moveq #0,d2
 move.w SW_DEN(a6),d2
 bsr _sweep_scale_delta
 add.l (a0)+,d0
 move.l d0,(a1)+
 asr.l #3,d0
 move.w d0,(a2)+
 dbf d7,.axis
 rts
; D0 signed-long delta, D1 unsigned numerator <= D2 unsigned denominator.
; Exact truncating signed interpolation, using a48-bit product and two DIVUs.
_sweep_scale_delta:
 movem.l d1-d7,-(a7)
 move.l d0,d7
 bpl.s .positive
 neg.l d0
.positive:
 move.w d2,d6
 ; Unsigned32 by unsigned16 to48 bits (including abs(LONG_MIN)).
 move.l d0,d3
 andi.l #$ffff,d3
 mulu.w d1,d3
 swap d0
 mulu.w d1,d0
 move.l d0,d2
 swap d2
 andi.l #$ffff,d2
 swap d0
 clr.w d0
 add.l d3,d0
 moveq #0,d3
 addx.l d3,d2
 move.l d0,d3
 swap d2
 move.l d3,d4
 swap d4
 move.w d4,d2
 divu.w d6,d2
 moveq #0,d5
 move.w d2,d5
 swap d5
 clr.w d2
 move.w d3,d2
 divu.w d6,d2
 move.w d2,d5
 move.l d5,d0
 tst.l d7
 bpl.s .done
 neg.l d0
.done:
 movem.l (a7)+,d1-d7
 rts

_sweep_box:
 movem.l d3-d7/a0-a2,-(a7)
 subq.l #8,a7
 movea.l a7,a1
 clr.w (a1)
 move.w #1,2(a1)
 move.w #1,4(a1)
 move.w #1,6(a1)
 moveq #2,d7
.axis:
 move.w (a0)+,d5
 ext.l d5
 move.w (a0)+,d4
 ext.l d4
 sub.l d5,d4
 move.w (a0)+,d1
 ext.l d1
 sub.l d5,d1
 move.w (a0)+,d3
 ext.l d3
 sub.l d5,d3
 tst.l d4
 beq .parallel
 bpl.s .positive
 neg.l d4
 neg.l d1
 neg.l d3
 exg d1,d3
.positive:
 tst.l d3
 bmi .miss
 cmp.l d4,d1
 bgt .miss
 tst.l d1
 ble.s .exit_bound
 move.l d1,d0
 mulu.w 2(a1),d0
 moveq #0,d6
 move.w (a1),d6
 mulu.w d4,d6
 cmp.l d6,d0
 bls.s .exit_bound
 move.w d1,(a1)
 move.w d4,2(a1)
.exit_bound:
 cmp.l d4,d3
 bge.s .overlap
 move.l d3,d0
 mulu.w 6(a1),d0
 moveq #0,d6
 move.w 4(a1),d6
 mulu.w d4,d6
 cmp.l d6,d0
 bhs.s .overlap
 move.w d3,4(a1)
 move.w d4,6(a1)
.overlap:
 moveq #0,d0
 move.w (a1),d0
 mulu.w 6(a1),d0
 moveq #0,d6
 move.w 4(a1),d6
 mulu.w 2(a1),d6
 cmp.l d6,d0
 bhi.s .miss
 bra.s .next
.parallel:
 tst.l d1
 bgt.s .miss
 tst.l d3
 bmi.s .miss
.next:
 dbf d7,.axis
 moveq #0,d1
 move.w (a1),d1
 moveq #0,d2
 move.w 2(a1),d2
 moveq #1,d0
 bra.s .done
.miss:
 moveq #0,d0
 moveq #0,d1
 moveq #1,d2
.done:
 addq.l #8,a7
 movem.l (a7)+,d3-d7/a0-a2
 rts
