; Optional rendering changes. All game hooks are absent with CUSTOM2 bit 0 off.
; The original game remains the reference for every replacement.
; PERF_MASK test-build bits: 1=BLIT IRQ, 2=vertices, 4=emit, 8=backface,
; 16=parent rotation, 32=state clear, 64=primitive depth/header,
; 128=owned primitive blitter priority, 256=68020 rectangle stores.
; All validated paths are selected; state clear is additionally 68000-only.
 IFND PERF_MASK
PERF_MASK = 511
 ENDC

perf_init:
 movem.l d0/a0,-(sp)
 move.l d7,d0
 addq.l #4,d0
 lea perf_game(pc),a0
 move.l d0,(a0)
 add.l #$a9e6,d0
 lea perf_reset+2(pc),a0
 move.l d0,(a0)
 movem.l (sp)+,d0/a0
 bsr perf_geometry_init
 bsr perf_math_init
 bsr perf_bookkeeping_init
 IFD P3_RASTER
 bsr raster_init
 ENDC
 rts

perf_patch:
 IFD P3_RASTER
 bsr raster_patch
 ENDC
 move.l _custom2(pc),d0
 btst #0,d0
 beq.s .done
 move.l perf_game(pc),a1
 lea pl_perf(pc),a0
 move.l _resload(pc),a2
 IFNE PERF_MASK&256
 bsr.w perf_patch_rect
 ELSE
 jsr resload_Patch(a2)
 ENDC
 IFNE PERF_MASK&32
 ; The longword clear only wins on the measured 68000. Faster CPUs keep
 ; the original byte loop, including its flags and registers.
 move.l perf_attnflags(pc),d0
 btst #0,d0 ; AFB_68010: set for 68010 and later processors
 bne.s .done
 move.l perf_game(pc),a1
 lea pl_perf_clear(pc),a0
 move.l _resload(pc),a2
 jsr resload_Patch(a2)
 ENDC
.done:
 rts

pl_perf:
 PL_START
 IFNE PERF_MASK&1
 PL_PS $0ab86,perf_draw_enter ; PERF_RANGE h0:0ab86 6 bit=0
 PL_P  $0aed0,perf_draw_exit ; PERF_RANGE h0:0aed0 6 bit=0
 PL_P $3980e,perf_own_blitter ; PERF_RANGE h0:3980e 6 bit=0
 PL_P $39800,perf_disown_blitter ; PERF_RANGE h0:39800 6 bit=0
 ENDC
 IFNE PERF_MASK&2
 PL_P $1440,perf_vertices ; PERF_RANGE h0:01440 6 bit=0
 ENDC
 IFNE PERF_MASK&4
 PL_P $1662,perf_emit ; PERF_RANGE h0:01662 6 bit=0
 ENDC
 IFNE PERF_MASK&8
 IFD PERF_TWIN
 PL_P $aad4,math_twin_backface ; PERF_RANGE h0:0aad4 6 bit=0
 ELSE
 PL_P $aad4,perf_backface_body ; PERF_RANGE h0:0aad4 6 bit=0
 ENDC
 PL_NOP $aada,2 ; PERF_RANGE h0:0aada 2 bit=0
 ENDC
 IFNE PERF_MASK&16
 IFD PERF_TWIN
 PL_P $a756,math_twin_parent ; PERF_RANGE h0:0a756 6 bit=0
 ELSE
 PL_P $a756,perf_parent_body ; PERF_RANGE h0:0a756 6 bit=0
 ENDC
 PL_NOP $a75c,2 ; PERF_RANGE h0:0a75c 2 bit=0
 ENDC
 IFNE PERF_MASK&64
 PL_P $20c8,perf_epilogue ; PERF_RANGE h0:020c8 6 bit=0
 PL_NOP $20ce,2 ; PERF_RANGE h0:020ce 2 bit=0
 ENDC
 PL_END

 IFNE PERF_MASK&32
pl_perf_clear:
 PL_START
 IFD PERF_TWIN
 PL_PS $fc6,book_twin_clear ; PERF_RANGE h0:00fc6 6 bit=0
 ELSE
 PL_PS $fc6,perf_clear_body ; PERF_RANGE h0:00fc6 6 bit=0
 ENDC
 PL_END
 ENDC

 ; Restrict suppression to owned blitter intervals inside primitive drawing.
perf_draw_enter:
 move.l a0,-(sp)
 lea perf_draw_active(pc),a0
 move.w #1,(a0)
 move.l (sp)+,a0
 move.w #$12c,-4(a5)
 rts
perf_draw_exit:
 move.l a0,-(sp)
 lea perf_draw_active(pc),a0
 clr.w (a0)
 move.l (sp)+,a0
 bsr perf_reset
 unlk a5
 rts

perf_own_blitter:
 jsr -456(a6)
 bsr.s perf_blit_off
 move.l (sp)+,a6 ; displaced original pop; PL_P adds no return address
 rts
perf_disown_blitter:
 bsr perf_blit_on
 jsr -462(a6)
 move.l (sp)+,a6
 rts

; Keep the original enable state and skip queued/pending work. The caller has
; acquired OwnBlitter; interrupts are restored before it calls DisownBlitter.
perf_blit_off:
 movem.l d0/a0-a1,-(sp)
 lea perf_blit_active(pc),a0
 clr.w (a0)
 move.w perf_draw_active(pc),d0
 beq.s .done
 IFNE PERF_MASK&128
 ; OwnBlitter has returned and this is an owned primitive-drawing interval.
 ; Save the original priority so DisownBlitter restores the exact state.
 move.w $dff002,d0
 and.w #$400,d0
 lea perf_priority_saved(pc),a1
 move.w d0,(a1)+
 move.w #1,(a1)
 move.w #$8400,$dff096
 ENDC
 move.w $dff01c,d0
 and.w #$40,d0
 beq.s .done
 btst #6,$dff01f
 bne.s .done
 btst #6,$dff002
 bne.s .done
 tst.l $3a(a6)
 bne.s .done
 tst.w $a2(a6)
 bne.s .done
 move.w #$40,$dff09a
 move.w #1,(a0)
 IFD VERIFY
 lea perf_blit_windows(pc),a0
 move.l (a0),a1
 addq.l #1,a1
 move.l a1,(a0)
 ENDC
.done:
 movem.l (sp)+,d0/a0-a1
 rts

perf_blit_on:
 move.l a0,-(sp)
 lea perf_blit_active(pc),a0
 tst.w (a0)
 beq.s .done
 IFD VERIFY
 tst.l $3a(a6)
 bne.s .queue_failure
 tst.w $a2(a6)
 bne.s .queue_failure
 ENDC
 tst.b $dff002
.wait:
 btst #6,$dff002
 bne.s .wait
 move.w #$40,$dff09c
 move.w #$8040,$dff09a
 clr.w (a0)
.done:
 IFNE PERF_MASK&128
 lea perf_priority_active(pc),a0
 tst.w (a0)
 beq.s .priority_done
 clr.w (a0)
 tst.w -2(a0)
 bne.s .priority_done
 move.w #$0400,$dff096
.priority_done:
 ENDC
 move.l (sp)+,a0
 rts
 IFD VERIFY
.queue_failure:
 lea perf_failure(pc),a0
 move.l #1,(a0)
 illegal
 bra.s .queue_failure
 ENDC
 IFNE PERF_MASK&128
perf_priority_saved: dc.w 0
perf_priority_active: dc.w 0
 ENDC
perf_reset:
 jmp $0.l ; relocated to the unchanged game:$a9e6 at patch time

 CNOP 0,4
 dc.b "4DPERF!!"
perf_game: dc.l 0
perf_blit_active: dc.w 0
perf_draw_active: dc.w 0
 IFD VERIFY
perf_failure: dc.l 0
perf_blit_windows: dc.l 0
 ENDC

 include "geometry.s"
 IFD PERF_TWIN
 include "geometry_verify.s"
 ENDC

 include "math.s"
 IFD PERF_TWIN
 include "math_verify.s"
 ENDC

 include "bookkeeping.s"
 IFD PERF_TWIN
 include "bookkeeping_verify.s"
 ENDC

 IFNE PERF_MASK&256
; Append the 020-only path after existing code: preserve the established hot
; routine offsets and their instruction-cache placement on other machines.
perf_patch_rect:
 jsr resload_Patch(a2)
 move.l perf_attnflags(pc),d0
 btst #1,d0 ; AFB_68020: measured win on 020, regression on 040
 beq.s .no_cpu_rect
 btst #2,d0 ; AFB_68030: leave 030 and later on the native blitter
 bne.s .no_cpu_rect
 move.l perf_game(pc),a1
 lea pl_perf_cpu_rect(pc),a0
 move.l _resload(pc),a2
 jsr resload_Patch(a2)
.no_cpu_rect:
 rts
 ENDC
 IFNE PERF_MASK&256
pl_perf_cpu_rect:
 PL_START
 PL_PSS $347b0,perf_cpu_rect,34 ; PERF_RANGE h0:347b0 40 bit=0
 PL_END
; Replaces only the selected D-only rectangle plane. All preceding clipping,
; plane selection and following loop control remain native. Wait before CPU
; access because a preceding plane/primitive can still own the chip bitmap.
perf_cpu_rect:
 adda.w d1,a0
 movem.l d0-d4/a0,-(sp)
 moveq #0,d4
 addx.b d4,d4 ; save the incoming X bit without reading privileged SR
 move.w d4,-(sp)
 tst.b $dff002
.wait:
 btst #6,$dff002
 bne.s .wait
 moveq #0,d4
 tst.b d2
 beq.s .value_ready
 moveq #-1,d4
.value_ready:
 move.w d3,d1
 and.w #63,d1
 bne.s .width_ready
 moveq #64,d1
.width_ready:
 move.w d3,d2
 lsr.w #6,d2
 bne.s .height_ready
 move.w #1024,d2
.height_ready:
 subq.w #1,d2
.row:
 move.w d1,d3
 lsr.w #1,d3
 subq.w #1,d3
 bmi.s .tail
.longs:
 move.l d4,(a0)+
 dbra d3,.longs
.tail:
 btst #0,d1
 beq.s .next
 move.w d4,(a0)+
.next:
 adda.w d0,a0
 dbra d2,.row
 move.w (sp)+,d4
 lsr.w #1,d4 ; restore X, then the original final MOVE.W condition codes
 movem.l (sp)+,d0-d4/a0
 tst.w d3
 rts
 ENDC

 IFD P3_RASTER
 include "raster.s"
 ENDC
