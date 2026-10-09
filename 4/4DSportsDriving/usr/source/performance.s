; Optional rendering changes. All game hooks are absent with CUSTOM2 bit 0 off.
; The original game remains the reference for every replacement.
 IFND PERF_MASK
PERF_MASK = 1
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
 rts

perf_patch:
 move.l _custom2(pc),d0
 btst #0,d0
 beq.s .done
 move.l perf_game(pc),a1
 lea pl_perf(pc),a0
 move.l _resload(pc),a2
 jsr resload_Patch(a2)
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
 PL_END

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
 move.l (sp)+,a0
 rts
 IFD VERIFY
.queue_failure:
 lea perf_failure(pc),a0
 move.l #1,(a0)
 illegal
 bra.s .queue_failure
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
