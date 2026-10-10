; Exact high-score qualification, insertion and sorted companion saving.
; Native record loading initializes physical rows before results eligibility.

; D0 native finish word; at50 Hz use the independent completed summary instead.
; Return D2:D0 exact hundredths and D1 status, and retain the candidate globally.
sim_score_candidate_from_finish:
 and.l #$ffff,d0
 moveq #0,d1
 move.w -$15fa(a4),d1
 cmp.w #50,d1
 bne .convert
 lea sim_results_summary(pc),a0
 move.l 4(a0),d0
.convert:
 bsr sim_score_from_ticks
 lea sim_score_candidate(pc),a0
 move.l d2,(a0)
 move.l d0,4(a0)
 rts

; A0 sorted physical records, A1 candidate. D0 first strictly slower row,
; or -1 when no insertion qualifies. Keep the native slot6 threshold first:
; after an insertion it holds that finish, suppressing a duplicate call from
; the same results dialog. Fresh loads restore sorted physical rows.
; Equal times retain their existing order within that native contract.
; Preserve all other registers and do not change records or candidate.
sim_score_rank:
 movem.l d1/a0-a1,-(sp)
 adda.l #48,a0
 bsr sim_score_compare
 bls .not_found
 suba.l #48,a0
 moveq #0,d1
.next:
 bsr sim_score_compare
 bhi .found
 addq.l #8,a0
 addq.w #1,d1
 cmp.w #7,d1
 blo .next
.not_found:
 moveq #-1,d0
 bra .out
.found:
 move.l d1,d0
.out:
 movem.l (sp)+,d1/a0-a1
 rts

; $5F72..$5F9C. Keep the old low-word local for native argument pushes, but
; qualify using the exact completed finish and the canonical score table.
sim_score_eligibility:
 movem.l d0-d2/a0-a1,-(sp)
 move.w -$2f0(a4),-40(a5)
 move.b -$16b8(a4),d0
 and.b #6,d0
 bne .out
 move.w -40(a5),d0
 bsr sim_score_candidate_from_finish
 tst.l d1
 bne .out
 or.l d2,d0
 beq .out
 lea sim_score_records(pc),a0
 lea sim_score_candidate(pc),a1
 bsr sim_score_rank
 tst.l d0
 bmi .out
 move.b #1,-19(a5)
.out:
 movem.l (sp)+,d0-d2/a0-a1
 rts

; $3E02 entry PSS trampoline: discard its injected return, then reproduce LINK.
; Replace native word scaling/ranking. Resume the original mapping/text/name UI
; body at3E6A with its expected insertion index and native compatibility word.
sim_score_insert_entry:
 addq.l #4,sp
 link a5,#-$3a
 movem.l d2/a2,-(sp)
 move.w 8(a5),d0
 bsr sim_score_candidate_from_finish
 tst.l d1
 bne .reject
 or.l d2,d0
 beq .reject
 lea sim_score_records(pc),a0
 lea sim_score_candidate(pc),a1
 bsr sim_score_rank
 tst.l d0
 bmi .reject
 move.b d0,-1(a5)
 ; Native results loaded a sorted physical table. Rebuild the identity map;
 ; the original3E76 loop then inserts physical row6 at the selected position.
 lea -$160a(a4),a0
 moveq #0,d0
.indices:
 move.w d0,(a0)+
 addq.w #1,d0
 cmp.w #7,d0
 blo .indices
 lea sim_score_candidate(pc),a0
 lea sim_score_records+48(pc),a1
 move.l (a0),d2
 move.l 4(a0),d0
 move.l d2,(a1)
 move.l d0,4(a1)
 bsr sim_score_native_mirror
 move.w d0,8(a5)
 lea sim_score_record_status(pc),a0
 move.l #6,(a0)             ; new exact row is pending a successful save
 movem.l (sp)+,d2/a2
 lea sim_score_insert_entry(pc),a0
 adda.l #tape_game-sim_score_insert_entry,a0
 move.l (a0),a0
 adda.l #$3e6a,a0
 jmp (a0)
.reject:
 movem.l (sp)+,d2/a2
 lea sim_score_insert_entry(pc),a0
 adda.l #tape_game-sim_score_insert_entry,a0
 move.l (a0),a0
 adda.l #$3fb0,a0
 jmp (a0)

; $4028..$4030: native sorted buffer is at A5-$16E. Sort the exact times using
; the SAME seven indices, validate before writing, then save native and sidecar.
; Failure is returned and recorded; final UI error presentation is separate.
sim_score_save_hook:
 movem.l d1-d7/a0-a6,-(sp)
 lea -$160a(a4),a0
 lea sim_score_records(pc),a1
 lea sim_score_sorted(pc),a2
 moveq #6,d7
 moveq #0,d6
.sort:
 moveq #0,d0
 move.w (a0)+,d0
 cmp.w #6,d0
 bhi .failed
 btst d0,d6
 bne .failed
 bset d0,d6
 lsl.w #3,d0
 move.l (a1,d0.w),(a2)+
 move.l 4(a1,d0.w),(a2)+
 dbra d7,.sort
 lea -$16e(a5),a0
 lea sim_score_sorted(pc),a1
 bsr sim_score_rows_valid
 tst.l d0
 bne .failed
 lea -$1736(a4),a0
 bsr sim_score_companion_name
 tst.l d0
 bne .failed
 move.l #SIM_SCORE_NATIVE_BYTES,-(sp)
 pea -$16e(a5)
 pea -$1736(a4)
 jsr -$7ae8(a4)
 lea 12(sp),sp
 tst.l d0
 bne .failed
 movea.l $bda(a4),a6
 lea sim_score_companion_path(pc),a0
 lea -$16e(a5),a1
 lea sim_score_sorted(pc),a2
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
 clr.b -$7707(a4)            ; displaced original instruction
 rts

 even
sim_score_candidate: dc.l -1,-1
sim_score_sorted: dcb.l 14,-1
sim_score_sorted_guard: dc.l $534f5254
