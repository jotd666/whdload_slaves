; Physics selection persists independently of native game/replay data.
; Sixteen bytes: "4DPHYS50", version.w=1, rate.w=10/20/50, IEEE CRC32.l
; over the first 12 bytes. A bounded read rejects both short and oversized files.

; A0 buffer, D0 byte count -> D0 rate, or 0 invalid. Preserve other registers.
sim_preferences_decode:
 movem.l d1/a0,-(sp)
 cmp.l #16,d0
 bne .bad
 cmp.l #$34445048,(a0)
 bne .bad
 cmp.l #$59533530,4(a0)
 bne .bad
 cmp.w #1,8(a0)
 bne .bad
 moveq #12,d0
 bsr sim_score_crc32
 cmp.l 12(a0),d0
 bne .bad
 moveq #0,d0
 move.w 10(a0),d0
 cmp.w #10,d0
 beq .out
 cmp.w #20,d0
 beq .out
 cmp.w #50,d0
 beq .out
.bad:
 moveq #0,d0
.out:
 movem.l (sp)+,d1/a0
 rts

; A6 DOS -> D0 validated rate or 0, D1=0 missing,1 loaded,2 rejected/error.
; Reuse the private buffer; main-task startup/menu use only.
sim_preferences_read:
 movem.l d2-d5/a0-a1,-(sp)
 lea sim_preferences_name(pc),a0
 move.l a0,d1
 move.l #1005,d2
 jsr _LVOOpen(a6)
 move.l d0,d4
 beq .open_failed
 move.l d4,d1
 lea sim_preferences_buffer(pc),a0
 move.l a0,d2
 moveq #17,d3
 jsr _LVORead(a6)
 move.l d0,d5
 move.l d4,d1
 jsr _LVOClose(a6)
 move.l d5,d0
 lea sim_preferences_buffer(pc),a0
 bsr sim_preferences_decode
 tst.l d0
 beq .failed
 moveq #1,d1
 bra .out
.open_failed:
 jsr _LVOIoErr(a6)
 cmp.l #205,d0
 bne .failed
 moveq #0,d1
 moveq #0,d0
 bra .out
.failed:
 moveq #2,d1
 moveq #0,d0
.out:
 movem.l (sp)+,d2-d5/a0-a1
 rts

; $16C9E: after the native benchmark, before copying selected to active mode.
; Missing/invalid files preserve the benchmark result; loading never writes.
sim_preferences_load:
 movem.l d0-d7/a0-a6,-(sp)
 movea.l $bda(a4),a6
 bsr sim_preferences_read
 lea sim_preferences_status(pc),a0
 move.l d1,(a0)
 lea sim_preferences_loads(pc),a0
 addq.l #1,(a0)
 tst.l d0
 beq .out
 cmp.w #20,d0
 bne .apply
 tst.w -$4628(a4)
 beq .apply
 lea sim_preferences_status(pc),a0
 move.l #4,(a0)             ; valid A2500 choice, blocked by native benchmark
 bra .out
.apply:
 move.w d0,-$bc(a4)
 lea sim_preferences_loaded(pc),a0
 move.w d0,(a0)
.out:
 movem.l (sp)+,d0-d7/a0-a6
 move.w -$bc(a4),-$15fa(a4) ; displaced assignment, including flags
 rts

; Save selected rate when leaving a changed simulation dialog. D0=0 verified,
; 1 failure. Preserve all other registers. No active/race-mode mutation here.
sim_preferences_save:
 movem.l d1-d7/a0-a6,-(sp)
 moveq #0,d7
 move.w -$bc(a4),d7
 cmp.w #10,d7
 beq .encode
 cmp.w #20,d7
 beq .encode
 cmp.w #50,d7
 bne .failed
.encode:
 lea sim_preferences_buffer(pc),a0
 move.l #$34445048,(a0)
 move.l #$59533530,4(a0)
 move.w #1,8(a0)
 move.w d7,10(a0)
 moveq #12,d0
 bsr sim_score_crc32
 move.l d0,12(a0)
 movea.l $bda(a4),a6
 lea sim_preferences_name(pc),a0
 move.l a0,d1
 move.l #1006,d2
 jsr _LVOOpen(a6)
 move.l d0,d4
 beq .failed
 move.l d4,d1
 lea sim_preferences_buffer(pc),a0
 move.l a0,d2
 moveq #16,d3
 jsr _LVOWrite(a6)
 move.l d0,d5
 move.l d4,d1
 jsr _LVOClose(a6)           ; V1.3 Close has no defined return status
 cmp.l #16,d5
 bne .failed
 bsr sim_preferences_read
 cmp.l #1,d1
 bne .failed
 cmp.l d7,d0
 bne .failed
 lea sim_preferences_status(pc),a0
 move.l #1,(a0)
 lea sim_preferences_saves(pc),a0
 addq.l #1,(a0)
 moveq #0,d0
 bra .out
.failed:
 lea sim_preferences_status(pc),a0
 move.l #3,(a0)
 moveq #1,d0
.out:
 movem.l (sp)+,d1-d7/a0-a6
 rts
 even
 dc.b "4DPREFS!"
 dc.w 1,16
sim_preferences_status: dc.l 0 ; 0 missing,1 valid,2 read error,3 save error,4 gated
sim_preferences_loads: dc.l 0
sim_preferences_saves: dc.l 0
sim_preferences_loaded: dc.w 0
sim_preferences_guard_before: dc.l $50524546
sim_preferences_buffer: dcb.b 18,0
sim_preferences_guard_after: dc.l $454e4421
sim_preferences_name: dc.b "4DPhysics.cfg",0
 even
