; Exercise the installed wrapper bodies with overlapping byte writes, signed
; indexing, both X states and zero/nonzero model IDs, then undo the whole lease.
time_model_terrain_selftest:
	movem.l d0-a6,-(sp)
	lea time_model_terrain_frame+120(pc),a5
	moveq #1,d7
.case
	lea time_model_terrain_data(pc),a3
	move.l #$a5a5a5a5,(a3)
	move.w #$1234,10(a3)
	move.w #-1,-78(a5)
	lea 8(a3),a0
	move.l a0,-60(a5)
	moveq #0,d5
	tst.w d7
	beq .model_ready
	move.w #255,d5
.model_ready
	move.b d5,9(a3)
	move.w d7,d6
	lsl.w #4,d6
	lea 1(a3),a1
	move.w d6,ccr
	bsr time_model_terrain_visible
	bsr time_message_ccr
	and.w #31,d0
	cmp.w d6,d0
	bne time_model_bad
	tst.b 1(a3)
	bne time_model_bad
	cmpi.w #1,-110(a5)
	bne time_model_bad
	lea 2(a3),a0
	move.w d6,ccr
	bsr time_model_terrain_hidden
	bsr time_message_ccr
	and.w #31,d0
	move.w d6,d1
	ori.w #8,d1
	cmp.w d1,d0
	bne time_model_bad
	lea 1(a3),a1
	cmpa.l a1,a0
	bne time_model_bad
	cmpi.b #$ff,1(a3)
	bne time_model_bad
	move.w d6,ccr
	bsr time_model_terrain_type
	movem.l d0,-(sp)
	bsr time_message_ccr
	move.w d0,d4
	movem.l (sp)+,d0
	cmp.l d5,d0
	bne time_model_bad
	cmp.w 10(a3),d5
	bne time_model_bad
	lea 8(a3),a1
	cmpa.l a1,a0
	bne time_model_bad
	and.w #31,d4
	move.w d6,d1
	tst.w d5
	bne .nonzero
	ori.w #4,d1
.nonzero
	cmp.w d1,d4
	bne time_model_bad
	; Original optional sim:0f5ae store is covered by the preceding word save.
	addq.w #1,2(a0)
	lea time_model_count(pc),a0
	cmpi.w #3,(a0)
	bne time_model_bad
	bsr time_model_restore
	cmpi.l #$a5a5a5a5,(a3)
	bne time_model_bad
	cmpi.w #$1234,10(a3)
	bne time_model_bad
	dbf d7,.case
	lea time_model_terrain_result(pc),a0
	move.l #2,(a0)
	movem.l (sp)+,d0-a6
	rts
time_model_terrain_result: dc.l 0
time_model_terrain_data: dcb.b 16,0
time_model_terrain_frame: dcb.b 128,0
