; Real 68000 validation of score codec boundaries, rejection and output guards.
 even
 dc.b "4DSCFILE"
 dc.w 1,470
sim_score_file_passed: dc.l 0
sim_score_test_native_guard: dc.l $11223344
sim_score_test_native: dcb.b SIM_SCORE_NATIVE_BYTES,0
sim_score_test_native_end: dc.l $55667788
sim_score_test_exact:
 dc.l 0,0,0,2,0,5,0,150000,0,327670,1,$fffffffe,-1,-1
sim_score_test_file_guard: dc.l $12345678
sim_score_test_file: dcb.b SIM_SCORE_FILE_BYTES,0
sim_score_test_file_end: dc.l $87654321
sim_score_test_out_guard: dc.l $13572468
sim_score_test_out: dcb.b SIM_SCORE_EXACT_BYTES,0
sim_score_test_out_end: dc.l $24681357
sim_score_test_crc_text: dc.b "123456789",0
 even
sim_score_test_lengths: dc.l 0,1,SIM_SCORE_FILE_BYTES-1,SIM_SCORE_FILE_BYTES+1,-1
sim_score_test_stale: dc.w 0,51,52,363
sim_score_test_mirrors:
 dc.l $00000000,$00000000,$00000000
 dc.l $00000000,$00000001,$00000001
 dc.l $00000000,$00000002,$00000001
 dc.l $00000000,$00000003,$00000001
 dc.l $00000000,$00000004,$00000001
 dc.l $00000000,$00000005,$00000001
 dc.l $00000000,$00000006,$00000002
 dc.l $00000000,$0004fff5,$0000fffe
 dc.l $00000000,$0004fff6,$0000fffe
 dc.l $00000000,$0004fff7,$0000ffff
 dc.l $00000001,$00000000,$0000ffff
 dc.l $ffffffff,$ffffffff,$0000ffff

sim_score_file_selftest:
 movem.l d0-a6,-(sp)
 lea sim_score_file_passed(pc),a6
 clr.l (a6)
 lea sim_score_test_native(pc),a3
 lea sim_score_test_exact(pc),a4
 lea sim_score_test_file(pc),a5
 lea sim_score_test_crc_text(pc),a0
 moveq #9,d0
 bsr sim_score_crc32
 cmp.l #$cbf43926,d0
 bne sim_score_file_test_failed
 addq.l #1,(a6)
 moveq #0,d0
 bsr sim_score_crc32
 tst.l d0
 bne sim_score_file_test_failed
 addq.l #1,(a6)
 lea sim_score_test_mirrors(pc),a2
 moveq #11,d7
.mirrors:
 move.l (a2),d2
 move.l 4(a2),d0
 bsr sim_score_native_mirror
 cmp.l 8(a2),d0
 bne sim_score_file_test_failed
 cmp.l (a2),d2
 bne sim_score_file_test_failed
 addq.l #1,(a6)
 lea 12(a2),a2
 dbra d7,.mirrors
 ; Distinct native bytes make binding cover all fields, not just the names.
 movea.l a3,a0
 move.w #SIM_SCORE_NATIVE_BYTES-1,d1
 moveq #0,d0
.fill_native:
 move.b d0,(a0)+
 addq.b #1,d0
 dbra d1,.fill_native
 movea.l a3,a0
 movea.l a4,a1
 moveq #6,d7
.mirror_rows:
 move.l (a1)+,d2
 move.l (a1)+,d0
 bsr sim_score_native_mirror
 move.w d0,50(a0)
 lea 52(a0),a0
 dbra d7,.mirror_rows
 bsr sim_score_file_test_encode
 tst.l d0
 bne sim_score_file_test_failed
 bsr sim_score_file_test_decode
 tst.l d0
 bne sim_score_file_test_failed
 lea sim_score_test_out(pc),a0
 movea.l a4,a1
 moveq #SIM_SCORE_EXACT_BYTES/4-1,d1
.roundtrip:
 move.l (a0)+,d0
 cmp.l (a1)+,d0
 bne sim_score_file_test_failed
 dbra d1,.roundtrip
 addq.l #1,(a6)
 bsr sim_score_file_test_fill_out
 ; A flipped bit in every byte of header/body must fail, leaving output intact.
 moveq #0,d7
.corrupt:
 eor.b #1,(a5,d7.w)
 bsr sim_score_file_test_decode
 tst.l d0
 beq sim_score_file_test_failed
 bsr sim_score_file_test_unchanged
 eor.b #1,(a5,d7.w)
 addq.l #1,(a6)
 addq.w #1,d7
 cmp.w #SIM_SCORE_FILE_BYTES,d7
 blo .corrupt
 lea sim_score_test_lengths(pc),a0
 moveq #4,d7
.length:
 move.l (a0)+,d0
 movem.l a0,-(sp)
 movea.l a5,a0
 movea.l a3,a1
 lea sim_score_test_out(pc),a2
 bsr sim_score_decode
 movem.l (sp)+,a0
 tst.l d0
 beq sim_score_file_test_failed
 movem.l a0,-(sp)
 bsr sim_score_file_test_unchanged
 movem.l (sp)+,a0
 addq.l #1,(a6)
 dbra d7,.length
 lea sim_score_test_stale(pc),a2
 moveq #3,d7
.stale:
 moveq #0,d6
 move.w (a2)+,d6
 eor.b #1,(a3,d6.w)
 movem.l a2,-(sp)
 bsr sim_score_file_test_decode
 tst.l d0
 beq sim_score_file_test_failed
 bsr sim_score_file_test_unchanged
 movem.l (sp)+,a2
 eor.b #1,(a3,d6.w)
 addq.l #1,(a6)
 dbra d7,.stale
 ; Domain violations, an inconsistent mirror, ordering, and premature empty.
 move.l #10,40(a4)
 bsr sim_score_file_test_invalid
 move.l #1,40(a4)
 move.l #9,40(a4)
 move.l #$fffffff7,44(a4)
 bsr sim_score_file_test_invalid
 move.l #1,40(a4)
 move.l #$fffffffe,44(a4)
 move.l #-2,52(a4)
 bsr sim_score_file_test_invalid
 move.l #-1,52(a4)
 move.w #1,50(a3)
 bsr sim_score_file_test_invalid
 clr.w 50(a3)
 move.l #327670,28(a4)
 move.l #150000,36(a4)
 move.w #65534,3*52+50(a3)
 move.w #30000,4*52+50(a3)
 bsr sim_score_file_test_invalid
 move.l #150000,28(a4)
 move.l #327670,36(a4)
 move.w #30000,3*52+50(a3)
 move.w #65534,4*52+50(a3)
 move.l #-1,(a4)
 move.l #-1,4(a4)
 move.w #$ffff,50(a3)
 bsr sim_score_file_test_invalid
 clr.l (a4)
 clr.l 4(a4)
 clr.w 50(a3)
 bsr sim_score_file_test_encode ; leave a valid golden file for host inspection
 tst.l d0
 bne sim_score_file_test_failed
 bsr sim_score_file_test_guards
 movem.l (sp)+,d0-a6
 rts

sim_score_file_test_encode:
 movea.l a3,a0
 movea.l a4,a1
 movea.l a5,a2
 bra sim_score_encode
sim_score_file_test_decode:
 movea.l a5,a0
 move.l #SIM_SCORE_FILE_BYTES,d0
 movea.l a3,a1
 lea sim_score_test_out(pc),a2
 bra sim_score_decode
sim_score_file_test_fill_out:
 lea sim_score_test_out(pc),a0
 moveq #SIM_SCORE_EXACT_BYTES/4-1,d1
.fill:
 move.l #$a5a5a5a5,(a0)+
 dbra d1,.fill
 rts
sim_score_file_test_unchanged:
 lea sim_score_test_out(pc),a0
 moveq #SIM_SCORE_EXACT_BYTES/4-1,d1
.check:
 cmp.l #$a5a5a5a5,(a0)+
 bne sim_score_file_test_failed
 dbra d1,.check
 rts
sim_score_file_test_invalid:
 movea.l a5,a0
 move.w #SIM_SCORE_FILE_BYTES/4-1,d1
.fill:
 move.l #$a5a5a5a5,(a0)+
 dbra d1,.fill
 bsr sim_score_file_test_encode
 tst.l d0
 beq sim_score_file_test_failed
 movea.l a5,a0
 move.w #SIM_SCORE_FILE_BYTES/4-1,d1
.unchanged:
 cmp.l #$a5a5a5a5,(a0)+
 bne sim_score_file_test_failed
 dbra d1,.unchanged
 ; Construct a checksummed but semantically invalid file, bypassing encode.
 move.l #$34444849,(a5)
 move.l #$47313030,4(a5)
 move.w #1,8(a5)
 move.w #SIM_SCORE_ROWS,10(a5)
 move.l #SIM_SCORE_NATIVE_BYTES,12(a5)
 lea SIM_SCORE_HEADER_BYTES(a5),a0
 movea.l a3,a1
 moveq #SIM_SCORE_NATIVE_BYTES/4-1,d1
.native:
 move.l (a1)+,(a0)+
 dbra d1,.native
 movea.l a4,a1
 moveq #SIM_SCORE_EXACT_BYTES/4-1,d1
.exact:
 move.l (a1)+,(a0)+
 dbra d1,.exact
 lea SIM_SCORE_HEADER_BYTES(a5),a0
 move.l #SIM_SCORE_NATIVE_BYTES+SIM_SCORE_EXACT_BYTES,d0
 bsr sim_score_crc32
 move.l d0,16(a5)
 bsr sim_score_file_test_decode
 tst.l d0
 beq sim_score_file_test_failed
 bsr sim_score_file_test_unchanged
 addq.l #1,(a6)
 rts
sim_score_file_test_guards:
 lea sim_score_test_native_guard(pc),a0
 cmp.l #$11223344,(a0)
 bne sim_score_file_test_failed
 lea sim_score_test_native_end(pc),a0
 cmp.l #$55667788,(a0)
 bne sim_score_file_test_failed
 lea sim_score_test_file_guard(pc),a0
 cmp.l #$12345678,(a0)
 bne sim_score_file_test_failed
 lea sim_score_test_file_end(pc),a0
 cmp.l #$87654321,(a0)
 bne sim_score_file_test_failed
 lea sim_score_test_out_guard(pc),a0
 cmp.l #$13572468,(a0)
 bne sim_score_file_test_failed
 lea sim_score_test_out_end(pc),a0
 cmp.l #$24681357,(a0)
 bne sim_score_file_test_failed
 lea sim_score_file_guard_before(pc),a0
 cmp.l #$53434f52,(a0)
 bne sim_score_file_test_failed
 lea sim_score_file_guard_after(pc),a0
 cmp.l #$45475541,(a0)
 bne sim_score_file_test_failed
 lea sim_score_file_readback_guard(pc),a0
 cmp.l #$52442121,(a0)
 bne sim_score_file_test_failed
 rts
sim_score_file_test_failed:
 lea sim_score_file_test_failed(pc),a0
 adda.l #perf_failure-sim_score_file_test_failed,a0
 move.l #26,(a0)
 illegal
 bra sim_score_file_test_failed

 IFD SIM_SCORE_IO_TEST
; Explicit opt-in filesystem fixture. The harness boots a fresh writable copy
; of the game, so this reserved test filename never touches original assets.
 even
 dc.b "4DSCIO!!"
 dc.w 1,8
sim_score_io_passed: dc.l 0
sim_score_io_name: dc.b "__4D_SCORE_TEST.hix",0
 even
sim_score_io_selftest:
 movem.l d0-a6,-(sp)
 move.l 4.w,a6
 lea sim_score_io_selftest(pc),a1
 adda.l #_dosname-sim_score_io_selftest,a1
 jsr _LVOOldOpenLibrary(a6)
 tst.l d0
 beq sim_score_file_test_failed
 movea.l d0,a6
 lea sim_score_test_native(pc),a3
 lea sim_score_test_exact(pc),a4
 lea sim_score_io_passed(pc),a5
 clr.l (a5)
 lea sim_score_io_name(pc),a0
 move.l a0,d1
 jsr _LVODeleteFile(a6)
 bsr sim_score_file_test_fill_out
 bsr sim_score_io_load
 cmp.l #1,d0
 bne sim_score_file_test_failed
 bsr sim_score_file_test_unchanged
 addq.l #1,(a5)
 bsr sim_score_io_save
 tst.l d0
 bne sim_score_file_test_failed
 addq.l #1,(a5)
 bsr sim_score_io_load
 tst.l d0
 bne sim_score_file_test_failed
 bsr sim_score_io_equal
 addq.l #1,(a5)
 move.l #SIM_SCORE_FILE_BYTES-1,d3
 bsr sim_score_io_write_raw
 bsr sim_score_io_reject
 addq.l #1,(a5)
 move.l #SIM_SCORE_FILE_BYTES+1,d3
 bsr sim_score_io_write_raw
 bsr sim_score_io_reject
 addq.l #1,(a5)
 lea sim_score_test_file(pc),a0
 eor.b #1,SIM_SCORE_EXACT_OFFSET+1(a0)
 move.l #SIM_SCORE_FILE_BYTES,d3
 bsr sim_score_io_write_raw
 bsr sim_score_io_reject
 lea sim_score_test_file(pc),a0
 eor.b #1,SIM_SCORE_EXACT_OFFSET+1(a0)
 addq.l #1,(a5)
 ; Invalid input must not truncate a previously valid saved file.
 bsr sim_score_io_save
 tst.l d0
 bne sim_score_file_test_failed
 move.w #1,50(a3)
 bsr sim_score_io_save
 cmp.l #1,d0
 bne sim_score_file_test_failed
 clr.w 50(a3)
 bsr sim_score_io_load
 tst.l d0
 bne sim_score_file_test_failed
 bsr sim_score_io_equal
 addq.l #1,(a5)
 ; KickEmu aborts on a nonexistent save directory. Inject a DOS Open
 ; failure instead; never trigger that host-level abort as a test.
 movem.l a6,-(sp)
 lea sim_score_io_fail_base(pc),a6
 bsr sim_score_io_save
 movem.l (sp)+,a6
 cmp.l #1,d0
 bne sim_score_file_test_failed
 addq.l #1,(a5)
 bsr sim_score_file_test_guards
 ; Leave the final valid test file for independent host byte/CRC inspection.
 movea.l a6,a1
 move.l 4.w,a6
 jsr _LVOCloseLibrary(a6)
 movem.l (sp)+,d0-a6
 rts
sim_score_io_save:
 lea sim_score_io_name(pc),a0
 movea.l a3,a1
 movea.l a4,a2
 bra sim_score_file_save
sim_score_io_load:
 lea sim_score_io_name(pc),a0
 movea.l a3,a1
 lea sim_score_test_out(pc),a2
 bra sim_score_file_load
sim_score_io_equal:
 lea sim_score_test_out(pc),a0
 movea.l a4,a1
 moveq #SIM_SCORE_EXACT_BYTES/4-1,d1
.equal:
 move.l (a0)+,d0
 cmp.l (a1)+,d0
 bne sim_score_file_test_failed
 dbra d1,.equal
 rts
sim_score_io_reject:
 bsr sim_score_file_test_fill_out
 bsr sim_score_io_load
 cmp.l #2,d0
 bne sim_score_file_test_failed
 bra sim_score_file_test_unchanged
; Test-only raw writer deliberately makes short/oversized/corrupt files.
; D3 length <=441 from a 442-byte readable fixture area. A6 DOS library.
sim_score_io_write_raw:
 movem.l d0-d7/a0-a5,-(sp)
 move.l d3,d5
 lea sim_score_io_name(pc),a0
 move.l a0,d1
 move.l #1006,d2
 jsr _LVOOpen(a6)
 move.l d0,d4
 beq sim_score_file_test_failed
 move.l d4,d1
 lea sim_score_test_file(pc),a0
 move.l a0,d2
 move.l d5,d3
 jsr _LVOWrite(a6)
 cmp.l d5,d0
 bne sim_score_file_test_failed
 move.l d4,d1
 jsr _LVOClose(a6)
 movem.l (sp)+,d0-d7/a0-a5
 rts
 even
sim_score_io_fail_vectors:
 bra.w sim_score_io_open_failed
 nop
 dcb.b 24,0
sim_score_io_fail_base: dc.l 0
sim_score_io_open_failed:
 moveq #0,d0
 rts
 ENDC
