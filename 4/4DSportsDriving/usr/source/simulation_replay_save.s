; The two replay save call sites retain their native dialogs and return ABI.
; The generic chooser also serves other file types: only the replay backing
; pointer selects this writer. No global DOS or generic writer interception.
sim_replay_save_direct:
 bsr sim_replay_save_dispatch
 move.w d0,-2(a5)        ; displaced native result store
 rts
sim_replay_save_dialog:
 bsr sim_replay_save_dispatch
 move.w d0,-4(a5)        ; displaced native result store
 rts

; Stack: own return, hook return, filename, data, native length.
sim_replay_save_dispatch:
 link a5,#0
 movem.l d1-d7/a0-a6,-(sp)
 movea.l 16(a5),a0
 cmpa.l -$177c(a4),a0
 beq .replay
 ; Other chooser payloads retain the original writer and its exact arguments.
 move.l 20(a5),-(sp)
 move.l 16(a5),-(sp)
 move.l 12(a5),-(sp)
 jsr -$7ae8(a4)
 lea 12(sp),sp
 bra .out
.replay:
 lea sim_replay_save_dispatch(pc),a3
 adda.l #sim_schedule_modal-sim_replay_save_dispatch,a3
 move.w (a3),-(sp)
 move.w #1,(a3)
 lea sim_replay_save_dispatch(pc),a0
 adda.l #sim_replay_pending-sim_replay_save_dispatch,a0
 clr.w (a0)             ; output reuses staging; never retain a pending load
 lea sim_replay_save_dispatch(pc),a2
 adda.l #sim_replay_pending_file-sim_replay_save_dispatch,a2
 moveq #0,d7
 move.b -$173a(a4),d7
 cmp.w #50,d7
 beq .tagged
 cmp.w #10,d7
 beq .native
 cmp.w #20,d7
 bne .invalid
.native:
 moveq #0,d6
 move.w -$1738(a4),d6
 mulu #600,d7
 cmp.l d7,d6
 bhi .invalid
 lea -$1750(a4),a0
 movea.l a2,a1
 moveq #25,d0
 bsr sim_replay_copy
 movea.l -$1778(a4),a0
 move.w #1801,d0
 bsr sim_replay_copy
 tst.l d6
 beq .native_ready
 movea.l -$1770(a4),a0
 move.l d6,d0
 subq.w #1,d0
 bsr sim_replay_copy
.native_ready:
 add.l #SIM_REPLAY_PREFIX,d6
 bra .write
.tagged:
 movea.l a2,a0
 bsr sim_replay_pack
 tst.l d0
 bne .invalid
 move.l #SIM_REPLAY_BYTES,d6
.write:
 movea.l 12(a5),a0
 movea.l a2,a1
 lea sim_replay_save_dispatch(pc),a2
 adda.l #sim_replay_save_readback-sim_replay_save_dispatch,a2
 move.l d6,d0
 movea.l $bda(a4),a6
 bsr sim_replay_file_write
 bra .status
.invalid:
 moveq #1,d0
.status:
 lea sim_replay_save_dispatch(pc),a0
 adda.l #sim_replay_save_marker-sim_replay_save_dispatch,a0
 addq.l #1,12(a0)
 move.l d0,16(a0)
 move.w (sp)+,(a3)
.out:
 movem.l (sp)+,d1-d7/a0-a6
 unlk a5
 rts
 even
sim_replay_save_marker:
 dc.b "4DRPLSAV"
 dc.w 1,0
 dc.l 0,-1
