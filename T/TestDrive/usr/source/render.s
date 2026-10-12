; CUSTOM2: preserve blitter bus priority (DMACON BLTPRI) and suppress
; graphics.library's unused blitter-finished interrupt while TD runs.
; Ported from TD2 render.s; TD's existing root:$434/$444 fixes already enable
; priority during gameplay. The measured additional gain is IRQ suppression.
; Shape blits poll BBUSY at root:$D44; waits and ownership are unchanged.
; Preserves the game entry's registers; restore puts back the original enables.
render_interrupt_option:
    movem.l d0/a0,-(sp)
    move.l sim_enabled(pc),d0
    tst.l d0
    beq.b .done
    IFD VERIFY
    move.l verify_c1(pc),d0
    btst #3,d0               ; measurement control: keep phase-8 simulation
    bne.b .done
    ENDC
    lea render_active(pc),a0
    move.w #1,(a0)
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
    move.w render_active(pc),d0
    tst.w d0
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

render_active: dc.w 0
