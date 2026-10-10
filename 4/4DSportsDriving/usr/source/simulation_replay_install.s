; Install a validated checkpoint set AFTER native replay resource/rate setup.
; Caller must have loaded the packet's car/track assets and active rate50,
; hold modal clock ownership, and seek before any further simulation/render.
; A0 tagged packet,D0 length,A4 game -> D0=0 installed,1 format,2 wrong rate.
; No state changes on rejection; all other registers preserved.
sim_replay_install:
 movem.l d1-d7/a0-a6,-(sp)
 cmp.w #50,-$15fa(a4)
 bne .rate
 bsr sim_replay_validate
 cmp.w #50,d0
 bne .bad
 movea.l a0,a5
 suba.w #24,sp
 move.l -$177c(a4),(sp)
 move.l -$1770(a4),4(sp)
 move.l -$16bc(a4),8(sp)
 lea sim_replay_install(pc),a1
 adda.l #sim_history_records-sim_replay_install,a1
 move.l a1,12(sp)
 lea 20(sp),a1
 move.l a1,16(sp)
 movea.l sp,a1
 move.l #SIM_REPLAY_BYTES,d0
 bsr sim_replay_unpack
 ; Same immutable validated packet, so unpack cannot reject here.
 tst.l d0
 bne .unpack_error
 move.w 22(sp),-$2e0(a4)
 adda.w #24,sp
 lea SIM_REPLAY_HEADER(a5),a0
 lea -$1750(a4),a1
 moveq #25,d0
 bsr sim_replay_copy
 ; Force the next native seek to restore even when requesting tick zero.
 move.w #-1,-$940(a4)
 moveq #0,d0
 bra .out
.unpack_error:
 adda.w #24,sp
.bad:
 moveq #1,d0
 bra .out
.rate:
 moveq #2,d0
.out:
 movem.l (sp)+,d1-d7/a0-a6
 rts
