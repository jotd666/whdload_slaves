; The v1 View swap schedules the copper list; it does not retire the old
; bitmap immediately. Defer a racing handoff until the first screen write so
; pure geometry work can overlap the remaining display field (especially 000).
; Other callers wait here. Pause and race-exit paths also drain a pending swap.
; PL_P at $39e inherits the original LINK frame and stacked View argument.
render_swap:
    jsr -32004(a4)
    addq.w #4,sp
    movem.l d0/a0,-(sp)
    lea render_swap_epoch(pc),a0
    move.l -31790(a4),(a0)+   ; native VBL count, advances even while paused
    move.w #1,(a0)          ; render_swap_pending
    move.l render_race_return(pc),d0
    cmp.l 4(a5),d0          ; only a8ee's call may defer the handoff
    movem.l (sp)+,d0/a0
    beq.b .done
    bsr render_wait_pending
.done
    unlk a5
    rts

render_before_road:
    bsr render_wait_pending
    move.w #72,-30606(a4)   ; original $818c: before sky clear / horizon blits
    rts

render_before_pause:
    cmp.w #-1,-31736(a4)
    bne.b .done
    bsr render_wait_pending
.done
    cmp.w #-1,-31736(a4)    ; original $7094, including condition codes
    rts

render_before_exit:
    bsr render_wait_pending
    moveq #0,d0            ; original $75c8..$75ce
    jsr -32400(a4)
    rts

render_wait_pending:
    movem.l d0-d1/a0-a1/a6,-(sp)
    lea render_swap_pending(pc),a0
    tst.w (a0)
    beq.b .done
    clr.w (a0)
    move.l render_swap_epoch(pc),d0
    cmp.l -31790(a4),d0
    bne.b .done            ; a complete VBL already retired the old View
    move.l 3600(a4),a6
    jsr _LVOWaitTOF(a6)
.done
    movem.l (sp)+,d0-d1/a0-a1/a6
    rts

render_race_return: dc.l 0
render_swap_epoch: dc.l 0
render_swap_pending: dc.w 0

render_options: dc.l 0        ; bit 1, set only for supported v1 + CUSTOM2

; v1 enhanced framerate (render_options bit 1): give the blitter bus priority
; (DMACON BLTPRI) and disable graphics.library's unused blitter-finished
; interrupt while the game runs.
; The CPU only polls BBUSY during shape blits, so its DMACONR reads no longer
; take the blitter's slots. Game code, waits and ownership are unchanged.
; Preserves the game entry's registers; restore puts back the original enables.
render_interrupt_option:
    movem.l d0/a0,-(sp)
    move.l render_options(pc),d0
    btst #1,d0
    beq.b .done
    lea render_saved_priority(pc),a0
    move.w $dff002,d0
    and.w #$400,d0
    move.w d0,(a0)+
    move.w $dff01c,d0
    and.w #$40,d0
    move.w d0,(a0)            ; render_saved_irq
    move.w #$8400,$dff096
    move.w #$40,$dff09a
.done
    movem.l (sp)+,d0/a0
    rts
render_interrupt_restore:
    move.l d0,-(sp)
    move.l render_options(pc),d0
    btst #1,d0
    beq.b .done
    move.w render_saved_priority(pc),d0
    bne.b .priority
    move.w #$0400,$dff096
.priority
    move.w render_saved_irq(pc),d0
    beq.b .done
    move.w #$8040,$dff09a
.done
    move.l (sp)+,d0
    rts
render_saved_priority: dc.w 0
render_saved_irq: dc.w 0
