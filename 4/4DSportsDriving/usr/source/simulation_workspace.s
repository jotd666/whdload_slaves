; WHDLoad slaves are one position-independent hunk: keep large zero-filled
; work areas in a cleared KickEmu allocation, not in the on-disk slave.
; FASTMEMSIZE (or CHIPMEMSIZE in CHIP_ONLY) includes this reserve. Allocation
; precedes DOS/game startup, so the original game pool remains available.
; WHDLoad owns the enclosing ExpMem/BaseMem and releases it on every exit.
sim_workspace_init:
 movem.l d0-d2/a0-a2/a6,-(sp)
 move.l 4.w,a6
 move.l #SIM_WORKSPACE_RESERVE,d0
 IFD CHIP_ONLY
 move.l #MEMF_CHIP|MEMF_CLEAR,d1
 ELSE
 move.l #MEMF_FAST|MEMF_CLEAR,d1
 ENDC
 jsr _LVOAllocMem(a6)
 tst.l d0
 beq .failed
 movea.l d0,a1
 lea sim_workspace_base(pc),a0
 move.l a1,(a0)
 IFD SIM_SCHEDULE
 lea sim_schedule_queue(pc),a0
 move.l a1,(a0)
 adda.l #SIM_QUEUE_COUNT*SIM_QUEUE_SIZE,a1
 ENDC
 IFD SIM_A4000
 lea sim_workspace_init(pc),a0
 adda.l #sim_history_inputs-sim_workspace_init,a0
 move.l a1,(a0)
 adda.l #30000,a1
 lea sim_workspace_init(pc),a0
 adda.l #sim_history_records-sim_workspace_init,a0
 move.l a1,(a0)
 adda.l #SIM_HISTORY_SLOTS*SIM_HISTORY_BYTES,a1
 IFD SIM_REPLAY_MENU
 lea sim_workspace_init(pc),a0
 adda.l #sim_replay_pending_file-sim_workspace_init,a0
 move.l a1,(a0)
 adda.l #(SIM_REPLAY_BYTES+5)&-4,a1
 lea sim_workspace_init(pc),a0
 adda.l #sim_replay_save_readback-sim_workspace_init,a0
 move.l a1,(a0)
 adda.l #(SIM_REPLAY_BYTES+5)&-4,a1
 ENDC
 ENDC
 sub.l d0,a1
 cmpa.l #SIM_WORKSPACE_RESERVE,a1
 bhi .failed
 movem.l (sp)+,d0-d2/a0-a2/a6
 rts
.failed:
 pea sim_workspace_error(pc)
 pea TDREASON_FAILMSG
 move.l _resload(pc),a0
 jmp resload_Abort(a0)
sim_workspace_base: dc.l 0
sim_workspace_error:
 dc.b "Not enough memory for simulation/replay workspace.",0
 even
