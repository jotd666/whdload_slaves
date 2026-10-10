; Drawing and world registration/removal share h3:03fa8 + h3:07dc8.
; Preserve the active prefix and count; append always overwrites an inactive slot.
time_present_list_save:
	move.l time_pose_h3(pc),a0
	moveq #0,d0
	move.w $3fa8(a0),d0
	cmpi.w #500,d0
	bhi time_model_bad
	lea time_present_list_count(pc),a1
	move.w d0,(a1)
	adda.l #$7dc8,a0
	lea .buffer_base(pc),a1
.buffer_base
	adda.l #time_present_list_buffer-.buffer_base,a1
	bra time_present_list_copy

time_present_list_restore:
	move.l time_pose_h3(pc),a1
	moveq #0,d0
	move.w time_present_list_count(pc),d0
	move.w d0,$3fa8(a1)
	adda.l #$7dc8,a1
	lea .buffer_base(pc),a0
.buffer_base
	adda.l #time_present_list_buffer-.buffer_base,a0
	bra time_present_list_copy

; Count is bounded by the native 500-entry registration limit. Copy only the
; active prefix: stale tail entries are never read without first being replaced.
time_present_list_copy:
	tst.w d0
	beq .done
	subq.w #1,d0
.next
	move.l (a0)+,(a1)+
	dbf d0,.next
.done
	rts

time_present_list_selftest:
	movem.l d0-a6,-(sp)
	lea .source_base(pc),a3
.source_base
	adda.l #time_model_buffer-.source_base,a3
	lea .dest_base(pc),a4
.dest_base
	adda.l #time_present_list_buffer-.dest_base,a4
	move.l a3,a0
	move.l a4,a1
	moveq #0,d0
	move.w #500,d7
.init
	move.l d0,(a0)+
	move.l #$76543210,(a1)+
	addq.l #1,d0
	dbf d7,.init
	move.l a3,a0
	move.l a4,a1
	moveq #0,d0
	bsr time_present_list_copy
	cmpi.l #$76543210,(a4)
	bne time_model_bad
	move.l a3,a0
	move.l a4,a1
	move.w #500,d0
	bsr time_present_list_copy
	move.l a3,a0
	move.l a4,a1
	move.w #499,d7
.check
	cmpm.l (a0)+,(a1)+
	bne time_model_bad
	dbf d7,.check
	cmpi.l #$76543210,(a1)
	bne time_model_bad
	lea time_present_list_result(pc),a0
	move.l #2,(a0)
	movem.l (sp)+,d0-a6
	rts

time_present_list_result: dc.l 0
time_present_list_count: dc.w 0

; The native terrain early-out at sim:0f038 reuses both cached visibility and
; selected model IDs. Those are restored after our draw, so a later draw must
; rebuild, even for an unchanged camera. Keep its key/flag/countdown coherent
; with the restored data. No IRQ-owned data is included.
time_terrain_cache_begin:
	bsr time_terrain_cache_addresses
	bra time_terrain_cache_save

time_terrain_cache_end:
	bsr time_terrain_cache_addresses
	bra time_terrain_cache_restore

time_terrain_cache_addresses:
	lea .h3_base(pc),a0
.h3_base
	adda.l #time_loop_h3-.h3_base,a0
	move.l (a0),a0
	lea $5270(a0),a1
	adda.l #$54de,a0
	rts

; a0 = 12-byte cached camera position + two-byte recomputation flag;
; a1 = two-byte view-change countdown. The sentinel bypasses sim:0f038's
; positive-height test without changing native arguments or branch semantics.
time_terrain_cache_save:
	lea time_terrain_cache_saved(pc),a2
	move.w (a1),(a2)+
	move.l (a0)+,(a2)+
	move.l (a0)+,(a2)+
	move.l (a0)+,(a2)+
	move.w (a0),(a2)
	move.l #-1,-4(a0)
	rts

time_terrain_cache_restore:
	lea time_terrain_cache_saved(pc),a2
	move.w (a2)+,(a1)
	move.l (a2)+,(a0)+
	move.l (a2)+,(a0)+
	move.l (a2)+,(a0)+
	move.w (a2),(a0)
	rts

time_terrain_cache_selftest:
	movem.l d0-a6,-(sp)
	lea time_model_terrain_data(pc),a0
	move.l #$12345678,(a0)+
	move.l #$87654321,(a0)+
	move.l #$00003000,(a0)+
	move.w #1,(a0)+
	move.w #2,(a0)
	lea time_model_terrain_data(pc),a0
	lea 14(a0),a1
	bsr time_terrain_cache_save
	cmpi.l #-1,-4(a0)
	bne time_model_bad
	; Simulate a complete rebuild overwriting all owned cache fields.
	lea time_model_terrain_data(pc),a0
	move.l #$aaaaaaaa,(a0)+
	move.l #$bbbbbbbb,(a0)+
	move.l #$cccccccc,(a0)+
	clr.l (a0)
	lea time_model_terrain_data(pc),a0
	lea 14(a0),a1
	bsr time_terrain_cache_restore
	lea time_model_terrain_data(pc),a0
	cmpi.l #$12345678,(a0)+
	bne time_model_bad
	cmpi.l #$87654321,(a0)+
	bne time_model_bad
	cmpi.l #$00003000,(a0)+
	bne time_model_bad
	cmpi.w #1,(a0)+
	bne time_model_bad
	cmpi.w #2,(a0)
	bne time_model_bad
	lea time_terrain_cache_result(pc),a0
	move.l #1,(a0)
	movem.l (sp)+,d0-a6
	rts

time_terrain_cache_saved: dcb.b 16,0
time_terrain_cache_result: dc.l 0

; Exercise the installed wrapper bodies with overlapping byte writes, signed
; indexing, both X states and zero/nonzero model IDs, then undo the whole lease.
time_model_terrain_selftest:
	movem.l d0-a6,-(sp)
	bsr time_present_list_selftest
	bsr time_terrain_cache_selftest
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
