; Bounded background twin: full and clipped restore for each gauge/page.
; Shared reserved 80k workspace is only borrowed during this synchronous call.
; Candidate/native see identical incoming pixels. Native result is retained.
gauge_fast_twin_begin:
 movem.l d0-d2/a0-a2,-(sp)
 lea gauge_fast_twin_active(pc),a0
 clr.w (a0)
 move.w d4,d0
 add.w d0,d0
 moveq #0,d1
 move.b -$ee3(a4),d1
 cmpi.w #1,d1
 bhi .done
 add.w d1,d0
 tst.w d7
 bne .full
 tst.b -$ee4(a4)
 bne .full
 addi.w #14,d0 ; separately exercise clipped previous-needle restores
.full
 lea gauge_fast_twin_checked(pc),a1
 move.l (a1),d1
 btst d0,d1
 bne .done
 move.w d0,(a0)
 addq.w #1,(a0)
 lea .workspace(pc),a0
.workspace
 adda.l #memory_workspace_reserved-.workspace,a0
 move.l (a0),a1
 adda.l #PERF_ARTWORK_TWIN_OFFSET,a1
 lea gauge_fast_twin_buffer(pc),a0
 move.l a1,(a0)
 move.l $1d72(a4),a0
 move.w #9999,d0
.copy
 move.l (a0)+,(a1)+
 dbf d0,.copy
.done
 movem.l (sp)+,d0-d2/a0-a2
 rts

gauge_fast_twin_end:
 movem.l d0-a6,-(sp)
 move.w gauge_fast_twin_active(pc),d0
 beq .done
 move.l gauge_fast_twin_buffer(pc),a0
 move.l a0,a1
 adda.l #40000,a1
 move.l $1d72(a4),a2
 move.w #9999,d0
.swap
 move.l (a2),(a1)+
 move.l (a0)+,(a2)+
 dbf d0,.swap
 ; Invoke precisely the displaced bitmap operation, no world replay.
 move.l d6,d0
 move.l d5,d1
 moveq #0,d2
 ; Original a2 was saved by the outer hook; this routine's stack also holds it.
 move.l 40(sp),a0
 bsr gauge_fast_native
 bsr overlay_blit_wait
 move.l gauge_fast_twin_buffer(pc),a0
 adda.l #40000,a0
 move.l $1d72(a4),a1
 move.w #39999,d0
.compare
 cmpm.b (a0)+,(a1)+
 bne .bad
 dbf d0,.compare
 move.w gauge_fast_twin_active(pc),d0
 subq.w #1,d0
 lea gauge_fast_twin_checked(pc),a0
 move.l (a0),d1
 bset d0,d1
 move.l d1,(a0)
 addq.l #1,4(a0)
 lea gauge_fast_twin_active(pc),a0
 clr.w (a0)
.done
 movem.l (sp)+,d0-a6
 rts
.bad
 lea gauge_fast_twin_failure(pc),a0
 move.l d4,(a0)
 move.w d0,4(a0)
 pea .message(pc)
 pea TDREASON_FAILMSG
 lea .resload(pc),a2
.resload
 adda.l #_resload-.resload,a2
 move.l (a2),a2
 jmp resload_Abort(a2)
.message: dc.b "Red Baron: gauge background pixel mismatch",0
 even
gauge_fast_twin_buffer: dc.l 0
gauge_fast_twin_active: dc.w 0
gauge_fast_twin_checked: dc.l 0,0
gauge_fast_twin_failure: dc.l 0,0
gauge_fast_draws: dc.l 0
