; Native high-score load/reset integration. Exact times have the SAME physical
; row order as A4-$1784. Native A4-$160A maps displayed/saved row order.
; Insertion and sorted saving are in simulation_score_insert.s.
; Exact UI consumers are in simulation_score_display.s.

; A0 native .hig name -> D0=0 and private .hix name, or 1 invalid/too long.
; Preserve other registers; never modify the caller's native filename.
sim_score_companion_name:
 movem.l d1-d2/a0-a2,-(sp)
 lea sim_score_companion_path(pc),a1
 movea.l a1,a2
 moveq #0,d1
.copy:
 move.b (a0)+,d0
 beq .end
 cmp.w #255,d1
 bhs .invalid
 move.b d0,(a1)+
 addq.w #1,d1
 bra .copy
.end:
 clr.b (a1)
 cmp.w #4,d1
 blo .invalid
 cmp.b #'.',-4(a1)
 bne .invalid
 move.b -3(a1),d0
 or.b #$20,d0
 cmp.b #'h',d0
 bne .invalid
 move.b -2(a1),d0
 or.b #$20,d0
 cmp.b #'i',d0
 bne .invalid
 move.b -1(a1),d0
 or.b #$20,d0
 cmp.b #'g',d0
 bne .invalid
 move.b #'h',-3(a1)
 move.b #'i',-2(a1)
 move.b #'x',-1(a1)
 moveq #0,d0
 bra .out
.invalid:
 clr.b (a2)
 moveq #1,d0
.out:
 movem.l (sp)+,d1-d2/a0-a2
 rts

; A0 filename, A1 native destination (364 bytes), A6 DOS.
; D0=0 success, 1 object not found, 2 other open/read/length failure.
; A bounded replacement for the native whole-file load into 364 allocated bytes.
; All other registers preserved. Reuse sidecar staging outside simulation.
sim_score_native_load:
 movem.l d1-d7/a0-a5,-(sp)
 movea.l a1,a4
 move.l a0,d1
 move.l #1005,d2
 jsr _LVOOpen(a6)
 move.l d0,d4
 beq .open_failed
 move.l d4,d1
 lea sim_score_native_load(pc),a3
 adda.l #sim_score_file_buffer-sim_score_native_load,a3
 move.l a3,d2
 move.l #SIM_SCORE_NATIVE_BYTES+1,d3
 jsr _LVORead(a6)
 move.l d0,d5
 move.l d4,d1
 jsr _LVOClose(a6)
 cmp.l #SIM_SCORE_NATIVE_BYTES,d5
 bne .failed
 moveq #SIM_SCORE_NATIVE_BYTES/4-1,d1
.copy:
 move.l (a3)+,(a4)+
 dbra d1,.copy
 moveq #0,d0
 bra .out
.open_failed:
 ; IoErr must be read immediately after Open fails. Only object-not-found
 ; authorizes automatic creation; permissions, devices and bad data do not.
 jsr _LVOIoErr(a6)
 cmp.l #205,d0             ; ERROR_OBJECT_NOT_FOUND, DOS V1.3
 bne .failed
 moveq #1,d0
 bra .out
.failed:
 moveq #2,d0
.out:
 movem.l (sp)+,d1-d7/a0-a5
 rts

; A0 native (364 bytes) -> initialize exact physical rows from native 20 Hz words.
sim_score_import_rows:
 movem.l d0-d2/d7/a0-a1,-(sp)
 lea sim_score_records(pc),a1
 moveq #6,d7
.row:
 move.w 50(a0),d0
 bsr sim_score_from_native
 move.l d2,(a1)+
 move.l d0,(a1)+
 lea 52(a0),a0
 dbra d7,.row
 movem.l (sp)+,d0-d2/d7/a0-a1
 rts

; $3956..$395E: original load(kind10,filename,buffer), then store return length.
; The surrounding native caller still owns error handling and the loading flag.
sim_score_load_hook:
 movem.l d1-d7/a0-a6,-(sp)
 lea sim_score_record_loads(pc),a0
 addq.l #1,(a0)
 lea sim_score_record_status(pc),a0
 move.l #3,(a0)             ; native load failed until proved otherwise
 lea sim_score_records(pc),a0
 moveq #13,d0
.clear:
 move.l #-1,(a0)+
 dbra d0,.clear
 movea.l $bda(a4),a6
 lea -$1736(a4),a0
 movea.l -$1784(a4),a1
 bsr sim_score_native_load
 cmp.l #1,d0
 beq .missing
 tst.l d0
 bne .failed
 movea.l -$1784(a4),a0
 bsr sim_score_import_rows
 lea sim_score_record_status(pc),a0
 clr.l (a0)                ; native-only (no companion) is fully supported
 lea -$1736(a4),a0
 bsr sim_score_companion_name
 tst.l d0
 bne .bad_name
 lea sim_score_companion_path(pc),a0
 movea.l -$1784(a4),a1
 lea sim_score_records(pc),a2
 bsr sim_score_file_load
 cmp.l #1,d0
 beq .loaded               ; no companion: retain exact native 20 Hz import
 tst.l d0
 bne .bad_sidecar
 lea sim_score_record_status(pc),a0
 move.l #1,(a0)
 bra .loaded
.bad_name:
 lea sim_score_record_status(pc),a0
 move.l #4,(a0)
 bra .loaded
.bad_sidecar:
 lea sim_score_record_status(pc),a0
 move.l #2,(a0)             ; reject it; future UI must surface this status
.loaded:
 IFD SIM_SCORE_RESET_TEST
 lea sim_score_reset_test_count(pc),a0
 tst.l (a0)
 bne .reset_test_done
 addq.l #1,(a0)
 move.w #1,-(sp)
 lea sim_score_load_hook(pc),a0
 adda.l #tape_game-sim_score_load_hook,a0
 move.l (a0),a0
 adda.l #$38f8,a0
 jsr (a0)                  ; actual native clear-records entry, nested A5 frame
 addq.l #2,sp
 lea sim_score_reset_test_result(pc),a0
 move.l d0,(a0)
.reset_test_done:
 ENDC
 move.l #SIM_SCORE_NATIVE_BYTES,d0
 bra .out
.missing:
 lea sim_score_record_status(pc),a0
 move.l #7,(a0)             ; only this failure permits automatic creation
.failed:
 moveq #0,d0
.out:
 movem.l (sp)+,d1-d7/a0-a6
 move.l d0,-6(a5)          ; displaced original instruction
 rts


; $5F56..$5F5C: results fallback reset(kind1), then native TST.B D0.
; The preceding failed load is not permission to replace an existing file.
; Recreate the native kind1 call frame only after confirmed object-not-found.
; Explicit clear-records callers retain their own behavior.
sim_score_autocreate:
 movem.l d1-d7/a0-a6,-(sp)
 lea sim_score_record_status(pc),a0
 cmp.l #7,(a0)
 bne .reject
 move.w #1,-(sp)
 lea sim_score_autocreate(pc),a0
 adda.l #tape_game-sim_score_autocreate,a0
 move.l (a0),a0
 adda.l #$38f8,a0
 jsr (a0)
 addq.l #2,sp
 bra .out
.reject:
 moveq #1,d0
.out:
 movem.l (sp)+,d1-d7/a0-a6
 tst.b d0
 rts

; $39DC..$39E4: native clear-records save plus its word return assignment.
; Keep native write first, then replace a previous exact sidecar with empty
; exact records. A failed companion save returns failure to the native caller.
sim_score_reset_hook:
 movem.l d1-d7/a0-a6,-(sp)
 lea sim_score_record_resets(pc),a0
 addq.l #1,(a0)
 movea.l -$1784(a4),a0
 bsr sim_score_import_rows
 move.l #SIM_SCORE_NATIVE_BYTES,-(sp)
 move.l -$1784(a4),-(sp)
 pea -$1736(a4)
 jsr -$7ae8(a4)
 lea 12(sp),sp
 tst.l d0
 bne .failed
 lea -$1736(a4),a0
 bsr sim_score_companion_name
 tst.l d0
 bne .failed
 movea.l $bda(a4),a6
 lea sim_score_companion_path(pc),a0
 movea.l -$1784(a4),a1
 lea sim_score_records(pc),a2
 bsr sim_score_file_save
 tst.l d0
 bne .failed
 lea sim_score_record_status(pc),a0
 move.l #1,(a0)
 moveq #0,d0
 bra .out
.failed:
 lea sim_score_record_status(pc),a0
 move.l #5,(a0)
 moveq #1,d0
.out:
 movem.l (sp)+,d1-d7/a0-a6
 move.w d0,-2(a5)          ; displaced original instruction
 rts

 even
 dc.b "4DSCRECS"
 dc.w 1,SIM_SCORE_EXACT_BYTES
; Status:0 native-only,1 exact loaded/saved,2 rejected companion,
; 3 failed native read,4 invalid filename,5 failed save,6 pending exact save,
; 7 native object not found (automatic creation permitted).
sim_score_record_status: dc.l 0
sim_score_record_loads: dc.l 0
sim_score_record_resets: dc.l 0
sim_score_records: dcb.l 14,-1
sim_score_records_guard: dc.l $52454353
sim_score_companion_path: dcb.b 256,0
sim_score_companion_guard: dc.l $50415448
 IFD SIM_SCORE_RESET_TEST
 dc.b "4DSCRSET"
 dc.w 1,1
sim_score_reset_test_count: dc.l 0
sim_score_reset_test_result: dc.l -1
 ENDC

 IFD SIM_SCORE_AUTOCREATE_TEST
; Run actual result-load and fallback branches with a valid caller local frame.
sim_score_autocreate_fixture:
 movem.l d0-a6,-(sp)
 link a5,#-64
 clr.b -$13(a5)
 lea sim_score_autocreate_fixture(pc),a0
 adda.l #tape_game-sim_score_autocreate_fixture,a0
 move.l (a0),a0
 adda.l #$5f46,a0
 jsr (a0)
 lea sim_score_autocreate_test_count(pc),a0
 addq.l #1,(a0)
 moveq #0,d0
 move.b -$13(a5),d0
 move.l d0,4(a0)
 unlk a5
 movem.l (sp)+,d0-a6
 rts
 even
 dc.b "4DSCAUTO"
 dc.w 1,1
sim_score_autocreate_test_count: dc.l 0
sim_score_autocreate_test_disabled: dc.l -1
 ENDC

 IFNE SIM_STARTUP_TESTS
; Fake DOS vectors exercise the actual Open/IoErr decision without touching
; files or relying on host filesystem permission mapping under WHDLoad.
sim_score_open_selftest:
 movem.l d0-a6,-(sp)
 lea sim_score_open_test_cases(pc),a2
 lea sim_score_open_test_passed(pc),a3
 clr.l (a3)
 lea sim_score_open_test_base(pc),a6
 moveq #5,d7
.case:
 lea sim_score_open_test_error(pc),a0
 move.w (a2)+,(a0)
 lea sim_score_open_test_guard(pc),a1
 movea.l a1,a0
 bsr sim_score_native_load
 cmp.w (a2)+,d0
 bne .failed
 cmp.l #$11223344,(a1)
 bne .failed
 addq.l #1,(a3)
 dbra d7,.case
 movem.l (sp)+,d0-a6
 rts
.failed:
 lea sim_score_open_selftest(pc),a0
 adda.l #perf_failure-sim_score_open_selftest,a0
 move.l #29,(a0)
 illegal
 bra .failed
sim_score_open_test_vectors:
 bra.w sim_score_open_test_ioerr
 dc.w 0
 dcb.b 96,0
 bra.w sim_score_open_test_open
 dc.w 0
 dcb.b 24,0
sim_score_open_test_base:
sim_score_open_test_open:
 moveq #0,d0
 rts
sim_score_open_test_ioerr:
 moveq #0,d0
 move.w sim_score_open_test_error(pc),d0
 rts
 even
 dc.b "4DSCOPEN"
 dc.w 1,6
sim_score_open_test_passed: dc.l 0
sim_score_open_test_error: dc.w 0
sim_score_open_test_cases: dc.w 205,1,0,2,202,2,212,2,218,2,221,2
sim_score_open_test_guard: dc.l $11223344

 ENDC
