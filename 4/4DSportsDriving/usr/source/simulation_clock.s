; Independent display-field clock. Initially enabled only by SIM_PROBE;
; production simulation scheduling is connected after its input/state gates.
; Exec owns the interrupt chain. The handler never calls game/OS routines,
; reads controls, or runs physics, and returns Z set to continue the chain.

sim_clock_install:
 movem.l d0-d1/a0-a1/a6,-(sp)
 lea sim_clock_installed(pc),a0
 tst.w (a0)
 bne .done
 lea sim_clock_node(pc),a1
 move.b #2,8(a1)            ; NT_INTERRUPT
 move.b #-60,9(a1)          ; run after the regular graphics service
 lea sim_clock_name(pc),a0
 move.l a0,10(a1)
 lea sim_clock_fields(pc),a0
 move.l a0,14(a1)           ; is_Data, provided in A1 at dispatch
 lea sim_clock_interrupt(pc),a0
 move.l a0,18(a1)           ; is_Code
 moveq #5,d0               ; INTB_VERTB
 move.l (4).w,a6
 jsr _LVOAddIntServer(a6)
 lea sim_clock_installed(pc),a0
 move.w #1,(a0)
.done:
 movem.l (sp)+,d0-d1/a0-a1/a6
 rts

sim_clock_remove:
 movem.l d0-d1/a0-a1/a6,-(sp)
 lea sim_clock_installed(pc),a0
 tst.w (a0)
 beq .done
 clr.w (a0)
 lea sim_clock_node(pc),a1
 moveq #5,d0
 move.l (4).w,a6
 jsr _LVORemIntServer(a6)
.done:
 movem.l (sp)+,d0-d1/a0-a1/a6
 rts

sim_clock_interrupt:
 addq.l #1,(a1)
 moveq #0,d0
 rts

 even
 dc.b "4DCLKVBL"
 dc.w 1,50                 ; format, current PAL validation target
sim_clock_fields: dc.l 0
sim_clock_installed: dc.w 0
sim_clock_node: dcb.b 22,0  ; struct Interrupt (node/data/code)
sim_clock_name: dc.b "4D simulation clock",0
 even
