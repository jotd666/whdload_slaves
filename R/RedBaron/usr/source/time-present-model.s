; Shared-model and native visibility-scratch write journal, VERIFY bit 13, sim v1 only.
; PERF_RANGE sim:0e128 10 bit=13
; PERF_RANGE sim:0e150 8 bit=13
; PERF_RANGE sim:0e1a6 8 bit=13
; PERF_RANGE sim:0df3e 8 bit=13
; PERF_RANGE sim:0df92 8 bit=13
; PERF_RANGE sim:0f55c 8 bit=13
; PERF_RANGE sim:0f56e 8 bit=13
; PERF_RANGE sim:0f584 14 bit=13
; PERF_RANGE sim:15c82 6 bit=13
; PERF_RANGE sim:15ca0 6 bit=13
TIME_MODEL_CAPACITY = 4096
TIME_MODEL_STRIDE = 8

time_model_install:
	movem.l d0-a6,-(sp)
	lea .checks(pc),a3
	moveq #6,d7
.check
	move.l (a3)+,d0
	move.w (a3)+,d1
	move.l a3,a0
	bsr perf_check_bytes
	adda.w d1,a3
	dbf d7,.check
	move.l time_loop_sim(pc),a0
	adda.l #$e150,a0
	cmpi.w #$1039,(a0)
	bne time_model_bad
	move.l time_loop_h3(pc),d0
	addi.l #$4e16,d0
	cmp.l 2(a0),d0
	bne time_model_bad
	cmpi.w #$1080,6(a0)
	bne time_model_bad
	bsr time_model_selftest
	bsr time_model_flag_install
	lea .patch(pc),a0
	jsr resload_Patch(a2)
	movem.l (sp)+,d0-a6
	rts
.checks:
	dc.l $e128
	dc.w 10,$5489,$12bc,$00ff,$2b48,$ffec
	dc.l $e1a6
	dc.w 8,$1029,$0007,$5300,$1080
	dc.l $df3e
	dc.w 8,$1401,$4882,$3182,$080e
	dc.l $df92
	dc.w 8,$1140,$0004,$1140,$0003
	dc.l $f55c
	dc.w 8,$4211,$3b7c,$0001,$ff92
	dc.l $f56e
	dc.w 8,$d0ed,$ffb2,$10bc,$00ff
	dc.l $f584
	dc.w 14,$7000,$206d,$ffc4,$1028,$0001,$3140,$0002
.patch:
	PL_START
	PL_PSS $e128,time_model_default,4
	PL_PSS $e150,time_model_player,2
	PL_PSS $e1a6,time_model_variant,2
	PL_PSS $df3e,time_model_color,2
	PL_PSS $df92,time_model_polygon,2
	PL_PSS $f55c,time_model_terrain_visible,2
	PL_PSS $f56e,time_model_terrain_hidden,2
	PL_PSS $f584,time_model_terrain_type,8
	PL_END

time_model_default:
	movem.l d0/a0,-(sp)
	lea 2(a1),a0
	moveq #1,d0
	bsr time_model_record
	movem.l (sp)+,d0/a0
	addq.l #2,a1
	move.b #$ff,(a1)
	move.l a0,-20(a5)
	rts

time_model_player:
	movem.l d0/a0,-(sp)
	moveq #1,d0
	bsr time_model_record
	movem.l (sp)+,d0/a0
	move.l a1,-(sp)
	move.l time_loop_h3(pc),a1
	move.b $4e16(a1),d0
	move.l (sp)+,a1
	move.b d0,(a0)
	rts

time_model_variant:
	move.l d0,-(sp)
	moveq #1,d0
	bsr time_model_record
	move.l (sp)+,d0
	move.b 7(a1),d0
	subq.b #1,d0
	move.b d0,(a0)
	rts

time_model_color:
	movem.l d0/a0,-(sp)
	lea 14(a0,d0.l),a0
	moveq #2,d0
	bsr time_model_record
	movem.l (sp)+,d0/a0
	move.b d1,d2
	ext.w d2
	move.w d2,14(a0,d0.l)
	rts

time_model_polygon:
	movem.l d0/a0,-(sp)
	lea 3(a0),a0
	moveq #2,d0
	bsr time_model_record
	movem.l (sp)+,d0/a0
	move.b d0,4(a0)
	move.b d0,3(a0)
	rts

; Terrain visibility lives in the allocation rooted at h3:054da. Each
; static object points to its slice at object+30. Preserve it across a draw.
time_model_terrain_visible:
	movem.l d0/a0,-(sp)
	move.l a1,a0
	moveq #1,d0
	bsr time_model_record
	movem.l (sp)+,d0/a0
	clr.b (a1)
	move.w #1,-110(a5)
	rts

time_model_terrain_hidden:
	adda.w -78(a5),a0
	move.l d0,-(sp)
	moveq #1,d0
	bsr time_model_record
	move.l (sp)+,d0
	move.b #$ff,(a0)
	rts

; Save before initial model selection. The conditional increment at sim:0f5ae
; stays native and is covered by this same saved word; its incoming branch at
; sim:0f5b2 must not be overwritten by a longer patch at the increment itself.
time_model_terrain_type:
	moveq #0,d0
	move.l -60(a5),a0
	movem.l d0/a0,-(sp)
	lea 2(a0),a0
	moveq #2,d0
	bsr time_model_record
	movem.l (sp)+,d0/a0
	move.b 1(a0),d0
	move.w d0,2(a0)
	rts

; a0 destination, d0 byte count (1 or 2). Preserve registers and X. Named
; stores replay native NZVC after return. Read bytewise: polygons can be odd.
time_model_record:
	movem.l d0-d2/a0-a2,-(sp)
	move.l d0,d2
	bsr time_message_ccr
	move.w d0,-(sp)
	lea time_present_active(pc),a2
	tst.w (a2)
	beq .done
	lea time_model_count(pc),a2
	moveq #0,d1
	move.w (a2),d1
	cmpi.w #TIME_MODEL_CAPACITY,d1
	bhs time_model_bad
	lsl.l #3,d1
	lea .buffer_base(pc),a1
.buffer_base
	adda.l #time_model_buffer-.buffer_base,a1
	adda.l d1,a1
	move.l a0,(a1)+
	move.b (a0),(a1)+
	clr.b (a1)
	cmpi.w #2,d2
	bne .size
	move.b 1(a0),(a1)
.size
	addq.l #1,a1
	move.w d2,(a1)
	addq.w #1,(a2)
.done
	move.w (sp)+,ccr
	movem.l (sp)+,d0-d2/a0-a2
	rts

; Undo in reverse order: duplicate/overlapping shared-model writes are valid.
; Called inside the outer draw's saved-register envelope.
time_model_restore:
	lea time_model_count(pc),a2
	moveq #0,d1
	move.w (a2),d1
	beq .done
	lea .buffer_base(pc),a1
.buffer_base
	adda.l #time_model_buffer-.buffer_base,a1
	move.l d1,d0
	lsl.l #3,d0
	adda.l d0,a1
.next
	subq.l #8,a1
	move.l (a1),a0
	move.b 4(a1),(a0)
	cmpi.w #2,6(a1)
	bne .one
	move.b 5(a1),1(a0)
.one
	subq.w #1,d1
	bne .next
	clr.w (a2)
.done
	rts

time_model_bad:
	pea time_model_error(pc)
	pea TDREASON_FAILMSG
	lea .resload_base(pc),a2
.resload_base
	adda.l #_resload-.resload_base,a2
	move.l (a2),a2
	jmp resload_Abort(a2)
time_model_error: dc.b "Red Baron: W6 model journal check or capacity failure",0
	even
time_model_count: dc.w 0

; Exercise repeated and odd-address overlapping stores before game activation.
time_model_selftest:
	movem.l d0-a6,-(sp)
	lea time_present_active(pc),a4
	move.w #1,(a4)
	lea time_model_test_data(pc),a0
	move.l #$12345678,(a0)
	moveq #1,d0
	bsr time_model_record
	move.b #$aa,(a0)
	moveq #2,d0
	bsr time_model_record
	move.b #$bb,(a0)
	move.b #$cc,1(a0)
	addq.l #1,a0
	bsr time_model_record
	move.b #$dd,(a0)
	move.b #$ee,1(a0)
	move.w time_model_count(pc),d0
	cmpi.w #3,d0
	bne time_model_bad
	bsr time_model_restore
	lea time_model_test_data(pc),a0
	cmpi.l #$12345678,(a0)
	bne time_model_bad
	bsr time_model_terrain_selftest
	clr.w (a4)
	moveq #1,d0
	bsr time_model_record
	move.w time_model_count(pc),d0
	bne time_model_bad
	lea time_model_test_result(pc),a0
	move.l #1,(a0)
	movem.l (sp)+,d0-a6
	rts
time_model_test_data: dc.l 0
time_model_test_result: dc.l 0
