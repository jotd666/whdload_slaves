; Development replay codec; native DOS/menu integration is opt-in.
; All words/longs are big-endian; buffers must be even-aligned and nonaliasing.
; Native files: 26-byte race header, two 901-byte tracks, then input bytes.
; Tagged v2: 36-byte header, native prefix, 30000 input bytes, twenty native
; checkpoints, twenty companions, 1802-byte opponent route + two zero pad bytes,
; CRC32 of all preceding bytes. Invalid slots
; and unused inputs are zeroed. The epoch is separate from native snapshots.
 IFNE SIM_HISTORY_BYTES-392
 FAIL "Replay ABI10 requires392-byte companions; revise the format explicitly"
 ENDC
 IFNE SIM_HISTORY_SLOTS-20
 FAIL "Replay ABI10 requires20 checkpoint slots"
 ENDC
SIM_REPLAY_PREFIX = $724
SIM_REPLAY_INPUTS = 30000
SIM_REPLAY_NATIVE = 20*$460
SIM_REPLAY_COMPANIONS = SIM_HISTORY_SLOTS*SIM_HISTORY_BYTES
SIM_REPLAY_HEADER = 36
SIM_REPLAY_INPUT_OFFSET = SIM_REPLAY_HEADER+SIM_REPLAY_PREFIX
SIM_REPLAY_NATIVE_OFFSET = SIM_REPLAY_INPUT_OFFSET+SIM_REPLAY_INPUTS
SIM_REPLAY_COMPANION_OFFSET = SIM_REPLAY_NATIVE_OFFSET+SIM_REPLAY_NATIVE
SIM_REPLAY_ROUTE_OFFSET = SIM_REPLAY_COMPANION_OFFSET+SIM_REPLAY_COMPANIONS
SIM_REPLAY_ROUTE_BYTES = 1802
SIM_REPLAY_CRC_OFFSET = SIM_REPLAY_ROUTE_OFFSET+SIM_REPLAY_ROUTE_BYTES+2
SIM_REPLAY_BYTES = SIM_REPLAY_CRC_OFFSET+4
 IFGT SIM_REPLAY_BYTES-65535
 FAIL "Replay copy loops require unsigned16-bit byte counts"
 ENDC

; A0 file, D0 actual byte count -> D0 10/20/50, or zero rejected.
; No state/output writes on any path. All other registers preserved.
sim_replay_validate:
 movem.l d1-d7/a0-a3,-(sp)
 cmp.l #SIM_REPLAY_PREFIX,d0
 blo .bad
 cmp.l #$34445250,(a0)    ; 4DRP
 beq .tagged
 ; Native mode is an unsigned byte, count an unsigned word.
 moveq #0,d1
 move.b 22(a0),d1
 cmp.w #10,d1
 beq .native
 cmp.w #20,d1
 bne .bad                ; untagged50 must never become an A2500 replay
.native:
 moveq #0,d2
 move.w 24(a0),d2
 move.w d1,d3
 mulu #600,d3
 cmp.l d3,d2
 bhi .bad
 add.l #SIM_REPLAY_PREFIX,d2
 cmp.l d2,d0
 bne .bad
 move.l d1,d0
 bra .out
.tagged:
 cmp.l #SIM_REPLAY_BYTES,d0
 bne .bad
 cmp.l #$4c303530,4(a0)   ; L050
 bne .bad
 cmp.l #$0002000a,8(a0)  ; format2, physics ABI10 (format1 omitted the opponent route)
 bne .bad
 cmp.l #$00320014,12(a0) ; 50Hz,20 slots
 bne .bad
 cmp.l #SIM_REPLAY_PREFIX,16(a0)
 bne .bad
 cmp.l #SIM_REPLAY_NATIVE,24(a0)
 bne .bad
 cmp.l #SIM_REPLAY_COMPANIONS,28(a0)
 bne .bad
 cmp.b #50,SIM_REPLAY_HEADER+22(a0)
 bne .bad
 move.l 20(a0),d4
 cmp.l #SIM_REPLAY_INPUTS,d4
 bhi .bad
 tst.l d4
 beq .bad                ; no initial checkpoint before the first input
 moveq #0,d1
 move.w SIM_REPLAY_HEADER+24(a0),d1
 cmp.l d4,d1
 bne .bad
 move.l 32(a0),d1
 cmp.l #45000,d1          ; 25-minute session, retained ten-minute window
 bhi .bad
 add.l d4,d1
 cmp.l #75000,d1
 bhi .bad
 move.l 32(a0),d1
 divu #1500,d1
 swap d1
 tst.w d1
 bne .bad
 movea.l a0,a1
 adda.l #SIM_REPLAY_NATIVE_OFFSET,a1
 movea.l a0,a2
 adda.l #SIM_REPLAY_COMPANION_OFFSET,a2
 cmp.w #50,(a2)          ; slot zero is the retained replay origin
 bne .bad
 moveq #0,d5
 moveq #19,d6
.slots:
 tst.w (a2)
 bne .present
 ; Native forward seek trusts its own valid flag. An absent companion must
 ; not leave a selectable native checkpoint that cannot restore fractions.
 tst.b $3f4(a1)
 bne .bad
 bra .next
.present:
 cmp.w #50,(a2)
 bne .bad
 cmp.b #1,$3f4(a1)
 bne .bad
 cmp.w $140(a1),d5
 bne .bad
 cmp.l d4,d5
 bhs .bad
.next:
 add.w #1500,d5
 lea $460(a1),a1
 lea SIM_HISTORY_BYTES(a2),a2
 dbra d6,.slots
 ; The table is static race state, outside the native checkpoint range.
 ; Require a bounded route and canonical zero tail/padding before any install.
 movea.l a0,a1
 adda.l #SIM_REPLAY_ROUTE_OFFSET,a1
 moveq #0,d2
 move.w #900,d3
 cmp.w #900,(a1)+         ; entry zero may itself be track index zero
 bhi .bad
.route:
 move.w (a1)+,d1
 cmp.w #900,d1
 bhi .bad
 tst.w d2
 beq .route_live
 tst.w d1
 bne .bad                ; no data after the first terminator
 bra .route_next
.route_live:
 tst.w d1
 bne .route_next
 moveq #1,d2
.route_next:
 subq.w #1,d3
 bne .route
 tst.w d2
 beq .bad                ; no terminator within the 901-word allocation
 tst.w (a1)              ; alignment padding is not part of the native table
 bne .bad
 move.l #SIM_REPLAY_CRC_OFFSET,d0
 bsr sim_replay_crc
 movea.l a0,a1
 adda.l #SIM_REPLAY_CRC_OFFSET,a1
 cmp.l (a1),d0
 bne .bad
 moveq #50,d0
 bra .out
.bad:
 moveq #0,d0
.out:
 movem.l (sp)+,d1-d7/a0-a3
 rts

; A4 game, A0 output (SIM_REPLAY_BYTES). D0=0 success,1 invalid state.
; Do not publish output before success. Preserve all other registers.
sim_replay_pack:
 movem.l d1-d7/a0-a6,-(sp)
 movea.l a0,a6
 cmp.w #50,-$15fa(a4)
 bne .bad
 cmp.b #50,-$173a(a4)
 bne .bad
 moveq #0,d4
 move.w -$1738(a4),d4
 cmp.l #SIM_REPLAY_INPUTS,d4
 bhi .bad
 tst.l d4
 beq .bad
 move.w #SIM_REPLAY_BYTES/4-1,d0
.clear:
 clr.l (a0)+
 dbra d0,.clear
 movea.l a6,a0
 move.l #$34445250,(a0)+
 move.l #$4c303530,(a0)+
 move.l #$0002000a,(a0)+
 move.l #$00320014,(a0)+
 move.l #SIM_REPLAY_PREFIX,(a0)+
 move.l d4,(a0)+
 move.l #SIM_REPLAY_NATIVE,(a0)+
 move.l #SIM_REPLAY_COMPANIONS,(a0)+
 moveq #0,d0
 move.w -$2e0(a4),d0
 move.l d0,32(a6)
 lea SIM_REPLAY_HEADER(a6),a1
 lea -$1750(a4),a0
 moveq #26-1,d0
 bsr sim_replay_copy
 movea.l -$1778(a4),a0
 move.w #901*2-1,d0
 bsr sim_replay_copy
 movea.l -$1770(a4),a0
 move.l d4,d0
 subq.w #1,d0
 bsr sim_replay_copy
 movea.l a6,a3
 adda.l #SIM_REPLAY_NATIVE_OFFSET,a3
 lea sim_replay_pack(pc),a2
 adda.l #sim_history_records-sim_replay_pack,a2
 movea.l (a2),a2
 movea.l -$16bc(a4),a5
 moveq #19,d7
.slots:
 tst.w (a2)
 beq .next
 cmp.w #50,(a2)
 bne .bad
 movea.l a5,a0
 movea.l a3,a1
 move.w #$460-1,d0
 bsr sim_replay_copy
 movea.l a2,a0
 movea.l a3,a1
 adda.l #SIM_REPLAY_NATIVE,a1
 ; Companions have a different stride than native records.
 moveq #19,d0
 sub.w d7,d0
 mulu #($460-SIM_HISTORY_BYTES),d0
 suba.l d0,a1
 move.w #SIM_HISTORY_BYTES-1,d0
 bsr sim_replay_copy
.next:
 lea $460(a5),a5
 lea $460(a3),a3
 lea SIM_HISTORY_BYTES(a2),a2
 dbra d7,.slots
 ; Copy only the live route. Native setup leaves stale allocation bytes
 ; after its terminator; the cleared output gives these a canonical zero tail.
 tst.b -$174a(a4)
 beq .route_packed
 movea.l -$17a4(a4),a0
 movea.l a6,a1
 adda.l #SIM_REPLAY_ROUTE_OFFSET,a1
 move.w (a0)+,(a1)+
 move.w #899,d0
.pack_route:
 move.w (a0)+,d1
 move.w d1,(a1)+
 beq .route_packed
 dbra d0,.pack_route
 bra .bad
.route_packed:
 movea.l a6,a0
 move.l #SIM_REPLAY_CRC_OFFSET,d0
 bsr sim_replay_crc
 movea.l a6,a1
 adda.l #SIM_REPLAY_CRC_OFFSET,a1
 move.l d0,(a1)
 move.l #SIM_REPLAY_BYTES,d0
 bsr sim_replay_validate
 cmp.w #50,d0
 bne .bad
 moveq #0,d0
 bra .out
.bad:
 moveq #1,d0
.out:
 movem.l (sp)+,d1-d7/a0-a6
 rts

; A0 tagged file,D0 length,A1 descriptor of five output pointers:
; prefix(1828),inputs(30000),native(22400),companions(7840),epoch(4).
; The validated static route is installed separately by sim_replay_install.
; D0=0 success,1 invalid. Validate everything before changing any output.
; Outputs must not overlap file, descriptor or each other. Preserve registers.
sim_replay_unpack:
 movem.l d1-d7/a0-a3,-(sp)
 bsr sim_replay_validate
 cmp.w #50,d0
 bne .bad
 movea.l a0,a2
 movea.l a1,a3
 move.l 32(a2),d1
 lea SIM_REPLAY_HEADER(a2),a0
 movea.l (a3)+,a1
 move.w #SIM_REPLAY_PREFIX-1,d0
 bsr sim_replay_copy
 movea.l (a3)+,a1
 move.w #SIM_REPLAY_INPUTS-1,d0
 bsr sim_replay_copy
 movea.l (a3)+,a1
 move.w #SIM_REPLAY_NATIVE-1,d0
 bsr sim_replay_copy
 movea.l (a3)+,a1
 move.w #SIM_REPLAY_COMPANIONS-1,d0
 bsr sim_replay_copy
 movea.l (a3),a1
 move.l d1,(a1)
 moveq #0,d0
 bra .out
.bad:
 moveq #1,d0
.out:
 movem.l (sp)+,d1-d7/a0-a3
 rts
sim_replay_copy:
 move.b (a0)+,(a1)+
 dbra d0,sim_replay_copy
 rts
sim_replay_crc:
 move.l a1,-(sp)
 lea sim_replay_crc(pc),a1
 adda.l #sim_score_crc32-sim_replay_crc,a1
 jsr (a1)
 move.l (sp)+,a1
 rts
