; Tagged exact-score sidecar. The native .hig remains exactly 364 bytes.
; All integers are big-endian. Header: "4DHIG100", version.w=1, rows.w=7,
; native_bytes.l=364, CRC32.l of the 420-byte body. Body: native rows (364 bytes),
; then seven unsigned 64-bit hundredths. Empty is UINT64_MAX.
SIM_SCORE_ROWS = 7
SIM_SCORE_NATIVE_BYTES = 364
SIM_SCORE_EXACT_BYTES = 56
SIM_SCORE_HEADER_BYTES = 20
SIM_SCORE_EXACT_OFFSET = SIM_SCORE_HEADER_BYTES+SIM_SCORE_NATIVE_BYTES
SIM_SCORE_FILE_BYTES = SIM_SCORE_EXACT_OFFSET+SIM_SCORE_EXACT_BYTES

; D2:D0 exact hundredths -> D0 native 20 Hz word, zero-extended.
; Round UP for the compatibility mirror, never manufacture a faster time.
; Values beyond 65534 native ticks useFFFF (hidden in the stock UI). Only
; the enhanced UI must use the exact sidecar for ranking/display.
; D2 is preserved. Empty also maps to FFFF. Validate the domain separately.
sim_score_native_mirror:
 tst.l d2
 bne .hidden
 cmp.l #65534*5,d0
 bhi .hidden
 addq.l #4,d0
 divu #5,d0
 and.l #$ffff,d0
 rts
.hidden:
 move.l #$ffff,d0
 rts

; A0 native rows, A1 exact values -> D0=0 valid,1 invalid.
; Validate mirror consistency, unsigned ascending order (empty last), and
; the common domain <=10*UINT32_MAX. Preserve all other registers.
sim_score_rows_valid:
 movem.l d1-d7/a0-a6,-(sp)
 movea.l a0,a3
 movea.l a1,a4
 moveq #6,d7
.row:
 move.l (a4),d2
 move.l 4(a4),d0
 cmp.l #-1,d2
 bne .finite
 cmp.l #-1,d0
 bne .invalid
 bra .mirror
.finite:
 cmp.l #9,d2
 bhi .invalid
 bne .mirror
 cmp.l #$fffffff6,d0
 bhi .invalid
.mirror:
 bsr sim_score_native_mirror
 cmp.w 50(a3),d0
 bne .invalid
 cmp.w #6,d7
 beq .next
 lea -8(a4),a0
 movea.l a4,a1
 bsr sim_score_compare
 bhi .invalid
.next:
 lea 52(a3),a3
 addq.l #8,a4
 dbra d7,.row
 moveq #0,d0
 bra .out
.invalid:
 moveq #1,d0
.out:
 movem.l (sp)+,d1-d7/a0-a6
 rts

; A0 data, D0 unsigned byte count -> D0 reflected IEEE CRC32.
; Preserve other registers, including A0. Used only outside the tick loop.
sim_score_crc32:
 movem.l d1-d3/a0,-(sp)
 move.l d0,d1
 moveq #-1,d0
 tst.l d1
 beq .done
.byte:
 moveq #0,d3
 move.b (a0)+,d3
 eor.l d3,d0
 moveq #7,d2
.bit:
 lsr.l #1,d0
 bcc .next
 eor.l #$edb88320,d0
.next:
 dbra d2,.bit
 subq.l #1,d1
 bne .byte
.done:
 not.l d0
 movem.l (sp)+,d1-d3/a0
 rts

; A0 native (364 bytes), A1 exact (56 bytes), A2 destination (440 bytes) -> D0=0 success,1 invalid.
; Inputs/output must not overlap. Invalid input leaves output unchanged.
sim_score_encode:
 movem.l d1-d7/a0-a6,-(sp)
 bsr sim_score_rows_valid
 tst.l d0
 bne .out
 move.l #$34444849,(a2)+       ; 4DHI
 move.l #$47313030,(a2)+       ; G100
 move.w #1,(a2)+
 move.w #SIM_SCORE_ROWS,(a2)+
 move.l #SIM_SCORE_NATIVE_BYTES,(a2)+
 clr.l (a2)+                  ; CRC written after the body
 movea.l a2,a3
 moveq #SIM_SCORE_NATIVE_BYTES/4-1,d1
.native:
 move.l (a0)+,(a2)+
 dbra d1,.native
 moveq #SIM_SCORE_EXACT_BYTES/4-1,d1
.exact:
 move.l (a1)+,(a2)+
 dbra d1,.exact
 movea.l a3,a0
 move.l #SIM_SCORE_NATIVE_BYTES+SIM_SCORE_EXACT_BYTES,d0
 bsr sim_score_crc32
 move.l d0,-4(a3)
 moveq #0,d0
.out:
 movem.l (sp)+,d1-d7/a0-a6
 rts

; A0 file, D0 file length, A1 current native (364 bytes), A2 destination exact (56 bytes).
; D0=0 success,1 invalid. Check length before any file access. Reject unknown
; versions, checksum errors, stale native binding and invalid score rows.
; Failure leaves the complete destination unchanged. Buffers must not overlap.
sim_score_decode:
 movem.l d1-d7/a0-a6,-(sp)
 cmp.l #SIM_SCORE_FILE_BYTES,d0
 bne .invalid
 cmp.l #$34444849,(a0)
 bne .invalid
 cmp.l #$47313030,4(a0)
 bne .invalid
 cmp.w #1,8(a0)
 bne .invalid
 cmp.w #SIM_SCORE_ROWS,10(a0)
 bne .invalid
 cmp.l #SIM_SCORE_NATIVE_BYTES,12(a0)
 bne .invalid
 movea.l a0,a3
 lea SIM_SCORE_HEADER_BYTES(a0),a0
 move.l #SIM_SCORE_NATIVE_BYTES+SIM_SCORE_EXACT_BYTES,d0
 bsr sim_score_crc32
 cmp.l 16(a3),d0
 bne .invalid
 movea.l a1,a4
 moveq #SIM_SCORE_NATIVE_BYTES/4-1,d1
.bind:
 move.l (a0)+,d0
 cmp.l (a1)+,d0
 bne .invalid
 dbra d1,.bind
 movea.l a0,a1              ; exact values follow native bytes
 movea.l a4,a0
 bsr sim_score_rows_valid
 tst.l d0
 bne .invalid
 moveq #SIM_SCORE_EXACT_BYTES/4-1,d1
.copy:
 move.l (a1)+,(a2)+
 dbra d1,.copy
 moveq #0,d0
 bra .out
.invalid:
 moveq #1,d0
.out:
 movem.l (sp)+,d1-d7/a0-a6
 rts

; A0 filename, A1 native (364 bytes), A2 exact destination56, A6 DOS library.
; D0=0 loaded,1 open failure,2 read/format failure; preserve other registers.
; Read at most 441 bytes into 442 bytes, detecting oversized files without
; trusting their size or the original unbounded native load wrapper.
; Main-task-only, non-reentrant; inputs must not alias the staging buffer.
sim_score_file_load:
 movem.l d1-d7/a0-a5,-(sp)
 movea.l a1,a4
 movea.l a2,a5
 move.l a0,d1
 move.l #1005,d2             ; MODE_OLDFILE
 jsr _LVOOpen(a6)
 move.l d0,d4
 beq .missing
 move.l d4,d1
 lea sim_score_file_buffer(pc),a3
 move.l a3,d2
 move.l #SIM_SCORE_FILE_BYTES+1,d3
 jsr _LVORead(a6)
 move.l d0,d5
 move.l d4,d1
 jsr _LVOClose(a6)           ; no defined result on Kickstart 1.3
 move.l d5,d0
 movea.l a3,a0
 movea.l a4,a1
 movea.l a5,a2
 bsr sim_score_decode
 tst.l d0
 beq .out
 moveq #2,d0
 bra .out
.missing:
 moveq #1,d0
.out:
 movem.l (sp)+,d1-d7/a0-a5
 rts

; A0 filename, A1 native (364 bytes), A2 exact (56 bytes), A6 DOS library.
; D0=0 verified save,1 invalid input/open/short-write/readback failure.
; Preserve all other registers. Inputs must not alias private staging/readback.
; Write only after validating the complete input.
; Reopen and compare the exact payload: pre-V36 Close has no status result.
; Caller must save the matching native rows first, propagate failure, and
; must not report success until both native and exact saves have succeeded.
sim_score_file_save:
 movem.l d1-d7/a0-a5,-(sp)
 movea.l a0,a5
 movea.l a1,a3
 movea.l a2,a4
 movea.l a1,a0
 movea.l a2,a1
 lea sim_score_file_buffer(pc),a2
 bsr sim_score_encode
 tst.l d0
 bne .failed
 move.l a5,d1
 move.l #1006,d2             ; MODE_NEWFILE
 jsr _LVOOpen(a6)
 move.l d0,d4
 beq .failed
 move.l d4,d1
 lea sim_score_file_buffer(pc),a0
 move.l a0,d2
 move.l #SIM_SCORE_FILE_BYTES,d3
 jsr _LVOWrite(a6)
 move.l d0,d5
 move.l d4,d1
 jsr _LVOClose(a6)
 cmp.l #SIM_SCORE_FILE_BYTES,d5
 bne .failed
 movea.l a5,a0
 movea.l a3,a1
 lea sim_score_file_readback(pc),a2
 bsr sim_score_file_load
 tst.l d0
 bne .failed
 moveq #SIM_SCORE_EXACT_BYTES/4-1,d1
.compare:
 move.l (a4)+,d0
 cmp.l (a2)+,d0
 bne .failed
 dbra d1,.compare
 moveq #0,d0
 bra .out
.failed:
 moveq #1,d0
.out:
 movem.l (sp)+,d1-d7/a0-a5
 rts

 even
sim_score_file_guard_before: dc.l $53434f52
sim_score_file_buffer: dcb.b SIM_SCORE_FILE_BYTES+2,0
sim_score_file_guard_after: dc.l $45475541
sim_score_file_readback: dcb.b SIM_SCORE_EXACT_BYTES,0
sim_score_file_readback_guard: dc.l $52442121
