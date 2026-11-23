; Bounded replay DOS I/O. Main-task callers must hold modal clock ownership.
; Caller-owned staging/readback buffers are SIM_REPLAY_BYTES+2 bytes, aligned.
; These helpers never install replay state and never call the unbounded loader.

; A0 filename,A1 staging,A6 DOS -> D0 status (0 valid,1 open,2 read/format),
; D1 rate10/20/50 and D2 exact byte count on success; both zero on failure.
; Other registers preserved. Staging is scratch and may change on rejection.
sim_replay_file_read:
 movem.l d3-d7/a0-a6,-(sp)
 movea.l a1,a3
 move.l a0,d1
 move.l #1005,d2
 jsr _LVOOpen(a6)
 move.l d0,d4
 beq .open_error
 move.l d4,d1
 move.l a3,d2
 move.l #SIM_REPLAY_BYTES+1,d3
 jsr _LVORead(a6)
 move.l d0,d5
 move.l d4,d1
 jsr _LVOClose(a6)         ; Kickstart1.3 Close has no defined return value
 tst.l d5
 ble .invalid
 movea.l a3,a0
 move.l d5,d0
 bsr sim_replay_validate
 tst.l d0
 beq .invalid
 move.l d0,d1
 move.l d5,d2
 moveq #0,d0
 bra .out
.open_error:
 moveq #1,d0
 bra .error
.invalid:
 moveq #2,d0
.error:
 moveq #0,d1
 moveq #0,d2
.out:
 movem.l (sp)+,d3-d7/a0-a6
 rts

; A0 filename,A1 packet,D0 length,A2 readback scratch,A6 DOS.
; D0=0 verified,1 invalid input,2 open,3 short/failed write,4 readback failure.
; All other registers preserved. Packet/scratch must not alias each other or
; filename. Validate before opening/truncating. Direct replacement write;
; callers must surface failure, and must not claim the old file was retained.
sim_replay_file_write:
 movem.l d1-d7/a0-a6,-(sp)
 movea.l a0,a5
 movea.l a1,a4
 movea.l a2,a3
 move.l d0,d7
 movea.l a4,a0
 bsr sim_replay_validate
 tst.l d0
 beq .invalid
 move.l d0,d6
 move.l a5,d1
 move.l #1006,d2
 jsr _LVOOpen(a6)
 move.l d0,d4
 beq .open_error
 move.l d4,d1
 move.l a4,d2
 move.l d7,d3
 jsr _LVOWrite(a6)
 move.l d0,d5
 move.l d4,d1
 jsr _LVOClose(a6)
 cmp.l d7,d5
 bne .write_error
 movea.l a5,a0
 movea.l a3,a1
 bsr sim_replay_file_read
 tst.l d0
 bne .readback_error
 cmp.l d6,d1
 bne .readback_error
 cmp.l d7,d2
 bne .readback_error
 movea.l a4,a0
 movea.l a3,a1
 move.l d7,d0
 subq.w #1,d0
.compare:
 move.b (a0)+,d1
 cmp.b (a1)+,d1
 bne .readback_error
 dbra d0,.compare
 moveq #0,d0
 bra .out
.invalid:
 moveq #1,d0
 bra .out
.open_error:
 moveq #2,d0
 bra .out
.write_error:
 moveq #3,d0
 bra .out
.readback_error:
 moveq #4,d0
.out:
 movem.l (sp)+,d1-d7/a0-a6
 rts
